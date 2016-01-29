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

# Output file name
out_fqn=/tmp/junk.txt
# Redirect command
outfile="2>&1 >>$out_fqn"
# eval echo xx $outfile

# echo "Number of arguments is $#; $1"
eval echo "===== Output from $0 at `date` =====" > $out_fqn

display_command() { 
	echo "[ $1 ]"           >> $out_fqn
	eval "$1"               >> $out_fqn 2>> $out_fqn
	echo -e "\n"           	>> $out_fqn
}

# ------- Main Routine -------

# Look to see if they're asking for help
if [ "$1" == "-h" ] 
then
	echo 'Usage: sh getstats.sh "command 1 to be executed" "command 2" "command 3" ... '
	exit
fi

# Handle the standard set of commands first
while read LINE; do
#	echo "$LINE"
    display_command "$LINE"
done << EOF
cat /etc/banner
date
uname -a
uptime
top -b | head -n 20
ifconfig
EOF

#logread 
#dmesg
#cat /etc/openwrt_release

# extract options and their arguments into variables.
while [ $# -gt 0 ] 
do
	display_command "$1" 
	shift 1
done

echo "Done... Stats written to ${out_fqn} (${0})"
echo " "
clear
#cat ${out_fqn}
echo "Output is also in ${out_fqn}"

# Now press Ctl-D, then type "sh getstats.sh"

