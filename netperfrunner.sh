#! /bin/sh
# Netperfrunner.sh - a shell script that runs several netperf commands simultaneously.
# This mimics the stress test of Flent (www.flent.org - formerly, "netperf-wrapper") 
# from Toke <toke@toke.dk> but doesn't have the nice GUI result. 
# This can live in /usr/lib/OpenWrtScripts
# 
# When you start this script, it concurrently uploads and downloads multiple
# streams (files) to a server on the Internet. This places a heavy load 
# on the bottleneck link of your network (probably your connection to the 
# Internet). It also starts a ping to a well-connected host. It displays:
#
# a) total bandwidth available 
# b) the distribution of ping latency
 
# Usage: sh netperfrunner.sh [ -4 -6 ] [ -H netperf-server ] [ -t duration ] [ -t host-to-ping ] [ -n simultaneous-streams ]

# Options: If options are present:
#
# -H | --host:   DNS or Address of a netperf server (default - netperf.bufferbloat.net)
#                Alternate servers are netperf-east (east coast US), netperf-west (California), 
#                and netperf-eu (Denmark)
# -4 | -6:       IPv4 or IPv6 
# -t | --time:   Duration for how long each direction's test should run - (default - 60 seconds)
# -p | --ping:   Host to ping to measure latency (default - gstatic.com)
# -n | --number: Number of simultaneous sessions (default - 5 sessions)

# Copyright (c) 2014 - Rich Brown rich.brown@blueberryhillsoftware.com
# GPLv2

# Summarize the contents of the ping's output file to show min, avg, median, max, etc.
# 	input parameter ($1) file contains the output of the ping command

summarize_pings() {			
	
	# Process the ping times, and summarize the results
	# grep to keep lines that have "time=", then sed to isolate the time stamps, and sort them
	# awk builds an array of those values, and prints first & last (which are min, max) 
	#	and computes average.
	# If the number of samples is >= 10, also computes median, and 10th and 90th percentile readings
	sed 's/^.*time=\([^ ]*\) ms/\1/' < $1 | grep -v "PING" | sort -n | \
	awk 'BEGIN {numdrops=0; numrows=0;} \
		{ \
			if ( $0 ~ /timeout/ ) { \
			   	numdrops += 1; \
			} else { \
				numrows += 1; \
				arr[numrows]=$1; sum+=$1; \
			} \
		} \
		END { \
			pc10="-"; pc90="-"; med="-"; \
			if (numrows == 0) {numrows=1} \
			if (numrows>=10) \
			{ 	ix=int(numrows/10); pc10=arr[ix]; ix=int(numrows*9/10);pc90=arr[ix]; \
				if (numrows%2==1) med=arr[(numrows+1)/2]; else med=(arr[numrows/2]); \
			}; \
			pktloss = numdrops/(numdrops+numrows) * 100; \
			printf("  Latency: (in msec, %d pings, %4.2f%% packet loss)\n      Min: %4.3f \n    10pct: %4.3f \n   Median: %4.3f \n      Avg: %4.3f \n    90pct: %4.3f \n      Max: %4.3f\n", numrows, pktloss, arr[1], pc10, med, sum/numrows, pc90, arr[numrows] )\
		 }'
}

# ------- Start of the main routine --------

# Usage: sh betterspeedtest.sh [ -H netperf-server ] [ -t duration ] [ -p host-to-ping ]

# “H” and “host” DNS or IP address of the netperf server host (default: netperf.bufferbloat.net)
# “t” and “time” Time to run the test in each direction (default: 60 seconds)
# “p” and “ping” Host to ping for latency measurements (default: gstatic.com)
# "n" and "number" Number of simultaneous upload or download sessions (default: 4 sessions;
#       4 sessions chosen to match default of RRUL test)

# set an initial values for defaults
TESTHOST="netperf.bufferbloat.net"
TESTDUR="60"

PING4=ping
command -v ping4 > /dev/null 2>&1 && PING4=ping4
PING6=ping6

PINGHOST="gstatic.com"
MAXSESSIONS=4
TESTPROTO=-4

# Create temp files for netperf up/download results
ULFILE=`mktemp /tmp/netperfUL.XXXXXX` || exit 1
DLFILE=`mktemp /tmp/netperfDL.XXXXXX` || exit 1
PINGFILE=`mktemp /tmp/measurepings.XXXXXX` || exit 1
# echo $ULFILE $DLFILE $PINGFILE

# read the options

# extract options and their arguments into variables.
while [ $# -gt 0 ] 
do
    case "$1" in
	    -4|-6) TESTPROTO=$1; shift 1 ;;
        -H|--host)
            case "$2" in
                "") echo "Missing hostname" ; exit 1 ;;
                *) TESTHOST=$2 ; shift 2 ;;
            esac ;;
        -t|--time) 
        	case "$2" in
        		"") echo "Missing duration" ; exit 1 ;;
                *) TESTDUR=$2 ; shift 2 ;;
            esac ;;
        -p|--ping)
            case "$2" in
                "") echo "Missing ping host" ; exit 1 ;;
                *) PINGHOST=$2 ; shift 2 ;;
            esac ;;
        -n|--number)
        	case "$2" in
        		"") echo "Missing number of simultaneous sessions" ; exit 1 ;;
        		*) MAXSESSIONS=$2 ; shift 2 ;;
        	esac ;;
        --) shift ; break ;;
        *) echo "Usage: sh Netperfrunner.sh [ -H netperf-server ] [ -t duration ] [ -p host-to-ping ] [ -n simultaneous-streams ]" ; exit 1 ;;
    esac
done

# Start main test

if [ $TESTPROTO -eq "-4" ]
then
	PROTO="ipv4"
else
	PROTO="ipv6"
fi
DATE=`date "+%Y-%m-%d %H:%M:%S"`
echo "$DATE Testing $TESTHOST ($PROTO) with $MAXSESSIONS streams down and up while pinging $PINGHOST. Takes about $TESTDUR seconds."
# echo "It downloads four files, and concurrently uploads four files for maximum stress."
# echo "It also pings a well-connected host, and prints a summary of the latency results."
# echo "This test is part of the CeroWrt project. To learn more, visit:"
# echo "  http://bufferbloat.net/projects/cerowrt/"

# Start Ping
if [ $TESTPROTO -eq "-4" ]
then
	"${PING4}" $PINGHOST > $PINGFILE &
else
	"${PING6}" $PINGHOST > $PINGFILE &
fi
ping_pid=$!
# echo "Ping PID: $ping_pid"

# Start $MAXSESSIONS upload datastreams from netperf client to the netperf server
# netperf writes the sole output value (in Mbps) to stdout when completed
for i in $( seq $MAXSESSIONS )
do
	netperf $TESTPROTO -H $TESTHOST -t TCP_STREAM -l $TESTDUR -v 0 -P 0 >> $ULFILE &
	# echo "Starting upload #$i $!"
done

# Start $MAXSESSIONS download datastreams from netperf server to the client
for i in $( seq $MAXSESSIONS )
do
	netperf $TESTPROTO -H $TESTHOST -t TCP_MAERTS -l $TESTDUR -v 0 -P 0 >> $DLFILE &
	# echo "Starting download #$i $!"
done

# Wait until each of the background netperf processes completes 
# echo "Process is $$"
# echo `pgrep -P $$ netperf `

for i in `pgrep -P $$ netperf`		# get a list of PIDs for child processes named 'netperf'
do
	# echo "Waiting for $i"
	wait $i
done

# Stop the pings after the netperf's are all done
kill -9 $ping_pid
wait $ping_pid 2>/dev/null

# sum up all the values (one line per netperf test) from $DLFILE and $ULFILE
# then summarize the ping stat's
echo " Download: " `awk '{s+=$1} END {print s}' $DLFILE` Mbps
echo "   Upload: " `awk '{s+=$1} END {print s}' $ULFILE` Mbps
summarize_pings $PINGFILE

# Clean up
rm $PINGFILE
rm $DLFILE
rm $ULFILE
