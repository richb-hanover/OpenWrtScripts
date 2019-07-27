#!/bin/sh
# Script for configuring OpenWrt to create a new 'henet' interface that 
#  uses '6in4' encapsulation to send your IPv6 packets inside IPv4 packets.
#  It uses Hurricane Electric as the tunnel at http://www.tunnelbroker.net/
#
# There are a few steps to set this up:
# 1) Go to the Tunnelbroker.net site to set up your free account
# 2) From its main page, click "Create Regular Tunnel"
#    - Enter your IP address in "IPv4 Endpoint" (paste in the address you're "viewing from")
#    - Select a nearby Tunnel Server
#    - Click "Create Tunnel"
# 3) On the resulting Tunnel Details page, click "Assign /48" to get a /48 prefix
# 4) From the Tunnel Details page, copy and paste the matching values to the variables below 
#    Note: The User_Name is the name you used to create the account
#    Note: Find the Update_Key on the Advanced Tab of the Tunnel Details page.

User_Name=abdcef
Tunnel_ID=123456
Server_IPv4_Address=123.45.67.89
Client_IPv6_Address=2001:470:abcd:ef::/64
Routed_48=2001:470:abcd::/48
Update_Key=AbCDeF54321vWxYz

# 5) Finally, ssh into the router and execute this script with these steps:
# 
# ssh root@192.168.1.1  # use your router's address 
# cd /tmp
# cat > tunnel.sh 
# [paste in the contents of this file, then hit ^D]
# [edit the script to match your tunnelbroker values (see #4 above)]
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
# Create a 6in4 interface named 'henet' to tunnel IPv6. 
#
echo 'Setting up HE.net tunnel'
uci set network.henet=interface
uci set network.henet.proto=6in4
uci set network.henet.peeraddr=$Server_IPv4_Address
uci set network.henet.ip6addr=$Client_IPv6_Address
uci set network.henet.ip6prefix=$Routed_48_Prefix
uci set network.henet.tunnelid=$Tunnel_ID
uci set network.henet.username=$User_Name
uci set network.henet.password=$Update_Key
uci set network.henet.mtu=1424
uci set network.henet.ttl=64
uci commit network

# ==============================================
# Configure the 6in4-henet interface into the WAN zone (along with wan & wan6)
uci set firewall.@zone[1].network='wan wan6 henet'
uci commit firewall

# ==============================================
# Invoke the new configuration
echo 'Restarting network...'
/etc/init.d/network restart
echo 'Restarting firewall...'
/etc/init.d/firewall restart

# Belt and suspenders - you could also restart
echo 'Done. You could also restart the router now to ensure these take effect.'

# ==============================================
#
# Re-establishing the Tunnel
#
# The automatic re-establishment code of the 6in4 module appears not always to work. 
# If the 6in4 tunnel goes down, you may need to re-establish it manually,
# say, when your external IP address changes.
#
# To re-establish the tunnel, simply paste the following URL (with the parameters defined above).
# into your browser. You should get a cryptic "OK" response.
#
# User_Name is your user account name 
# Update_Key is the Update Key shown above
# Tunnel_ID is the Tunnel ID  
# https://User_Name:Update_Key@ipv4.tunnelbroker.net/nic/update?hostname=Tunnel_ID
#
# --- end of script ---
# 
# Final Steps:
# 1) Hit Ctl-D
# 2) Edit six lines of the file (User_Name through Update_Key) to add your tunnelbroker values 
# 3) Type: sh tunnel.sh 
