# AHRS from FIX Gateway
This is a small hack to get AHRS data from Makerplane FIX Gateway into stratux. I wrote this because I already had reliable and accurate AHRS data in FIX Gateway and wanted to pass it along to stratux so it could also be used in an EFB.

## Installing
These instructions are written for Ubuntu and were only tested on 23.10

### Install dependencies
```
sudo apt install -y librtlsdr-dev libusb-1.0-0-dev pkg-config debhelper libjpeg-dev i2c-tools python3-smbus python3-pip python3-dev python3-pil python3-daemon screen autoconf libfftw3-bin libfftw3-dev libtool build-essential mercurial libncurses-dev golang ifupdown net-tools bridge-utils libconfig9 dnsmasq-base git cmake libusb-1.0-0-dev build-essential autoconf libtool i2c-tools libfftw3-dev libncurses-dev python3-serial jq ifplugd iptables
```

### Clone stratux repo
```
cd ~/.makerplane/stratux
git clone --recursive https://github.com/b3nn0/stratux.git
```

### Replace sensors.go
```
cp sensors.go stratux/main/
```

### Modify network template
```
sed -i 's/# allow-hotplug eth0 # configured by ifplugd/# Bridge for local ethernet and waydroid/g' stratux/image/interfaces.template 
sed -i 's/iface eth0 inet dhcp/iface eth0 inet manual\n\nauto br0\niface br0 inet static\n  address 192.168.2.1\n  broadcast 192.168.2.255\n  netmask 255.255.255.0\n  bridge_ports eth0\n  bridge_stp off \n  bridge_waitport 0\n  bridge_fd 0\n\n# iLevil IP\n\n# CAN Networks/g' stratux/image/interfaces.template
```

### If using the iFly plugin in FIX Gateway
If you are using the iFly plugin in FIX Gateway to pickup waypoints from the flight plan you need some additional configuration for the network template.<br>
The issue is iFly only sends to the IP address 192.168.1.1 so we need that address setup for the FIX gateway to get the data.
```
sed -i 's/# iLevil IP/# iLevil IP\nauto br0:0\niface br0:0 inet static\n  address 192.168.1.1\n  netmask 255.255.255.0/g' stratux/image/interfaces.template
```

### If using CAN all that to the network template too:
```
TODO Need to finish this:
sed -i 's/# CAN Networks/# CAN Networks\n\nauto can11\n  iface can11 inet manual\n  pre-up \/sbin\/ip link set can11 type can bitrate 500000 restart-ms 500\n  up \/sbin\/ifconfig can11 up\n  down \/sbin\/ifconfig can11 down\n/g' stratux/image/interfaces.template
sed -i 's/# CAN Networks/# CAN Networks\n\nauto can10\n  iface can10 inet manual\n  pre-up \/sbin\/ip link set can10 type can bitrate 250000 restart-ms 500\n  up \/sbin\/ifconfig can10 up\n  down \/sbin\/ifconfig can10 down\n/g' stratux/image/interfaces.template
```


### Create some directories and links so editing network settings in stratus GUI works
```
sudo mkdir -p /overlay/robase
sudo ln -s /etc /overlay/robase/etc
```

### Build and install
```
cd stratux
make
sudo make install
```

### Disable Fan control
I'm not using the fan control from stratux so I disabled that
```
sudo systemctl stop fancontrol.service
sudo systemctl disable fancontrol.service
```

### Disable other services that should not run automatically
```
systemctl disable dnsmasq # Only did this on so far
systemctl disable systemd-resolved.service # did not do this
systemctl disable wpa_supplicant # did this
systemctl disable systemd-timesyncd #did this
```
So far did none of the disables to see what is really needed

### Create dnsmasq config for local ethernet
You will likely want to customize this.<br>
I set a static IP address for each waydroid install on the network and for other FIX Gateway servers.

```
sudo mkdir /etc/dnsmasq.d
echo 'bind-interfaces
except-interface=lxcbr0
interface=br0
dhcp-option=br0,3,192.168.2.1
dhcp-option=br0,6,192.168.2.1
dhcp-range=interface:br0,192.168.2.128,192.168.2.254,24h
dhcp-host=00:16:3e:f9:d3:04,hawk1_android,192.168.2.20,30d
'| sudo tee -a /etc/dnsmasq.d/stratux-dnsmasq-eth0.conf >/dev/null
```


### If using waydroid
Setup waydroid to use the br0 network.
```
sudo sed -i 's/waydroid0/br0/g' /var/lib/waydroid/lxc/waydroid/config
```

## Reboot

## Configure Stratux
After rebooting open up the browser and navigate to http://127.0.0.1

### Setup Wifi
Click the settings tab on the left side.<br>
In the WiFi Settings box on the right select the mode `AP + Client`
![AP Mode](/images/ap-mode.png)

Select your wifi country<br>
Enable Network Security and set a password<br>
Enable the option Internet passthrough<br>
Click Add WiFi Client Network<br>
I added my phone's mobile hotspot and my home wifi, if you FBO has wifi might want to add that too!<br>
Click Submit WiFi settings

### Enable/disable hardware
On the hardware sections on the settings page enable/disable the hardware you are using


### Remove network manager
```
sudo apt remove network-manager -y
sudo apt autoremove -y
```
Now reboot 

#######
Need to add this to /etc/network/interfaces:
auto wlan0

Without it the wifi does not always come up

This seems to be a heat issue.
The ubuntu kernel is not regulating temp properly
Also should add the rfkill options to the cmdline.txt
do not think the auto wlan0 is needed

