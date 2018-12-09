#! /bin/sh
#
# getstats.sh - Collect diagnostic information about OpenWrt
# Write the data to a file (usually /tmp/openwrtstats.txt)
#
# Usage: sh getstats.sh [ "command 1 to be executed" "command 2" "command 3" ... ]
#
# ***** To install and run this script *****
#
# SSH into your router and execute these statements. 
# 
# ssh root@192.168.1.1
# cd /tmp
# cat > getstats.sh 
# [paste in the contents of this file, then hit ^D]
# sh getstats.sh
# The results listed are written to the designated file
#   (usually /tmp/openwrtstats.txt, unless redirected)
#
# License: GPL Copyright (c) 2013-2018 Rich Brown
#
# Based on Sebastian Moeller's original set of diagnostic info:
# https://lists.bufferbloat.net/pipermail/cerowrt-devel/2014-April/002871.html
# Based on alexmow's script to list user-installed packages
# https://forum.openwrt.org/t/script-to-list-installed-packages-for-simplifying-sysupgrade/7188/16

# File that will receive command results
out_fqn=/tmp/openwrtstats.txt

# ------- display_command() -------
# Format the command results into the output file
# Redirect both standard out and error out to that file.

display_command() { 
	echo "[ $1 ]"  >> $out_fqn
	eval "$1"      >> $out_fqn 2>> $out_fqn
	echo -e "\n"   >> $out_fqn
}

# ------- display_user_packages() ---------
# Display a list of all packages installed after the kernel was built

display_user_packages() {
  echo "[ User-installed packages ]" >> $out_fqn

  install_time=`opkg status kernel | awk '$1 == "Installed-Time:" { print $2 }'`
  opkg status | awk '$1 == "Package:" {package = $2} \
  $1 == "Status:" { user_inst = / user/ && / installed/ } \
  $1 == "Installed-Time:" && $2 != '$install_time' && user_inst { print package }' | \
  sort >> $out_fqn 2>> $out_fqn

  echo -e "\n" >> $out_fqn
} 

# ------- Main Routine -------

# Examine first argument to see if they're asking for help
if [ "$1" == "-h" ] || [ "$1" == "--help" ]
then
	echo 'Usage: sh $0 "command 1 to be executed" "command 2" "command 3" ... '
	echo ' '
	exit
fi


# Write a heading for the file

echo "===== $0 at `date` =====" > $out_fqn

# Display four sets of commands:
# 1. Common diagnostic commands
# 2. Additional user-supplied commands (from the command line)
# 3. User-installed opkg packages
# 4. Longer/less common diagnostic output

# 1. Display the common diagnostic commands
# These are read from the list delimited by "EOF"

while read LINE; do
    display_command "$LINE"
done << EOF
cat /etc/banner
date
cat /etc/openwrt_release
uname -a
uptime
top -b | head -n 20
du -sh / ; du -sh /*
EOF


# 2. Extract arguments from the command line and display them.
while [ $# -gt 0 ] 
do
	display_command "$1" 
	shift 1
done

# 3. Display user-installed opkg packages
display_user_packages

# 4. Display the long/less frequently-needed commands

while read LINE; do
    display_command "$LINE"
done << EOF
ifconfig
logread
dmesg
EOF

# End the report
echo "===== end of $0 =====" >> $out_fqn


#cat $out_fqn
echo "Done... Diagnostic information written to $out_fqn"
echo " "

# Now press Ctl-D, then type "sh getstats.sh"

