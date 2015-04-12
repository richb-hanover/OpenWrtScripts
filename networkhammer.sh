#!/bin/sh
# Continuously hammer the network with continuous netperfrunner tests
# Initially created to put load on Wi-Fi for CeroWrt
#

echo "Hammering the network to gw.home.lan. Hit Ctl-C to cancel"
while True;
do
  ./netperfrunner.sh -H gw.home.lan
done
