CeroWrtScripts
==============

The CeroWrt router firmware project has largely eliminated the problem of *bufferbloat* on Ethernet for home routers. 
This firmware makes a huge difference for wireless, too, although there's still more work to be done.
The symptoms of bufferbloat give people cause to complain, "the Internet feels slow today." 
The techniques that the CeroWrt team have proved out are being widely adopted across 
the Internet to make everyone's network performance better.

This is a set of scripts (sometimes also called "Ceroscripts") that we use to measure (and improve) latency in home routers (and everywhere else!) 
[http://bufferbloat.net/projects/cerowrt](http://bufferbloat.net/projects/cerowrt)
These scripts include:

* Scripts that measure the performance of your router or offer load to the network for testing.

* Script to configure the CeroWrt router consistently after flashing factory firmware.

* Script to set up a IPv6 6-in-4 tunnel to TunnelBroker.net.

* Script to collect troubleshooting information that helps us diagnose problems in the CeroWrt distribution.

These scripts are bundled into CeroWrt 3.10.44-3 and newer as the 'cerowrtscripts' package, saved in the `/usr/lib/CeroWrtScripts` directory.
To get the newest versions, you can use `opkg update; opkg upgrade`

If the scripts are not built into your version of CeroWrt, it is safe to put them in that CeroWrtScripts directory.
 
---
## betterspeedtest.sh

This script emulates the web-based test performed by speedtest.net, but does it one better. While script performs a download and an upload to a server on the Internet, it simultaneously measures latency of pings to see whether the file transfers affect the responsiveness of your network. 

Here's why that's important: If the data transfers do increase the latency/lag much, then other network activity, such as voice or video chat, gaming, and general network activity will also work poorly. Gamers will see this as lagging out when someone else uses the network. Skype and FaceTime will see dropouts or freezes. Latency is bad, and good routers will not allow it to happen.

The betterspeedtest.sh script measures latency during file transfers. To invoke it:

    sh betterspeedtest.sh [ -4 | -6 ] [ -H netperf-server ] [ -t duration ] [ -p host-to-ping ] [-n simultaneous-streams ]

Options, if present, are:

* -H | --host: DNS or Address of a netperf server (default - netperf.bufferbloat.net)  
Alternate servers are netperf-east (east coast US), netperf-west (California), 
and netperf-eu (Denmark)
* -4 | -6:     Enable ipv4 or ipv6 testing (default - ipv4)
* -t | --time: Duration for how long each direction's test should run - (default - 60 seconds)
* -p | --ping: Host to ping to measure latency (default - gstatic.com)
* -n | --number: Number of simultaneous sessions (default - 5 sessions)

The output shows separate (one-way) download and upload speed, along with a summary of latencies, including min, max, average, median, and 10th and 90th percentiles so you can get a sense of the distribution. The tool also displays the percent packet loss. The example below shows two measurements, bad and good. 

On the left is a test run without SQM. Note that the latency gets huge (greater than 5 seconds), meaning that network performance would be terrible for anyone else using the network. 

On the right is a test using SQM: the latency goes up a little (less than 23 msec under load), and network performance remains good.

    Example with NO SQM - BAD                                     Example using SQM - GOOD
    
    root@cerowrt:/usr/lib/CeroWrtScripts# sh betterspeedtest.sh   root@cerowrt:/usr/lib/CeroWrtScripts# sh betterspeedtest.sh
    [date/time] Testing against netperf.bufferbloat.net (ipv4)    [date/time] Testing against netperf.bufferbloat.net (ipv4)
       with 5 simultaneous sessions while pinging gstatic.com        with 5 simultaneous sessions while pinging gstatic.com
       (60 seconds in each direction)                                (60 seconds in each direction)
    
     Download:  6.19 Mbps                                         Download:  4.75 Mbps
      Latency: (in msec, 58 pings, 0.00% packet loss)              Latency: (in msec, 61 pings, 0.00% packet loss)
          Min: 43.399                                                  Min: 43.092
        10pct: 156.092                                               10pct: 43.916
       Median: 230.921                                              Median: 46.400
          Avg: 248.849                                                 Avg: 46.575
        90pct: 354.738                                               90pct: 48.514
          Max: 385.507                                                 Max: 56.150
    
       Upload:  0.72 Mbps                                           Upload:  0.61 Mbps
      Latency: (in msec, 59 pings, 0.00% packet loss)              Latency: (in msec, 53 pings, 0.00% packet loss)
          Min: 43.699                                                  Min: 43.394
        10pct: 352.521                                               10pct: 44.202
       Median: 4208.574                                             Median: 50.061
          Avg: 3587.534                                                Avg: 50.486
        90pct: 5163.901                                              90pct: 56.061
          Max: 5334.262                                                Max: 69.333

---         
## netperfrunner.sh

This script runs several netperf commands simultaneously.
This mimics the stress test of [netperf-wrapper](https://github.com/tohojo/netperf-wrapper) [Github] but without the nice GUI result.

When you start this script, it concurrently uploads and downloads several
streams (files) to a server on the Internet. This places a heavy load 
on the bottleneck link of your network (probably your connection to the Internet), 
and lets you measure both the total bandwidth and the latency of the link during the transfers.

To invoke the script:

    sh netperfrunner.sh [ -4 | -6 ] [ -H netperf-server ] [ -t duration ] [ -p host-to-ping ] [-n simultaneous-streams ]

Options, if present, are:

* -H | --host: DNS or Address of a netperf server (default - netperf.bufferbloat.net)  
Alternate servers are netperf-east (east coast US), netperf-west (California), 
and netperf-eu (Denmark)
* -4 | -6: Enable ipv4 or ipv6 testing (default - ipv4)
* -t | --time: Duration for how long each direction's test should run - (default - 60 seconds)
* -p | --ping: Host to ping to measure latency (default - gstatic.com)
* -n | --number: Number of simultaneous sessions (default - 4 sessions)

The output of the script looks like this:

    root@cerowrt:/usr/lib/CeroWrtScripts# sh netperfrunner.sh
    [date/time] Testing netperf.bufferbloat.net (ipv4) with 4 streams down and up 
        while pinging gstatic.com. Takes about 60 seconds.
    Download:  5.02 Mbps
      Upload:  0.41 Mbps
     Latency: (in msec, 61 pings, 15.00% packet loss)
         Min: 44.494
       10pct: 44.494
      Median: 66.438
         Avg: 68.559
       90pct: 79.049
         Max: 140.421

**Note:** The download and upload speeds reported may be considerably lower than your line's rated speed. This is not a bug, nor is it a problem with your internet connection. That's because the acknowledge messages sent back to the sender consume a significant fraction of the link's capacity (as much as 25%). 

---
## networkhammer.sh

This script continually invokes the netperfrunner script to provide a heavy load. It runs forever - Ctl-C will interrupt it. 
 
---
## config-cerowrt.sh

This script updates the factory settings of CeroWrt to a known-good configuration.
If you frequently update your firmware, you can use this script to reconfigure
the router to a consistent state.
You should make a copy of this script, customize it to your needs,
then use the "To run this script" procedure (below).

This script is designed to configure the settings after an initial "factory" firmware flash. 
There are sections below to configure many aspects of your router.
All the sections are commented out. There are sections for:

- Set up the ge00/WAN interface to connect to your provider
- Update the software packages
- Update the root password
- Set the time zone
- Enable SNMP for traffic monitoring and measurements
- Enable NetFlow export for traffic analysis
- Enable mDNS/ZeroConf on the ge00 (WAN) interface 
- Change default IP addresses and subnets for interfaces
- Change default DNS names
- Set the SQM (Smart Queue Management) parameters
- Set the radio channels
- Set wireless SSID names
- Set the wireless security credentials

**To run this script**

Flash the router with factory firmware. Then ssh in and execute these statements. 
You should do this over a wired connection because some of these changes
may reset the wireless network.

    ssh root@172.30.42.1
    cd /tmp
    cat > config.sh 
    [paste in the contents of this file, then hit ^D]
    sh config.sh
    Presto! (You should reboot the router when this completes.)

**Note:** If you use a secondary CeroWrt router, you can create another copy of this script, and use it to set different configuration parameters (perhaps different subnets, radio channels, SSIDs, enable mDNS, etc).  

---
## tunnelbroker.sh

This script configures CeroWrt to create an IPv6 tunnel. 
It's an easy way to become familiar with IPv6 if your ISP doesn't offer native IPv6 capabilities. There are three steps:

1. Go to the Hurricane Electric [TunnelBroker.net](http://www.tunnelbroker.net/)  site to set up your free account. There are detailed instructions for setting up an account and an IPv6 tunnel at the
   [CeroWrt IPv6 Tunnel page.](http://www.bufferbloat.net/projects/cerowrt/wiki/IPv6_Tunnel) 
2. Edit the tunnelbroker.sh script, using the parameters supplied by Tunnelbroker.net. They're on the site's "Tunnel Details" page. Click on the "Example
Configurations" tab and select "OpenWRT Backfire 10.03.1". Use the info to fill in the corresponding lines of the script. 
3. ssh into the CeroWrt router and execute this script with these steps.
    
        ssh root@172.30.42.1
        cd /tmp
        cat > tunnel.sh 
        [paste in the contents of this file, then hit ^D]
        sh tunnel.sh
        [Restart your router. This seems to make a difference.]
  
Presto! Your tunnel is up! Your computer should get a global IPv6 address, and should be able to communicate directly with IPv6 devices on the Internet. To test it, try: `ping6 ivp6.google.com`

---
## cerostats.sh

This script collects a number of useful configuration settings and dynamic values for aid in diagnosing problems with CeroWrt. If you report a problem, it would be helpful to include the output of this script.

By default, it collects information about the first 2.4GHz radio/interface, and writes the collected data to `/tmp/cerostats_output.txt`
