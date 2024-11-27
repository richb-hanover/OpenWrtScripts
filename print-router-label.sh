#!/bin/sh

# Print Router Label

# This script retrieves values from the OpenWrt to print a
# concise label that contains important config info.
# This label can be taped to the side of the router 
# so the next person to encounter the router (which may be
# you) can access it. It is secure because if someone
# can read the label, they can factory-reset the router anyway.

# Usage: sh print-router-label.sh [root-password] [WifiSSID] [WifiPassword]

# There's no way to determine the root password (it's hashed)
# so the script leaves it as "?" unless you supply it.

print_router_label() {

local NEWPASSWD="${1:-"?"}" 
local WIFISSID="${2:-"?"}" 
local WIFIPASSWD="${3:-"?"}" 

TODAY=$(date +"%Y-%b-%d")
DEVICE=$(cat /tmp/sysinfo/model)
OPENWRTVERSION=$(grep "DISTRIB_DESCRIPTION" /etc/openwrt_release | cut -d"=" -f2 | tr -d '"')
HOSTNAME=$(uci get system.@system[0].hostname)
LANIPADDRESS=$(uci get network.lan.ipaddr)


echo ""
echo "Print the following label and tape it to the router..."
echo ""
echo "=== Printed with: print-router-label.sh ============"
echo "     Device: $DEVICE"
echo "    OpenWrt: $OPENWRTVERSION" 
echo " Connect to: http://$HOSTNAME.local" 
echo "         or: ssh root@$HOSTNAME.local"
echo "        LAN: $LANIPADDRESS"
echo "       User: root"
echo "   Login PW: $NEWPASSWD"
echo "  Wifi SSID: $WIFISSID"
echo "    Wifi PW: $WIFIPASSWD"
echo " Configured: $TODAY"
echo "=== See: github.com/richb-hanover/OpenWrtScripts ==="
echo ""
echo "Power Brick Label: $DEVICE"
echo ""
}

print_router_label "$1" "$2" "$3"
