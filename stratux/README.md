## AHRS from FIX Gateway
This is a small hack to get AHRS data from Makerplane FIX Gateway into stratux. I wrote this because I already had reliable and accurate AHRS data in FIX Gateway and wanted to pass it along to stratux so it could also be used in an EFB.

## Installing
These instructions are written for Ubuntu and were only tested on 23.10

### Install dependencies
```
sudo apt install librtlsdr-dev libusb-1.0-0-dev pkg-config debhelper libjpeg-dev i2c-tools python3-smbus python3-pip python3-dev python3-pil python3-daemon screen autoconf libfftw3-bin libfftw3-dev libtool build-essential mercurial libncurses-dev golang ifupdown net-tools bridge-utils
```

### Clone stratux repo
```
git clone --recursive https://github.com/b3nn0/stratux.git
```

### Replace sensors.go
```
cp sensors.go stratux/main/
```

### Modify network template
```
sed -i 's/# allow-hotplug eth0 # configured by ifplugd/# Bridge for local ethernet and waydroid/g' stratux/image/interfaces.template 
sed -i 's/iface eth0 inet dhcp/iface eth0 inet manual\n\nauto br0\niface br0 inet static\n        address 192.168.2.1\n        broadcast 192.168.2.255\n        netmask 255.255.255.0\n        bridge_ports eth0\n        bridge_stp off \n        bridge_waitport 0\n        bridge_fd 0/g' stratux/image/interfaces.template
```

### Create some directories and links so editing netwokr settings in stratus GUI works
```
sudo mkdir -p /overlay/robase
sudo ln -s /etc /overlay/robase/etc
```

### Create dnsmasq config for local ethernet
```
cat << 'EOF' > /etc/dnsmasq.d/stratux-dnsmasq-eth0.conf
interface=br0
dhcp-range=interface:br0,192.168.2.128,192.168.2.254,24h
dhcp-host=00:16:3e:f9:d3:04,hawk1_android,192.168.2.20,3d

EOF
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
systemctl disable wpa_supplicant
systemctl disable systemd-timesyncd
```
