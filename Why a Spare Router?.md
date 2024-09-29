# Why a "Spare Router" Configuration?

Many people who use OpenWrt wind up with unused routers when
they retire one for a newer device.
These are perfectly functioning devices that are perhaps older or missing a certain function.

They could be easily re-used and passed along to friends, family or neighbors.
BUT... you have to solve a couple problems:

1. The router retains all your personal info:
  passwords, certificates, idiosyncratic packages. etc.
2. You can't remember how it was configured, so you
  can't even connect to it.
  
**The remedy:** A "spare router" configuration script that
you can use when you take a router out of service.
It leaves the router with current OpenWrt firmware
configured for Wifi access, and
a known useful set of package to make it easy to reuse.
The script also prints a label that you can attach to
the router so that you can get started quickly the next
time you get it out.

## Usage

When you retire a router from service, run this script.
It is available at
[config-spare-router.sh](https://github.com/richb-hanover/OpenWrtScripts/blob/master/config-spare-router.sh)
To use it:

* Connect via Ethernet to a LAN port
* Use the LuCI GUI to reset settings to
  factory default (**System -> Backup/Flash firmware**)
* Use the [Firmware Selector](https://firmware-selector.openwrt.org/)
  to find and flash the latest firmware
* SSH into the router using the Ethernet connection
* Run the attached script (see the instructions within it)
* The script prints a label: cut it out and tape it to the router
* _Pro tip:_ Snip the model number from the paper 
  and tape it directly to the power brick.
  (Use the text from the "Power Brick Label" section.)
* _Pro tip:_ Place the router and its power brick in a ziploc bag
  to keep them together.

The `config-spare-router.sh` script may be run multiple times without bad effect.
When the script completes, it displays configuration like this,
suitable for printing and taping to the router.

```
=================================================
     Device: D-Link DIR-878 A1
    OpenWrt: 'OpenWrt 23.05.5 r24106-10cc5fcd00'
 Connect to: http://SpareRouter.local
         or: ssh root@SpareRouter.local
        LAN: 172.30.42.1
       User: root
   Login PW: SpareRouter
  WiFi SSID: SpareRouter
    WiFi PW:
 Configured: 2024-Sep-26
=================================================

Power Brick Label: D-Link DIR-878 A1

```

## When you (re)deploy the router

The default settings are (intentionally) insecure.
Remember to change the following:

* Root password (**System -> Administration**)
* Wifi credentials (**Network -> Wireless**) 
* Enable other Wifi radios (**Network -> Wireless**) 
* Change the LAN interace IP address and other settings as needed (**Network -> Interfaces**)
* (Optional) Configure SQM (**Network -> SQM QoS**)
* (Optional) Change the hostname (**System -> System**)
* (Optional) Install other packages as needed
* (Optional) Travelmate (**Services -> Travelmate**)
  Click the **Interface Wizard** button one time
  
## Rationale for the configuration choices

This script was designed for ease of use.
It presumes that it is being installed on a modern (post-2021)
router that has plenty of RAM and Flash storage, so that size
was not a consideration.

* **Root password:** To make it easy to re-use the router,
  the `root` password is set to `SpareRouter`.
  There is no need for strong security here, as you will be changing
  the password when you set it up in its new location.
* **LAN Address:** The LAN IP address is set to `172.30.42.1`. 
  This is a
  [valid private IP address range](https://en.wikipedia.org/wiki/Private_network)
  (like `10...` and `192.168...` subnets) but it is less commonly used.
  This means that you can bring the router into virtually any
  network environment without concern for IP address conflicts,
  then use the LuCI GUI to configure the LAN.
* **Hostname:** is set to "SpareRouter".
  Because `umdns` is installed, you can connect using
  `http://SpareRouter.local` or `ssh root@SpareRouter.local`
  no matter what the LAN IP address is.
* **Wifi settings:** The SSID is of the _first_ radio is set
  to `SpareRouter` without encryption.
  No other radios are enabled.
  As with the root password, there is no need for a strong password,
  because you will be changing it immediately.
* **Time Zone:** As a convenience, the time zone is set to `Americas/New York`.
  You can use the LuCI GUI to re-configure as needed.
* **Software packages:** The script installs a minimal set of useful 
  packages that are required to bootstrap a new router.

  * **luci** Released versions of OpenWrt already install `luci`,
    re-installing does no harm.
  * **umdns** To allow the router to advertise its name as "SpareRouter"
    (e.g., connect using `ssh root@sparerouter`)
  * **luci-app-sqm** All OpenWrt routers should have the SQM package installed
    to minimize bufferbloat
  * **travelmate**	_and_
  * **luci-app-travelmate** This package allows a router to
    act as a Wifi repeater by making a wireless "uplink"
    to an existing network
    Even if there's no Ethernet connection for the spare routers's WAN port,
    the wireless uplink lets you download additional packages.
    
## Modifications

This script provides a stable platform for re-deploying old routers.
Feel free to make suggestions (create an Issue) for _minimal_ tweaks that
would improve the script. Enjoy!

## Old information

The script also has a large number of lines that are commented out.
These were steps for other packages that are not essential for a "Spare Router".
Feel free to experiment with these sections in your own copy of the script.
