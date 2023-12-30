### My Makerplane EFIS configurations and installation guide
This repo is my personal configuration repository for the Makerplane EFIS.
This is not intended to be a tutorial so some details may be omitted.


### Image the drive
First I imaged the boot disk using the Raspberry Pi imager with Ubuntu Desktop 23.10

After booting up I connected to Wifi network and selected time zone
Entered username/password and selected to log in automatically
In Power Settings set the screen blank option to Never, we do not want the screen to blank mid flight!

### Login and clone this repo
git clone https://github.com/e100/makerplane-configs.git .makerplane
cd .makerplane

### Installing software needed
```
sudo apt update
sudo apt install weston vim-nox raspi-config openssh-server i2c-tools python3-smbus python3-pip python3-pil git can-utils
```

NOTES: I2C and SPI are enabled by default in Ubuntu image so no need to enable them.
If using another image you might need to enable those options using `sudo raspi-config`


mkdir setup
cd setup


### Install software for the x729 UPS board
git clone https://github.com/e100/x729
cd x729
git checkout ubuntu

#Setup shutdown on power loss:
sudo bash pwr_ubuntu.sh


# Setup RTC
edit /boot/firmware/config.txt

add:
# X729 Power
usb_max_current_enable=1

# X729 RTC
dtoverlay=i2c-rtc,ds1307


# no on ubuntu"
#sudo apt-get -y remove fake-hwclock
#sudo update-rc.d -f fake-hwclock remove
#sudo systemctl disable fake-hwclock
#sudo vi /lib/udev/hwclock-set
#Comment out all except the dev= line
#reboot

# Setup waveshare CAN FD hat
edit /boot/firmware/config.txt adding:
# Waveshare CAN FD HAT
dtparam=spi=on
dtoverlay=spi1-3cs
dtoverlay=mcp251xfd,spi0-0,interrupt=25
dtoverlay=mcp251xfd,spi1-0,interrupt=24

rebooted

create /etc/systemd/network/80-can0.network with:
[Match]
Name=can0

[CAN]
BitRate=250K
RestartSec=100ms

# Enable and start
sudo systemctl enable systemd-networkd
sudo systemctl start systemd-networkd

Turn on RDAC and see if it works should get output with:
candump -cae can0,0:0,#FFFFFFFF


# Pair BT keyboard/mouse app

# Install snapcraft
snap install snapcraft --classic

sudo snap install lxd
sudo lxd init --auto
sudo usermod -a -G lxd ${USER}
newgrp lxd # OR reboot


cd ~/setup
git clone https://github.com/e100/FIX-Gateway.git
cd FIX-Gateway
# Currently:
git checkout combined
snapacraft
snap install fixgateway_0.3_amd64.snap --dangerous

Might need to try running the snap one time before the next step:
cd ~/snap/fixgateway/common
git clone https://github.com/e100/makerplane-configs.git .makerplane

The fixgateway snap runs in confined mode, it does not have access to the normal home directory.
So I also clone this repo into the location where the confined snap can access the home directory.

You must also read the docs/snapcraft.md for Fix and follow the directions to complete setup
If using serial ports add yourself to dialout
sudo usermod -a -G dialout ${USER}

mkdir -p ~/.config/systemd/user
cp contrib/fixgateway.service  TODO Need to add this into the FIX repo


cd ..
git clone https://github.com/e100/pyEfis.git
cd FIX-Gateway
# Currently:
git checkout improve_snap
snapcraft
snap install pyefis_0.1_arm64.snap --dangerous --classic

When copying the systemd unit file also edit the exec line and set the config file to the left or right as needed
ExecStart=/snap/bin/pyefis --config-file /home/eblevins/.makerplane/pyefis/config/left.yaml



### Install waydroid
sudo apt install curl ca-certificates -y
curl https://repo.waydro.id | sudo bash
sudo apt install waydroid -y
sudo apt install linux-modules-extra-raspi

# Remove the -s GAPPS if you do not want google play
sudo waydroid init -s GAPPS

Self Certify Play Store:
sudo waydroid shell
ANDROID_RUNTIME_ROOT=/apex/com.android.runtime ANDROID_DATA=/data ANDROID_TZDATA_ROOT=/apex/com.android.tzdata ANDROID_I18N_ROOT=/apex/com.android.i18n sqlite3 /data/data/com.google.android.gsf/databases/gservices.db "select * from main where name = \"android_id\";"

Use the string of numbers printed by the command to register the device on your Google Account at https://www.google.com/android/uncertified


Move waydroid to direct network connection.
# Netwokr Bridge:
vi /etc/systemd/network/25-br0.netdev
[NetDev]
Name=br0
Kind=bridge

vi /etc/systemd/network/25-br0-en.network
[Match]
Name=eth0

[Network]
Bridge=br0

vi /etc/systemd/network/25-br0.network
[Match]
Name=br0

[Network]
DHCP=yes


# Edit waydroid network
sudo vi /var/lib/waydroid/lxc/waydroid/config
Change:
lxc.net.0.link = waydroid0
TO
lxc.net.0.link = br0



# Download the data for virtual VFR and index it
```
mkdir ~/.makerplane/pyefis/CIFP/
cd ~/.makerplane/pyefis/CIFP/
```

Visit https://www.faa.gov/air_traffic/flight_info/aeronav/digital_products/cifp/download/

Download the latest data:
```
wget https://aeronav.faa.gov/Upload_313-d/cifp/CIFP_231228.zip
unzip CIFP_231228.zip

```
