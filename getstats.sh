#! /bin/sh
#
# getstats.sh - Collect diagnostic information when troubles arise.
# Write the data to a file (usually /tmp/openwrtstats.txt)
#
# ***** To run this script *****
#
# SSH into your router and execute these statements. 
# 
# ssh root@192.168.1.1
# cd /tmp
# cat > getstats.sh 
# [paste in the contents of this file, then hit ^D]
# sh getstats.sh
# You should see the results listed on-screen
#
# Based on Sebastian Moeller's original from:
# https://lists.bufferbloat.net/pipermail/cerowrt-devel/2014-April/002871.html
#
# The script defaults to writing stats in /tmp/openwrtstats.txt
# Change for your circumstances

out_fqn=/tmp/openwrtstats.txt

echo -e "[date]"                 > ${out_fqn}
date                            >> ${out_fqn}
echo -e "\n"                    >> ${out_fqn}

echo -e "[uname -a]"            >> ${out_fqn}
echo $( uname -a )              >> ${out_fqn}
echo -e "\n"                    >> ${out_fqn}

echo -e "[uptime]"              >> ${out_fqn}
echo $( uptime )                >> ${out_fqn}
echo -e "\n"                    >> ${out_fqn}

echo -e "[ifconfig]"            >> ${out_fqn}
ifconfig                        >> ${out_fqn}
echo -e "\n"                    >> ${out_fqn}

echo -e "[top]"                 >> ${out_fqn}
top -b | head -n 20             >> ${out_fqn}
echo -e "\n"                    >> ${out_fqn}

echo -e "[tc -s qdisc]"         >> ${out_fqn}
tc -s qdisc                     >> ${out_fqn}
echo -e "\n"                    >> ${out_fqn}

echo -e "[ip: path & version]"  >> ${out_fqn}
which ip                        >> ${out_fqn}
ip -V                           >> ${out_fqn}
echo -e "\n"                    >> ${out_fqn}

echo -e "[Installed Modules]"   >> ${out_fqn}
ls -alR /lib/modules/*          >> ${out_fqn}
echo -e "\n"                    >> ${out_fqn}

echo -e "[SQM stop]"            1>> ${out_fqn}
SQM_DEBUG=1 SQM_VERBOSITY=8     2>> ${out_fqn}
/etc/init.d/sqm stop            2>> ${out_fqn}
echo -e "\n"                    1>> ${out_fqn}

echo -e "[SQM   start]"         1>> ${out_fqn}
SQM_DEBUG=1 SQM_VERBOSITY=8     2>> ${out_fqn}
/etc/init.d/sqm start           2>> ${out_fqn}
SQM_DEBUG=0                     2>> ${out_fqn}
echo -e "\n"                    1>> ${out_fqn}

echo -e "[SQM debug directory]" >> ${out_fqn}
ls -R -al /var/run/sqm          >> ${out_fqn}
echo -e "\n"                    >> ${out_fqn}

echo -e "[SQM debug log files]" >> ${out_fqn}
tail -n +1 /var/run/sqm/*.log   >> ${out_fqn}
echo -e "\n"                    >> ${out_fqn}

echo -e "[logread]"             >> ${out_fqn}
logread                         >> ${out_fqn}
echo -e "\n"                    >> ${out_fqn}

echo -e "[dmesg]"               >> ${out_fqn}
dmesg                           >> ${out_fqn}
echo -e ""                      >> ${out_fqn}

echo "Done... Stats written to ${out_fqn} (${0})"
echo " "
clear
echo "============= Output from ${0} ============="
cat ${out_fqn}
echo "Output is also in ${out_fqn}"

# Now press Ctl-D, then type "sh getstats.sh"

