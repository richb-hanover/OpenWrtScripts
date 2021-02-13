# Configure snmpd in OpenWrt
# Edit the four variables below (COMMUNITYSTRING, LOCATION, CONTACT, SYSTEMNAME), 
# then run this script using:
# 
#  sh snmp.sh
#
COMMUNITYSTRING=public
LOCATION='Under The House'
CONTACT="somebody@example.com"
SYSTEMNAME="One Really Sweet Router"

echo 'Configuring and starting snmpd'
# Listen port 161 (v4 & v6), with specified community string
uci set snmpd.@agent[0].agentaddress='UDP:161,UDP6:161'
uci set snmpd.@com2sec[0].community="$COMMUNITYSTRING"

# set up to listen for IPv6 queries as well
uci add snmpd com2sec6
uci set snmpd.@com2sec6[-1].secname=ro
uci set snmpd.@com2sec6[-1].source=default
uci set snmpd.@com2sec6[-1].community="$COMMUNITYSTRING"

# Set a few system variables
uci set snmpd.@system[-1].sysLocation="$LOCATION"
uci set snmpd.@system[-1].sysContact="$CONTACT"
uci set snmpd.@system[-1].sysName="$SYSTEMNAME"
uci commit snmpd

# restart the snmpd, and enable it to restart at next boot
/etc/init.d/snmpd restart   
/etc/init.d/snmpd enable  	
