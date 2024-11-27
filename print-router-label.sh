#!/bin/sh

# Print Router Label

# This script retrieves values from an OpenWrt router to print a
# concise label that contains important config info.
# This label can be taped to the side of the router 
# so the next person to encounter the router (which may be
# you) can access it. It is pretty secure because if someone
# can read the label, they can factory-reset the router
# (or steal your silverware).
# Here's an example label:

# === Printed with: print-router-label.sh ============
#      Device: Linksys E8450 (UBI)
#     OpenWrt: 'OpenWrt 23.05.5 r24106-10cc5fcd00'
#  Connect to: http://Belkin-RT3200.local
#          or: ssh root@Belkin-RT3200.local
#         LAN: 192.168.253.1
#        User: root
#    Login PW: abcdef
#   Wifi SSID: OpenWrt
#     Wifi PW: -open-
#  Configured: 2024-Nov-27
# === See: github.com/richb-hanover/OpenWrtScripts ===

# Usage: sh print-router-label.sh root-password WifiSSID WifiPassword

print_router_label() {

local ROOTPASSWD="${1:-"?"}" 
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
echo "   Login PW: $ROOTPASSWD"
echo "  Wifi SSID: $WIFISSID"
echo "    Wifi PW: $WIFIPASSWD"
echo " Configured: $TODAY"
echo "=== See: github.com/richb-hanover/OpenWrtScripts ==="
echo ""
echo "Power Brick Label: $DEVICE"
echo ""
}

print_router_label "$1" "$2" "$3"
