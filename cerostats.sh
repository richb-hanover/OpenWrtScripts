#! /bin/sh
# A collection of diagnostic commands to run when troubles arise.
# Based on Sebastian Moeller's original from:
# https://lists.bufferbloat.net/pipermail/cerowrt-devel/2014-April/002871.html
#
# The default script collects stats for the first 2.4GHz interface. 
# Change for your situation.
#
# - phy0 - 2.4GHz radio
# - sw00 - First 2.4GHz wireless interface
# - /tmp/cerostats_output.txt - output file for stats

radio=phy0
wlan_if=sw00
out_fqn=/tmp/cerostats_output.txt

echo -e "[date]" > ${out_fqn}
date >> ${out_fqn}
echo -e "\n" >> ${out_fqn}

echo -e "[uname -a]" >> ${out_fqn}
echo $( uname -a ) >> ${out_fqn}
echo -e "\n" >> ${out_fqn}

echo -e "[uptime]" >> ${out_fqn}
echo $( uptime ) >> ${out_fqn}
echo -e "\n" >> ${out_fqn}

echo -e "[ifconfig]" >> ${out_fqn}
ifconfig >> ${out_fqn}
echo -e "\n" >> ${out_fqn}

echo -e "[top]" >> ${out_fqn}
top -b | head -n 20 >> ${out_fqn}
echo -e "\n" >> ${out_fqn}

echo -e "[tc -s qdisc show dev ${wlan_if}]" >> ${out_fqn}
tc -s qdisc show dev ${wlan_if} >> ${out_fqn}
echo -e "\n" >> ${out_fqn}

echo -e "[iw dev ${wlan_if} station dump]" >> ${out_fqn}
iw dev ${wlan_if} station dump >> ${out_fqn}
echo -e "\n" >> ${out_fqn}

echo -e "[cat /sys/kernel/debug/ieee80211/${radio}/ath9k/ani]" >> ${out_fqn}
cat /sys/kernel/debug/ieee80211/${radio}/ath9k/ani >> ${out_fqn}
echo -e "" >> ${out_fqn}

echo -e "[cat /sys/kernel/debug/ieee80211/${radio}/ath9k/interrupt]" >> ${out_fqn}
cat /sys/kernel/debug/ieee80211/${radio}/ath9k/interrupt >> ${out_fqn}
echo -e "" >> ${out_fqn}

echo -e "[cat /sys/kernel/debug/ieee80211/${radio}/ath9k/queues]" >> ${out_fqn}
cat /sys/kernel/debug/ieee80211/${radio}/ath9k/queues >> ${out_fqn}
echo -e "" >> ${out_fqn}

echo -e "[cat /sys/kernel/debug/ieee80211/${radio}/ath9k/xmit]" >> ${out_fqn}
cat /sys/kernel/debug/ieee80211/${radio}/ath9k/xmit >> ${out_fqn}
echo -e "" >> ${out_fqn}

echo -e "[cat /sys/kernel/debug/ieee80211/${radio}/ath9k/recv]" >> ${out_fqn}
cat /sys/kernel/debug/ieee80211/${radio}/ath9k/recv >> ${out_fqn}
echo -e "" >> ${out_fqn}

echo -e "[cat /sys/kernel/debug/ieee80211/${radio}/ath9k/reset]" >> ${out_fqn}
cat /sys/kernel/debug/ieee80211/${radio}/ath9k/reset >> ${out_fqn}
echo -e "" >> ${out_fqn}

echo -e "[logread]" >> ${out_fqn}
logread >> ${out_fqn}
echo -e "\n" >> ${out_fqn}

echo -e "[dmesg]" >> ${out_fqn}
dmesg >> ${out_fqn}
echo -e "" >> ${out_fqn}

echo "Done... Stats written to ${out_fqn} (${0})"
