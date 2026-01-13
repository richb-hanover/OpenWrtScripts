#! /bin/sh

# Write a list of packages currently installed or read that list,
# presumably after a firmware upgrade, in order to reinstall all packages
# on that list not currently installed
#
# (c) 2013 Malte Forkel <malte.forkel@berlin.de>
#
# Originally found on OpenWrt forums at:
#    https://forum.openwrt.org/viewtopic.php?pid=194478#p194478
# Thanks, too, to hnyman for important comments on this script
#
# Version history
#    0.2.3 - added support for selective IPK caching with version retention control for offline recovery installs
#    0.2.2 - editorial tweaks to help text -richb-hanvover 
#    0.2.1 - fixed typo in awk script for dependency detection
#    0.2.0 - command interface
#    0.1.0 - Initial release

PCKGLIST=/etc/config/opkg.installed                 # Default package list
IPK_CACHE_LIST="/etc/config/opkg.ipk_cache_list"    # List of packages to cache IPKs for
IPK_CACHE_DIR="/etc/opkg/ipk_cache"                 # Directory to store cached IPK files
IPK_CACHE_ALL_VERSIONS=false                        # Cache only the latest IPK per package (default). Set to true to keep all versions.
SCRIPTNAME=$(basename $0)                           # Name of this script
COMMAND=""                                          # Command to execute

INSTLIST=$(mktemp)                                  # List of packages to install
PREQLIST=$(mktemp)                                  # List of prerequisite packages

UPDATE=false                                        # Update the package database
OPKGOPT=""                                          # Options for opkg calls
VERBOSE=false                                       # Be verbose
DEBUG_TRACE=false                                   # Set to true to enable shell debug tracing (set -x)


cleanup () {
    rm -f $INSTLIST $PREQLIST
}

echo_usage () {
    echo \
"Usage: $(basename $0) [options...] command [packagelist]

Available commands:
    help                print this help text
    write               write a list of currently installed packages
    install             install packages on list not currently installed
    script              output a script to install missing packages
    cache-ipks          download .ipk files for specific packages to a local cache

Options:
    -u                  update the package database
    -t                  test only, execute opkg commands with --noaction
    -v                  be verbose
    -x                  enable shell debug tracing (set -x)

Configuration:
    IPK_CACHE_ALL_VERSIONS in script controls whether to cache all .ipk versions or just the latest.
    Default is to cache only the latest. Set IPK_CACHE_ALL_VERSIONS=true to retain all versions.
    Warning: caching all versions may consume significant storage and must be cleaned manually.

$SCRIPTNAME can be used to re-install those packages that were installed
before a firmware upgrade but are not part of the new firmware image.

Before the firmware upgrade, execute

    $SCRIPTNAME [options...] write [packagelist]
    
to save the list of currently installed packages. Save the package list in a 
place that will not be wiped out by the firmware upgrade. The default package list
is '$PCKGLIST', which works well for normal sysupgrades. Or copy that file to 
another computer before the upgrade if you are not preserving the settings.

After the firmware upgrade, execute

    $SCRIPTNAME [options...] install [packagelist]
    
to re-install all packages that were not part of the firmware image. 
By default, the script will use the previously-created '$PCKGLIST'.
Alternatively, you can execute

    $SCRIPTNAME [options...] script [packagelist]
    
to output a shell script that will contain calls to opkg to install those
missing packages. This might be useful if you want to check which packages
would be installed or if you want to edit that list.

In order for this script to work after a firmware upgrade or reboot, the
opkg database must have been updated. You can use the option -u to do this.

You can specify the option -t to test what $SCRIPTNAME would do. All calls
to opkg will be made with the option --noaction. This does not influence
the call to opkg to write the list of installed packages, though.
"
}

trap cleanup SIGHUP SIGINT SIGTERM EXIT

# parse command line options
while getopts "htuvx" OPTS; do
    case $OPTS in
        t ) OPKGOPT="$OPKGOPT --noaction";;
        u ) UPDATE=true;;
        v ) VERBOSE=true;;
        x ) DEBUG_TRACE=true; VERBOSE=true;;
        [h\?*] ) echo_usage; exit 0;;
    esac
done
shift $(($OPTIND - 1))

[ "$DEBUG_TRACE" = true ] && set -x

# Set the command
COMMAND=$1

# Set name of the package list
if [ "x$2" != "x" ]; then
    PCKGLIST="$2"
fi

#
# Help
#
if [ "x$COMMAND" == "x" ]; then
    echo "No command specified."
    echo ""
    COMMAND="help"
fi

if [ $COMMAND == "help" ]; then
    echo_usage
    exit 0
fi

#
# Write
#
if [ $COMMAND = "write" ]; then
    $VERBOSE && echo "Saving package list to $PCKGLIST"
    # NOTE: option --noaction not valid for list-installed
    opkg list-installed > "$PCKGLIST"
    exit 0
fi

#
# Cache IPKs
#
if [ $COMMAND = "cache-ipks" ]; then
    if [ ! -f "$IPK_CACHE_LIST" ]; then
        echo "Error: IPK cache list '$IPK_CACHE_LIST' not found."
        echo "Please create this file and list the packages you want to cache (one per line)."
        exit 1
    fi

    if [ ! -d "$IPK_CACHE_DIR" ]; then
        $VERBOSE && echo "Creating IPK cache directory: $IPK_CACHE_DIR"
        mkdir -p "$IPK_CACHE_DIR" || {
            echo "Error: Could not create IPK cache directory '$IPK_CACHE_DIR'."
            exit 1
        }
    fi

    $VERBOSE && echo "Caching IPK files from list: $IPK_CACHE_LIST to $IPK_CACHE_DIR"
    $VERBOSE && echo "Checking freshness of opkg cache..."

    # Only update if lists are older than 5 minutes
    CACHE_AGE_LIMIT=300  # seconds
    needs_update=false
    for list in /var/opkg-lists/*; do
        if [ ! -f "$list" ] || [ "$(($(date +%s) - $(date -r "$list" +%s)))" -gt "$CACHE_AGE_LIMIT" ]; then
            needs_update=true
            break
        fi
    done

    if $needs_update; then
        $VERBOSE && echo "Running opkg update..."
        opkg update
        $VERBOSE && echo "Finished opkg update"
    else
        echo "Skipping opkg update: cache is fresh"
    fi

	TOTAL=0
	DOWNLOADED=0
	SKIPPED=0
	REMOVED=0

	while read PACKAGE; do
		PACKAGE=$(echo "$PACKAGE" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
		[ -z "$PACKAGE" ] && continue
		TOTAL=$((TOTAL + 1))

		IPK_LATEST_FILENAME=$(opkg info "$PACKAGE" | grep "^Filename:" | awk '{print $2}')
		[ -z "$IPK_LATEST_FILENAME" ] && {
			echo "Warning: Could not find filename for package '$PACKAGE'. Skipping."
			continue
		}

		BASE_PACKAGE_NAME=$(opkg info "$PACKAGE" | grep "^Package:" | awk '{print $2}')
		IPK_LATEST_PATH="$IPK_CACHE_DIR/$IPK_LATEST_FILENAME"

		if ! $IPK_CACHE_ALL_VERSIONS && [ -n "$BASE_PACKAGE_NAME" ]; then
			CACHED_FILES=$(find "$IPK_CACHE_DIR" -maxdepth 1 -type f -name "${BASE_PACKAGE_NAME}_*.ipk")
			for CACHED_FILE in $CACHED_FILES; do
				CACHED_FILENAME=$(basename "$CACHED_FILE")
				if [ "$CACHED_FILENAME" != "$IPK_LATEST_FILENAME" ]; then
					$VERBOSE && echo "Removing old version of $BASE_PACKAGE_NAME: $CACHED_FILENAME"
					rm -f "$CACHED_FILE" || echo "Warning: Failed to remove $CACHED_FILE"
					REMOVED=$((REMOVED + 1))
				fi
			done
		fi

		if [ -f "$IPK_LATEST_PATH" ]; then
			echo "$PACKAGE is up to date ($IPK_LATEST_FILENAME)"
			SKIPPED=$((SKIPPED + 1))
		else
			$VERBOSE && echo "Downloading $PACKAGE → $IPK_LATEST_FILENAME"
			opkg $OPKGOPT download "$PACKAGE"
			if [ $? -eq 0 ] && [ -f "./$IPK_LATEST_FILENAME" ]; then
				mv "./$IPK_LATEST_FILENAME" "$IPK_LATEST_PATH" || echo "Error: Failed to move downloaded IPK"
				$VERBOSE && echo "Moved to $IPK_CACHE_DIR"
				DOWNLOADED=$((DOWNLOADED + 1))
			else
				echo "Warning: Download failed or file missing for '$PACKAGE'"
			fi
		fi
	done < "$IPK_CACHE_LIST"

    echo ""
    echo "IPK Cache Summary:"
    printf "  %-25s %d\n" "Packages scanned:" $TOTAL
    printf "  %-25s %d\n" "New downloads:" $DOWNLOADED
    printf "  %-25s %d\n" "Older versions removed:" $REMOVED
    printf "  %-25s %d\n" "Already up to date:" $SKIPPED
    echo ""

    exit 0
fi

#
# Update 
#
if $UPDATE; then
    opkg $OPKGOPT update
fi

#
# Check
#
if [ $COMMAND == "install" ] || [ $COMMAND == "script" ]; then
    # detect uninstalled packages
    $VERBOSE && [ $COMMAND != "script" ] && echo "Checking packages... "
    cat "$PCKGLIST" | while read PACKAGE SEP VERSION; do
        # opkg status is much faster than opkg info
        # it only returns status of installed packages
        #if ! opkg status $PACKAGE | grep -q "^Status:.* installed"; then
        if [ "x$(opkg status $PACKAGE)" == "x" ]; then
            # collect uninstalled packages
            echo $PACKAGE >> $INSTLIST
            # collect prerequisites
            opkg info "$PACKAGE" |
            awk "/^Depends: / {
                sub(\"Depends: \", \"\");
                gsub(\", \", \"\\n\");
                print >> \"$PREQLIST\";
            }"
        fi
    done
fi

#
# Install or script
#
if [ $COMMAND == "install" ]; then
    # install packages
    cat "$INSTLIST" | while read PACKAGE; do
        if grep -q "^$PACKAGE\$" "$PREQLIST"; then
            # prerequisite package, will be installed automatically
            $VERBOSE && echo "$PACKAGE installed automatically"
        else
            # install package
            opkg $OPKGOPT install $PACKAGE
        fi
    done
elif [ $COMMAND == "script" ]; then
    # output install script
    echo "#! /bin/sh"
    cat "$INSTLIST" | while read PACKAGE; do
        if ! grep -q "^$PACKAGE\$" "$PREQLIST"; then
            echo "opkg install $PACKAGE"
        fi
    done
else
    echo "Unknown command '$COMMAND'."
    echo ""
    echo_usage
    exit 1
fi

# clean up and exit
exit 0
