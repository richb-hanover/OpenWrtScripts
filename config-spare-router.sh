#!/bin/sh
# Conigure a "spare router" in a known-good state.

# This script configures the factory default settings of OpenWrt
#   to make it easy to swap it in when a new router is needed.
# It also displays important configuration information when complete.
#   You can print out those lines and tape them to the router so
#   the next person will know how to access the router in the future.
#   The format is:
#
# Configured: YYYY-MMM-DD
#     Device: Belkin RT3200
#    OpenWrt: 22.03.5 r20134-5f15225c1e  
#        LAN: 192.168.253.1
#       User: root
#   Login PW: SpareRouter
#  WiFi SSID: SpareRouter
#    WiFi PW: none

# The default settings of the script are generic, but the router will work.
# You could make a copy of this script, customize it to your needs,
# then use the "To run this script" procedure (below).
#
# ***** To run this script *****
#
# Flash the router with factory firmware. Then SSH in and execute these statements. 
# You should do this over a wired connection because some of these changes
# can reset the wireless network.
# 
# ssh root@192.168.1.1
# cd /tmp
# cat > config.sh 
# [paste in the contents of this file, then hit ^D]
# sh config.sh
# Presto! (You should reboot the router when this completes.)

# === CONFIGURATION PARAMETERS ===
# Set the variables in this section to be used for configuration

NEWPASSWD="SpareRouter"
TIMEZONE='EST5EDT,M3.2.0,M11.1.0' 	# see link to other time zones below
ZONENAME='America/New York'			
LANIPADDRESS="172.30.42.1"
LANSUBNET="255.255.255.0"
SNMP_COMMUNITYSTRING=public
WIFISSID="SpareRouter"
WIFIPASSWD=''
ENCRMODE='none'

# === Update root password =====================
# Update the root password. 
# 
echo 'Updating root password'
passwd <<EOF
$NEWPASSWD
$NEWPASSWD
EOF

# === Update IP Subnet Ranges ==================
# Change the local IP Subnet
#
echo "Changing LAN address"
uci set network.lan.ipaddr=$LANIPADDRESS
uci set network.lan.netmask=$LANSUBNET
uci commit network

# === Enable Wifi on the first radio with configured parameters
# Only one radio opened up for access
# Use its default channel
#
echo "Setting Wi-fi Parameters"
uci set wireless.@wifi-iface[0].ssid=$WIFISSID
uci set wireless.@wifi-iface[0].encryption=$ENCRMODE
uci set wireless.@wifi-iface[0].disabled='0'
uci set wireless.@wifi-device[0].disabled='0'
uci commit wireless
wifi

# === Set the Time Zone ========================
# Set the time zone to non-default (other than UTC)
# Full list of time zones is at:
# https://github.com/openwrt/luci/blob/master/modules/luci-lua-runtime/luasrc/sys/zoneinfo/tzdata.lua
#
echo 'Setting timezone to' $TIMEZONE
uci set system.@system[0].timezone="$TIMEZONE"
echo 'Setting zone name to' $ZONENAME 
uci set system.@system[0].zonename="$ZONENAME"
uci commit system

# === Update the software packages =============
# Download and update all the interesting packages
# Some of these are pre-installed, but there is no harm in
# updating/installing them a second time.
echo 'Updating software packages'
opkg update                # retrieve updated packages
opkg install luci          # install the web GUI
opkg install snmpd         # install snmpd 
opkg install luci-app-sqm  # install the SQM modules to get fq_codel etc
opkg install travelmate	   # install the travelmate package to be a repeater
# opkg install netperf	   # install the netperf module for speed testing
# opkg install ppp-mod-pppoe # install PPPoE module
# opkg install avahi-daemon  # install the mDNS daemon
# opkg install fprobe        # install fprobe netflow exporter

# === Enable SNMP daemon =======================
# Enables responses on IPv4 & IPv6 with same read-only community string
# Supply values for COMMUNITYSTRING and uncomment eleven lines.
echo 'Configuring and starting snmpd'
uci set snmpd.@agent[0].agentaddress='UDP:161,UDP6:161'
uci set snmpd.@com2sec[0].community=$SNMP_COMMUNITYSTRING
uci add snmpd com2sec6
uci set snmpd.@com2sec6[-1].secname=ro
uci set snmpd.@com2sec6[-1].source=default
uci set snmpd.@com2sec6[-1].community=$SNMP_COMMUNITYSTRING
uci commit snmpd
/etc/init.d/snmpd restart   # default snmpd config uses 'public' 
/etc/init.d/snmpd enable  	# community string for SNMPv1 & SNMPv2c

# ==============================
# Set Smart Queue Management (SQM) values for your own network
#
# Use a speed test (http://speedtest.net or other) to determine 
# the speed of your own network, then set the speeds  accordingly.
# Speeds below are in kbits per second (3000 = 3 megabits/sec)
# For details about setting the SQM for your router, see:
# https://openwrt.org/docs/guide-user/network/traffic-shaping/sqm
# Set DOWNLOADSPEED, UPLOADSPEED, WANIF and then uncomment 18 lines
#
# DOWNLOADSPEED=20000
# UPLOADSPEED=2000
# WANIF=eth0
# echo 'Setting SQM on '$WANIF ' to ' $DOWNLOADSPEED/$UPLOADSPEED 'kbps down/up'
# uci set sqm.@queue[0].interface=$WANIF
# uci set sqm.@queue[0].enabled=1
# uci set sqm.@queue[0].download=$DOWNLOADSPEED
# uci set sqm.@queue[0].upload=$UPLOADSPEED
# uci set sqm.@queue[0].script='simple.qos' # Already the default
# uci set sqm.@queue[0].qdisc='fq_codel'
# uci set sqm.@queue[0].itarget='auto'
# uci set sqm.@queue[0].etarget='auto'
# uci set sqm.@queue[0].linklayer='atm'
# uci set sqm.@queue[0].overhead='44'
# uci commit sqm
# /etc/init.d/sqm restart
# /etc/init.d/sqm enable

# === Get parameters for the Router Config Display ===
# 
today=$(date +"%Y-%b-%d")
device=$(cat /tmp/sysinfo/model)
openwrtversion=$(grep "DISTRIB_DESCRIPTION" /etc/openwrt_release | cut -d"=" -f2 | tr -d '"')

echo ""
echo "================================================="
echo " Configured: $today"
echo "     Device: $device" 
echo "    OpenWrt: $openwrtversion" 
echo "        LAN: $LANIPADDRESS"
echo "       User: root"
echo "   Login PW: $NEWPASSWD"
echo "  WiFi SSID: $WIFISSID"
echo "    WiFi PW: $WIFIPASSWD"
echo "================================================="
echo ""

echo 'You should restart the router now for these changes to take effect...'
echo 'Note that there may be a different IP address for the LAN port...'
# --- end of script ---

# ================ 
# 
# The following sections are historical, and can be ignored:
#
# - Enable NetFlow export for traffic analysis
# - Enable mDNS/ZeroConf on eth0 for internal routers *only* 
# - Change default IP addresses and subnets for interfaces
# - Change default DNS names
# - Set the radio channels
# - Set wireless SSID names
# - Set the wireless security credentials

# === Enable NetFlow export ====================
# NetFlow export
# Start fprobe now to send netflow records to local netflow 
#   collector at the following address and port (I use http://intermapper.com) 
# Supply values for NETFLOWCOLLECTORADRS & NETFLOWCOLLECTORADRS
# and uncomment nine lines
#
# NETFLOWCOLLECTORADRS=192.168.2.13
# NETFLOWCOLLECTORPORT=2055
# echo 'Configuring and starting fprobe...'
# fprobe -i ge00 -f ip -d 15 -e 60 $NETFLOWCOLLECTORADRS':'$NETFLOWCOLLECTORPORT
# Also edit /etc/rc.local to add the same command 
#   so that it will start after next reboot
# sed -i '$ i\
# fprobe -i ge00 -f ip -d 15 -e 60 NEWIPPORT' /etc/rc.local
# sed -i s#NEWIPPORT#$NETFLOWCOLLECTORADRS:$NETFLOWCOLLECTORPORT#g /etc/rc.local



# === Update local DNS domain ==================
# DNS: 
# Supply a desired DNS name for NEWDNS and uncomment three lines
#
# NEWDNS=home.lan
# echo 'Changing local domain to' $NEWDNS
# sed -i s#home.lan#$NEWDNS#g /etc/config/*  

# === Update WiFi info for the access point ================
# a) Assign the radio channels
# b) Assign the SSID's
# c) Assign the encryption/passwords
# To see all the wireless info:
#	uci show wireless
#
# Default interface indices and SSIDs are:
#	0 - CEROwrt
#	1 - CEROwrt-guest
#	2 - babel (on 2.4GHz)
#	3 - CEROwrt5
#	4 - CEROwrt-guest5
#	5 - babel (on 5GHz)

# === Assign channels for the wireless radios
# Set the channels for the wireless radios
# Radio0 choices are 1..11
# Radio1 choices are 36, 40, 44, 48, 149, 153, 157, 161, 165
#    The default HT40+ settings bond 36&40, 44&48, etc.
#    Choose 36 or 44 and it'll work fine
# echo 'Setting 2.4 & 5 GHz channels'
# uci set wireless.radio0.channel=6
# uci set wireless.radio1.channel=44

# === Assign the SSID's
# These are the default SSIDs for CeroWrt; no need to set again
# echo 'Setting SSIDs'
# uci set wireless.@wifi-iface[0].ssid=CEROwrt
# uci set wireless.@wifi-iface[1].ssid=CEROwrt-guest
# uci set wireless.@wifi-iface[3].ssid=CEROwrt5
# uci set wireless.@wifi-iface[4].ssid=CEROwrt-guest5

# === Assign the encryption/password ================
# Update the wifi password/security. To see all the wireless info:
#	uci show wireless
# The full list of encryption modes is at: (psk2 gives WPA2-PSK)
# https://openwrt.org/docs/guide-user/network/wifi/basic#encryption_modes 
# echo 'Updating WiFi security information'

# uci set wireless.@wifi-iface[0].key=$WIFIPASSWD
# uci set wireless.@wifi-iface[1].key=$WIFIPASSWD
# uci set wireless.@wifi-iface[3].key=$WIFIPASSWD
# uci set wireless.@wifi-iface[4].key=$WIFIPASSWD

# uci set wireless.@wifi-iface[0].encryption=$ENCRMODE
# uci set wireless.@wifi-iface[1].encryption=$ENCRMODE
# uci set wireless.@wifi-iface[3].encryption=$ENCRMODE
# uci set wireless.@wifi-iface[4].encryption=$ENCRMODE

# uci commit wireless

# === Set up the WAN (eth0) interface for PPPoE =============
# Default is DHCP, this sets it to PPPoE (typical for DSL/ADSL) 
# From http://wiki.openwrt.org/doc/howto/internet.connection
# Supply values for DSLUSERNAME and DSLPASSWORD 
# and uncomment ten lines
#
# echo 'Configuring WAN link for PPPoE'
# DSLUSERNAME=YOUR-DSL-USERNAME
# DSLPASSWORD=YOUR-DSL-PASSWORD
# uci set network.wan.proto=pppoe
# uci set network.wan.username=$DSLUSERNAME
# uci set network.wan.password=$DSLPASSWORD
# uci commit network
# ifup wan
# echo 'Waiting for link to initialize'
# sleep 20

# === Enable mDNS/ZeroConf =====================
# mDNS allows devices to look each other up by name
# This enables mDNS lookups on the LAN (br-lan) interface
# mDNS was useful in CeroWrt because all its interaces
# were routed. In OpenWrt, interfaces are bridge by default
# Uncomment seven lines
# echo 'Enabling mDNS on LAN interface'
# sed -i '/use-iff/ a \
# allow-interfaces=br-lan \
# enable-dbus=no ' /etc/avahi/avahi-daemon.conf
# sed -i s/enable-reflector=no/enable-reflector=yes/ /etc/avahi/avahi-daemon.conf
# /etc/init.d/avahi-daemon start
# /etc/init.d/avahi-daemon enable