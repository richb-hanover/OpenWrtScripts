#!/bin/sh
# Update the factory settings of OpenWrt to a known-good configuration.
# You should make a copy of this script, customize it to your needs,
# then use the "To run this script" procedure (below).
#
# This script is designed to configure all the settings needed to 
# set up your router after an initial "factory" firmware flash. 
#
# There are sections below to configure many aspects of your router.
# All the sections are commented out. There are sections for:
# 
# - Update the root password
# - Set up the eth0/WAN interface to connect to via PPPoE
# - Update the software packages
# - Set the time zone
# - Enable SNMP for traffic monitoring and measurements
# - Enable mDNS/ZeroConf on the br-lan (LAN) interface 
# - Set the SQM (Smart Queue Management) parameters
#
# ***** To run this script *****
#
# Flash the router with factory firmware. Then *telnet* in and execute these statements. 
# You should do this over a wired connection because some of these changes
# can reset the wireless network.
# 
# telnet 192.168.1.1
# cd /tmp
# cat > config.sh 
# [paste in the contents of this file, then hit ^D]
# sh config.sh
# Presto! (You should reboot the router when this completes.)

# === Update root password =====================
# Update the root password. Supply new password for NEWPASSWD and
# uncomment six lines.
# 
# echo 'Updating root password'
# NEWPASSWD=your-new-root-password
# passwd <<EOF
# $NEWPASSWD
# $NEWPASSWD
# EOF

# === Set up the WAN (eth0) interface ==================
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

# === Update the software packages =============
# Download and update all the interesting packages
# Some of these are pre-installed, but there is no harm in
# updating/installing them a second time.
# echo 'Updating software packages'
# opkg update                # retrieve updated packages
# opkg install luci          # install the web GUI
# opkg install snmpd fprobe  # install snmpd & fprobe
# opkg install luci-app-sqm  # install the SQM modules to get fq_codel etc
# opkg install ppp-mod-pppoe # install PPPoE module
# opkg install avahi-daemon  # install the mDNS daemon
# opkg install netperf		 # install the netperf module for speed testing

# === Set the Time Zone ========================
# Set the time zone to non-default (other than UTC)
# Full list of time zones is at:
#	http://wiki.openwrt.org/doc/uci/system#time.zones
# Use the URL above to find the desired ZONENAME and TIMEZONE, 
# then uncomment seven lines
#
# TIMEZONE='EST5EDT,M3.2.0,M11.1.0'
# ZONENAME='America/New York'
# echo 'Setting timezone to' $TIMEZONE
# uci set system.@system[0].timezone="$TIMEZONE"
# echo 'Setting zone name to' $ZONENAME 
# uci set system.@system[0].zonename="$ZONENAME"
# uci commit system

# === Enable SNMP daemon =======================
# Enables responses on IPv4 & IPv6 with same read-only community string
# Supply values for COMMUNITYSTRING and uncomment eleven lines.
# COMMUNITYSTRING=public
# echo 'Configuring and starting snmpd'
# uci set snmpd.@agent[0].agentaddress='UDP:161,UDP6:161'
# uci set snmpd.@com2sec[0].community=$COMMUNITYSTRING
# uci add snmpd com2sec6
# uci set snmpd.@com2sec6[-1].secname=ro
# uci set snmpd.@com2sec6[-1].source=default
# uci set snmpd.@com2sec6[-1].community=$COMMUNITYSTRING
# uci commit snmpd
# /etc/init.d/snmpd restart   # default snmpd config uses 'public' 
# /etc/init.d/snmpd enable  	# community string for SNMPv1 & SNMPv2c

# === Enable mDNS/ZeroConf =====================
# mDNS allows devices to look each other up by name
# This enables mDNS lookups on the LAN (br-lan) interface
# Uncomment seven lines
#
# echo 'Enabling mDNS on LAN interface'
# sed -i '/use-iff/ a \
# allow-interfaces=br-lan \
# enable-dbus=no ' /etc/avahi/avahi-daemon.conf
# sed -i s/enable-reflector=no/enable-reflector=yes/ /etc/avahi/avahi-daemon.conf
# /etc/init.d/avahi-daemon start
# /etc/init.d/avahi-daemon enable

# ==============================
# Set Smart Queue Management (SQM) values for your own network
#
# Use a speed test (http://dslreports.com/speedtest) to determine 
# the speed of your own network, then set the speeds  accordingly.
# Speeds below are in kbits per second (3000 = 3 megabits/sec)
# For details about setting the SQM for your router, see:
# http://wiki.openwrt.org/doc/howto/sqm
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


echo 'You should restart the router now for these changes to take effect...'
# --- end of script ---

# ================ 
# 
# The following sections have not been completed, and should not be uncommented:
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

# === Enable mDNS/ZeroConf =====================
# Enable avahi to relay mDNS queries out the "WAN" port.
# YOU SHOULD NEVER DO THIS if CeroWrt is your primary router - that is, if it's
# connected directly to the Internet, as it will leak private information. 
# To enable mDNS, uncomment two lines, and reboot the router afterwards
###
### IF THIS IS YOUR PRIMARY ROUTER, DO NOT DO THIS!       ###
### IT COULD LEAK YOUR mDNS NAMES INTO THE INTERNET!      ###
### (But it's useful if this is your secondary router.)   ###
###
# echo 'Enabling mDNS'
# sed -i s/deny-interfaces=ge00/#deny-interfaces=ge00/g /etc/avahi/avahi-daemon.conf

# === Update IP Subnet Ranges ==================
# Changing configuration for Subnets, DNS, SSIDs, etc. 
# See this page for details:
#    http://www.bufferbloat.net/projects/cerowrt/wiki/Changing_your_cerowrt_ip_addresses
# If you do any of these, you should reboot the router afterwards
#
# Subnet:
# Supply values for NEWIP and REVIP (e.g. 192.168.1 and 1.168.192, respectively)
#   in the lines below, then uncomment five lines
#
# NEWIP=your.new.ip
# REVIP=ip.new.your
# echo 'Changing IP subnets to' $NEWIP 'and' $REVIP
# sed -i s#172.30.42#$NEWIP#g /etc/config/* 

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
#	http://wiki.openwrt.org/doc/uci/wireless#wpa.modes
# Set WIFIPASSWD and the ENCRMODE, and then uncomment the remaining lines.
# 
# echo 'Updating WiFi security information'
# WIFIPASSWD='Beatthebloat'
# ENCRMODE=psk2

# uci set wireless.@wifi-iface[0].key=$WIFIPASSWD
# uci set wireless.@wifi-iface[1].key=$WIFIPASSWD
# uci set wireless.@wifi-iface[3].key=$WIFIPASSWD
# uci set wireless.@wifi-iface[4].key=$WIFIPASSWD

# uci set wireless.@wifi-iface[0].encryption=$ENCRMODE
# uci set wireless.@wifi-iface[1].encryption=$ENCRMODE
# uci set wireless.@wifi-iface[3].encryption=$ENCRMODE
# uci set wireless.@wifi-iface[4].encryption=$ENCRMODE

# uci commit wireless
