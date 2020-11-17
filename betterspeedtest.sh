#!/bin/sh

# betterspeedtest.sh - Script to simulate http://speedtest.net
# Start pinging, then initiate a download, let it finish, then start an upload
# Output the measured transfer rates and the resulting ping latency
# It's better than 'speedtest.net' because it measures latency *while* measuring the speed.

# Usage: sh betterspeedtest.sh [-4 -6] [ -H netperf-server ] [ -t duration ] [ -p host-to-ping ] [ -i ] [ -n simultaneous-streams ]

# Options: If options are present:
#
# -H | --host:   DNS or Address of a netperf server (default - netperf.bufferbloat.net)
#                Alternate servers are netperf-east (east coast US), netperf-west (California), 
#                and netperf-eu (Denmark)
# -4 | -6:       enable ipv4 or ipv6 testing (ipv4 is the default)
# -t | --time:   Duration for how long each direction's test should run - (default - 60 seconds)
# -p | --ping:   Host to ping to measure latency (default - gstatic.com)
# -i | --idle:   Don't send traffic, only measure idle latency
# -n | --number: Number of simultaneous sessions (default - 5 sessions)

# Copyright (c) 2014-2019 - Rich Brown rich.brown@blueberryhillsoftware.com
# GPLv2

# Summarize the contents of the ping's output file to show min, avg, median, max, etc.
#   input parameter ($1) file contains the output of the ping command

summarize_pings() {     
  
  # Process the ping times, and summarize the results
  # grep to keep lines that have "time=", then sed to isolate the time stamps, and sort them
  # awk builds an array of those values, and prints first & last (which are min, max) 
  # and computes average.
  # If the number of samples is >= 10, also computes median, and 10th and 90th percentile readings

  # stop pinging and drawing dots
  kill_pings
  kill_dots

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
      {   ix=int(numrows/10); pc10=arr[ix]; ix=int(numrows*9/10);pc90=arr[ix]; \
        if (numrows%2==1) med=arr[(numrows+1)/2]; else med=(arr[numrows/2]); \
      }; \
      pktloss = numdrops/(numdrops+numrows) * 100; \
      printf("\n  Latency: (in msec, %d pings, %4.2f%% packet loss)\n      Min: %4.3f \n    10pct: %4.3f \n   Median: %4.3f \n      Avg: %4.3f \n    90pct: %4.3f \n      Max: %4.3f\n", numrows, pktloss, arr[1], pc10, med, sum/numrows, pc90, arr[numrows] )\
     }'

  # and finally remove the PINGFILE
  rm $1

}

# Print a line of dots as a progress indicator.

print_dots() {
  while : ; do
    printf "."
    sleep 1s
  done
}

# Stop the current print_dots() process

kill_dots() {
  # echo "Pings: $ping_pid Dots: $dots_pid"
  kill -9 $dots_pid
  wait $dots_pid 2>/dev/null
  dots_pid=0
}

# Stop the current ping process

kill_pings() {
  # echo "Pings: $ping_pid Dots: $dots_pid"
  kill -9 $ping_pid 
  wait $ping_pid 2>/dev/null
  ping_pid=0
}

# Stop the current pings and dots, and exit
# ping command catches (and handles) first Ctrl-C, so you have to hit it again...
kill_pings_and_dots_and_exit() {
  kill_dots
  kill_pings
  echo "\nStopped"
  exit 1
}

# ------------ start_pings() ----------------
# Start printing dots, then start a ping process, saving the results to a PINGFILE

start_pings() {

  # Create temp file
  PINGFILE=`mktemp /tmp/measurepings.XXXXXX` || exit 1

  # Start dots
  print_dots &
  dots_pid=$!
  # echo "Dots PID: $dots_pid"

  # Start Ping
  if [ $TESTPROTO -eq "-4" ]
  then
    "${PING4}"  $PINGHOST > $PINGFILE &
  else
    "${PING6}"	$PINGHOST > $PINGFILE &
  fi
  ping_pid=$!
  # echo "Ping PID: $ping_pid"

}

# ------------ Measure speed and ping latency for one direction ----------------
#
# Call measure_direction() with single parameter - "Download" or "  Upload"
#   The function gets other info from globals determined from command-line arguments

measure_direction() {

  # Create temp file
  SPEEDFILE=`mktemp /tmp/netperfUL.XXXXXX` || exit 1
  DIRECTION=$1
  
  # start off the ping process
  start_pings

  # Start netperf with the proper direction
  if [ $DIRECTION = "Download" ]; then
    dir="TCP_MAERTS"
  else
    dir="TCP_STREAM"
  fi
  
  # Start $MAXSESSIONS datastreams between netperf client and the netperf server
  # netperf writes the sole output value (in Mbps) to stdout when completed
  for i in $( seq $MAXSESSIONS )
  do
    netperf $TESTPROTO -H $TESTHOST -t $dir -l $TESTDUR -v 0 -P 0 >> $SPEEDFILE &
    # echo "Starting PID $! params: $TESTPROTO -H $TESTHOST -t $dir -l $TESTDUR -v 0 -P 0 >> $SPEEDFILE"
  done
  
  # Wait until each of the background netperf processes completes 
  # echo "Process is $$"
  # echo `pgrep -P $$ netperf `

  for i in `pgrep -P $$ netperf `   # gets a list of PIDs for child processes named 'netperf'
  do
    #echo "Waiting for $i"
    wait $i
  done

  # Print TCP Download speed
  echo ""
  awk -v dir="$1" '{s+=$1} END {printf " %s: %1.2f Mbps", dir, s}' < $SPEEDFILE 

  # When netperf completes, summarize the ping data
  summarize_pings $PINGFILE

  rm $SPEEDFILE
}

# ------- Start of the main routine --------

# Usage: sh betterspeedtest.sh [ -4 -6 ] [ -H netperf-server ] [ -t duration ] [ -p host-to-ping ] [ -i ] [ -n simultaneous-sessions ]

# “H” and “host” DNS or IP address of the netperf server host (default: netperf.bufferbloat.net)
# “t” and “time” Time to run the test in each direction (default: 60 seconds)
# “p” and “ping” Host to ping for latency measurements (default: gstatic.com)
# "i" and "idle" Don't send up/down traffic - just measure idle link latency
# "n" and "number" Number of simultaneous upload or download sessions (default: 5 sessions;
#       5 sessions chosen empirically because total didn't increase much after that number)

# set an initial values for defaults
TESTHOST="netperf.bufferbloat.net"
TESTDUR="60"

PING4=ping
command -v ping4 > /dev/null 2>&1 && PING4=ping4
PING6=ping6

PINGHOST="gstatic.com"
MAXSESSIONS="5"
TESTPROTO="-4"
IDLETEST=false

# read the options

# extract options and their arguments into variables.
while [ $# -gt 0 ] 
do
    case "$1" in
      -4|-6) TESTPROTO=$1 ; shift 1 ;;
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
      -i|--idle)
        IDLETEST=true ; shift 1 ;;
      --) shift ; break ;;
        *) echo "Usage: sh betterspeedtest.sh [-4 -6] [ -H netperf-server ] [ -t duration ] [ -p host-to-ping ] [ -n simultaneous-sessions ] [ --idle ]" ; exit 1 ;;
    esac
done

# Start the main test

if [ $TESTPROTO -eq "-4" ]
then
  PROTO="ipv4"
else
  PROTO="ipv6"
fi
DATE=`date "+%Y-%m-%d %H:%M:%S"`

# Catch a Ctl-C and stop the pinging and the print_dots
trap kill_pings_and_dots_and_exit HUP INT TERM

if $IDLETEST
then
  echo "$DATE Testing idle line while pinging $PINGHOST ($TESTDUR seconds)"
  start_pings
  sleep $TESTDUR
  summarize_pings $PINGFILE

else
  echo "$DATE Testing against $TESTHOST ($PROTO) with $MAXSESSIONS simultaneous sessions while pinging $PINGHOST ($TESTDUR seconds in each direction)"
  measure_direction "Download" 
  measure_direction "  Upload" 
fi

