#!/bin/sh

# Print Router Label

# Usage: sh print-router-label.sh root-password

# This script retrieves values from an OpenWrt router to create a
# label that contains the LAN address and credentials.
# Tape this label to the side of the router so the next person
# to encounter the router (which may be you) can access it. 

# This process is reasonably secure - if the bad guy
# can read the label, they can also factory-reset the router
# (or steal your TV or your silverware).
# 
# Pro-tip: Snip out the power brick label, and tape it to the
# power brick so the router and brick don't get separated.
#
# Pro-tip: Printing the label in 12-point type produces a
# "business card" size label. Small text, but readable.
# 
# If no root-password is supplied, the script prints "?".
# You can then write the password on the label.
# If the Wifi is open, its password is printed as "<no password>"
#
# Here's a sample label created from the Usage above:

# ======= Printed with: print-router-label.sh =======
#      Device: Linksys E8450 (UBI)
#     OpenWrt: OpenWrt 23.05.5 r24106-10cc5fcd00
#  Connect to: http://Belkin-RT3200.local
#          or: ssh root@Belkin-RT3200.local
#         LAN: 192.168.253.1
#        User: root
#    Login PW: root-password
#   Wifi SSID: My Wifi SSID
#     Wifi PW: <no password>
#  Configured: 2024-11-28
# === See github.com/richb-hanover/OpenWrtScripts ===
#
# Label for Power Brick: Linksys E8450 (UBI)
#

print_router_label() {
	local ROOTPASSWD="${1:-"?"}" 
	TODAY=$(date +"%Y-%m-%d")
	DEVICE=$(cat /tmp/sysinfo/model)
	OPENWRTVERSION=$(grep "DISTRIB_DESCRIPTION" /etc/openwrt_release | cut -d"=" -f2 | tr -d '"' | tr -d "'")
	HOSTNAME=$(uci get system.@system[0].hostname)
	LANIPADDRESS=$(uci get network.lan.ipaddr)
	LOCALDNSTLD=$(uci get dhcp.@dnsmasq[0].domain) # top level domain for local names

	# Create temporary file for both SSID and password
	TMPFILE=$(mktemp /tmp/wifi_creds.XXXXXX)

	# Get wifi credentials
	uci show wireless |\
	egrep =wifi-iface$ |\
	cut -d= -f1 |\
	while read s;
	    do uci -q get $s.disabled |\
	    grep -q 1 && continue;
	    id=$(uci -q get $s.ssid);
	    key=$(uci -q get $s.key);
	    # Write both SSID and password to temporary file
	    echo "$id:$key" > "$TMPFILE"
	    break
	done

	# Read both values from temporary file
	if [ -f "$TMPFILE" ]; then
	    WIFISSID=$(cut -d: -f1 "$TMPFILE")
	    WIFIPASSWD=$(cut -d: -f2 "$TMPFILE")
	    # Check if password is empty and replace with "<no password>"
	    if [ -z "$WIFIPASSWD" ]; then
	        WIFIPASSWD="<no password>"
	    fi
	else
	    WIFISSID="unknown"
	    WIFIPASSWD="unknown"
	fi

	# Clean up temporary file
	rm -f "$TMPFILE"

	echo ""
	echo "Print the following label and tape it to the router..."
	echo ""
	echo "======= Printed with: print-router-label.sh ======="
	echo "     Device: $DEVICE"
	echo "    OpenWrt: $OPENWRTVERSION" 
	echo " Connect to: http://$HOSTNAME.$LOCALDNSTLD" 
	echo "         or: ssh root@$HOSTNAME.$LOCALDNSTLD"
	echo "        LAN: $LANIPADDRESS"
	echo "       User: root"
	echo "   Login PW: $ROOTPASSWD"
	echo "  Wifi SSID: $WIFISSID"
	echo "    Wifi PW: $WIFIPASSWD"
	echo " Configured: $TODAY"
	echo "=== See github.com/richb-hanover/OpenWrtScripts ==="
	echo ""
	echo "Label for Power Brick: $DEVICE"
	echo ""
}

print_router_label "$1"
