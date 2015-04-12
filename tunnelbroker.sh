#!/bin/sh
# Script for setting CeroWrt to create an IPv6 tunnel 
# to Hurricane Electric at http://www.tunnelbroker.net/
# There are two steps:
# 1) Go to the Tunnelbroker.net site to set up your free account
# 2) Run the script below, using the parameters supplied by Tunnelbroker
# This CeroWrt page gives detailed instructions for setting up an IPv6 tunnel: 
#    http://www.bufferbloat.net/projects/cerowrt/wiki/IPv6_Tunnel  
# 
# Once you've created your account and a tunnel, get the "Example
# Configurations" for OpenWRT Backfire, and use the info to fill in this
# file, then save it as a file named "tunnel.sh" Finally, ssh into the 
# router and execute this script with these steps:
# 
# ssh root@172.30.42.1
# cd /tmp
# cat > tunnel.sh 
# [paste in the contents of this file, then hit ^D]
# sh tunnel.sh
# [Restart your router. This seems to make a difference.]
#
# Presto! Your tunnel is set up. You should now be able 
#   communicate directly with IPv6 devices. 

# ==============================================
# Download and update all the interesting packages
# Some of these are pre-installed, but there is no 
# harm in updating/installing them a second time.
opkg update
opkg install 6in4

# ==============================================
# Create a 6in4 interface to tunnel IPv6. These steps show how to
# set the credentials for a Hurricane Electric tunnel
# First create an account at http://HE.net, then use their
# Example Configurations page to get the specifics, which are
# automatically generated specifically for *your* tunnel 
# Copy/paste the information from the Example Configurations
# generated for the OpenWRT Backfire 10.03.1 dropdown
# then edit the following to match your parameters.
#
# NOTE: The username should be your plain UserID (the "Account Name:
# 	on the tunnelbroker.net site) not the long alphanumeric string
#
echo 'Setting up HE.net tunnel'
# ------- USE THE INFORMATION FROM TUNNELBROKER.NET HERE --------
uci set network.henet=interface
uci set network.henet.proto=6in4
uci set network.henet.peeraddr=xxx.xxx.xxx.xxx
uci set network.henet.ip6addr='2001:470:ABCD::2/64'
uci set network.henet.tunnelid=123456
uci set network.henet.username='your-plain-userid'
uci set network.henet.password='your-password'
# ------- END OF TUNNELBROKER.NET INFO --------

# ------- Additional configuration info required for the tunnel --------
# This automatically assigns each LAN interface a /64 from your routed /48
# Set the ip6prefix to use your routed /48 prefix from HE.net
uci set network.henet.ip6prefix='2001:470:ABCD::/48'   
uci set network.henet.mtu=1424
uci set network.henet.ttl=64
uci commit network

# ==============================================
# Configure the 6in4-henet interface into the WAN zone
# CeroWrt puts WAN stuff in zone[0], not zone[1] as with OpenWrt
uci set firewall.@zone[0].network='ge00 henet'
uci commit firewall

# ==============================================
# Invoke the new configuration
echo 'Restarting network... "Device busy (-16)" messages are OK.'
/etc/init.d/network restart
echo 'Restarting firewall...'
/etc/init.d/firewall restart

# Belt and suspenders - you could also restart
echo 'Done. You should restart the router now to make these take effect.'

# ==============================================
# What's going on here?
#
# CeroWrt is configured to do a lot of stuff automatically, so you may not notice
# all the magic that's happening under the covers. Here are some of the configuration
# tricks that have been worked out over the various test releases of CeroWrt 3.10.x
#
# IPv6-in-IPv4 tunnel to Hurricane Electric (http://HE.net):
#
# These lines create an interface named "6in4-henet" that acquires an IPv6 address
# for the CeroWrt router, and also gets the assigned /48 prefix to assign to the 
# individual routed LAN interfaces.
#
# In addition, the script places 6in4-henet into the firewall's WAN zone.
# 
# DNS/DHCP:
#
# dnsmasq-dhcpv6 is the default DNS and DHCP server. By default, it is prepared
# to handle all DNS duties and to hand out IPv4 and IPv6 addresses.
# Each time it restarts, its config file (/etc/config/dhcp) is compiled to 
# create /var/etc/dnsmasq.conf. This in turn links to a conf file at
# /etc/dnsmasq.conf. The latter file contains the information required for 
# handing out IPv6 addresses on the LAN interfaces (se00, sw00, gw00, sw10, gw10).
#
# Restarting services:
# 
# The final step in the script is to restart the network and firewall services.
# It never hurts to reboot the router after this completes.
#
# NB: This has been tested with CeroWrt 3.10.50-1 (July 2014)

# ==============================================
# Re-establishing the Tunnel
#
# NB: As of CeroWrt 3.7.5-2 (Feb 2013), the automatic re-establishment code 
# of the 6in4 module appears not to be working. You will need to re-establish 
# the tunnel manually when your external IP address changes.
#
# To re-establish the tunnel, say, because your external IP address changed,
# you can also use the following URL with these parameters. Note that the 
# USERNAME and PASSWORD are what you type to log into the Tunnelbroker site.
#
# USERNAME is the Account Name 
# PASSWORD is the current password
# TUNNELID is the Tunnel ID  
# https://USERNAME:PASSWORD@ipv4.tunnelbroker.net/ipv4_end.php?tid=TUNNELID
# 
# You can also use a non-HTTPS URL and parameters to re-establish the link.
# This form relies on hashed representations of the credentials since they're
# not carried on a secure connection. You can get more information about the
# parameters at https://ipv4.tunnelbroker.net/ipv4_end.php
#
# USERID is the "User ID" from the Tunnelbroker site's Main Page
# PWHASH is the MD5 hash of the password
# TUNNELID is the Tunnel ID
# http://ipv4.tunnelbroker.net/ipv4_end.php?ip=AUTO&apikey=USERID&pass=PWHASH&tid=TUNNELID
#
# --- end of script ---
