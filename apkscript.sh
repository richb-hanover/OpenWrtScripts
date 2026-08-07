#! /bin/sh

# Write a list of packages currently installed or read that list,
# presumably after a firmware upgrade, in order to reinstall all packages
# on that list not currently installed
#
# (c) 2013 Malte Forkel <malte.forkel@berlin.de>
# (c) 2026 Tilman Vogel <tilman.vogel@web.de>
#
# Originally found on OpenWrt forums at:
#    https://forum.openwrt.org/viewtopic.php?pid=194478#p194478
# Thanks, too, to hnyman for important comments on this script

PCKGLIST=/etc/config/apk.installed   # default package list
OPKGLIST=/etc/config/opkg.installed  # fall-back package list
SCRIPTNAME=$(basename $0)            # name of this script
COMMAND=""                           # command to execute

INSTLIST=$(mktemp)                   # list of packages to install
PREQLIST=$(mktemp)                   # list of prerequisite packages

UPDATE=false                         # update the package database
VERBOSE=false                        # be verbose

cleanup () {
    rm -f $INSTLIST $PREQLIST
}

trap cleanup SIGHUP SIGINT SIGTERM EXIT

echo_usage () {
    echo \
"Usage: $(basename $0) [options...] command [packagelist]

Available commands:
    help                print this help text
    write               write a list of currently installed packages
    install             install packages on list not currently installed
    script              output a script to install missing packages

Options:
    -u                  update the package database
    -v                  be verbose

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

to output a shell script that will contain calls to apk to install those
missing packages. This might be useful if you want to check which packages
would be installed of if you want to edit that list.

In order for this script to work after a firmware upgrade or reboot, the
apk database must have been updated. You can use the option -u to do this.

For 'install' and 'script', the older '$OPKGLIST' will be read if '$PCKGLIST'
is not found.
"
}

strip_dependencies() {
    SOURCE="$1"
    TARGET="$2"
    cp /dev/null "$PREQLIST"
    cat "$SOURCE" | while read PACKAGE REST; do
        $VERBOSE && echo "Collecting dependencies of $PACKAGE"
        # collect prerequisites
        apk info --installed -qR "$PACKAGE" >> $PREQLIST
    done
    cp /dev/null "$TARGET"
    cat "$SOURCE" | while read PACKAGE REST; do
        # only save top packages (not a dependency of others)
        if grep -qF "$PACKAGE" "$PREQLIST"; then
            $VERBOSE && echo "Skipping dependency $PACKAGE"
        else
            $VERBOSE && echo "Saving $PACKAGE"
            echo "$PACKAGE" >> "$TARGET"
        fi
    done
}

# parse command line options
while getopts "htuvw" OPTS; do
    case $OPTS in
        u )
            UPDATE=true;;
        v )
            VERBOSE=true;;
        [h\?*] )
            echo_usage
            exit 0;;
    esac
done
shift $(($OPTIND - 1))

# Set the command
COMMAND=$1

# Set name of the package list
if [ "x$2" != "x" ]; then
    PCKGLIST="$2"
else
    if [ $COMMAND == "install" ] || [ $COMMAND == "script" ]; then
        if [ ! -e "$PCKGLIST" -a -e "$OPKGLIST" ]; then
            strip_dependencies "$OPKGLIST" "$PCKGLIST"
        fi
    fi
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

if [ $COMMAND = "write" ] ; then
    if $VERBOSE; then
        echo "Saving package list to $PCKGLIST"
    fi
    apk info > "$INSTLIST"
    strip_dependencies "$INSTLIST" "$PCKGLIST"
    exit 0
fi

#
# Update
#

if $UPDATE; then
    apk update
fi

#
# Check
#

if [ $COMMAND == "install" ] || [ $COMMAND == "script" ]; then
    # detect uninstalled packages
    if $VERBOSE && [ $COMMAND != "script" ]; then
        echo "Checking packages... "
    fi
    cat "$PCKGLIST" | while read PACKAGE SEP VERSION; do
        if [ "x$(apk query --installed $PACKAGE)" == "x" ]; then
            # collect uninstalled packages
            echo $PACKAGE >> $INSTLIST
        fi
    done
fi

#
# Install or script
#

if [ $COMMAND == "install" ]; then
    # install packages
    cat "$INSTLIST" | while read PACKAGE; do
        apk add $PACKAGE
    done
elif [ $COMMAND == "script" ]; then
    # output install script
    echo "#! /bin/sh"
    cat "$INSTLIST" | while read PACKAGE; do
        echo "apk add $PACKAGE"
    done
else
    echo "Unknown command '$COMMAND'."
    echo ""
    echo_usage
    exit 1
fi

# clean up and exit
exit 0
