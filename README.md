# My Makerplane EFIS configurations and installation guide
This repo is my personal configuration repository for the Makerplane EFIS.
This is not intended to be a tutorial so some details may be omitted.


## Image the drive
First I imaged the boot disk using the Raspberry Pi imager with Ubuntu Desktop 23.10
![Raspberry Pi Imager](/images/rpi-imager.png)

After booting up I connected to Wifi network and selected time zone
Entered username/password and selected to log in automatically
Enabled Location Services but not sure if that is of much use or not yet
In Power Settings set the screen blank option to Never, we do not want the screen to blank mid flight!

## Install the latest updates
Open a terminal window and run:
```
sudo apt update
sudo apt dist-upgrade -y
```
![Installing Updates](/images/apt.png)

While not necessary I rebooted at this point.
A bug in the kernel caused the fan to run full speed, the fist update fixes this so I don't get annoyed by the fan.

## Installing software needed
```
sudo apt update
sudo apt install git weston vim-nox raspi-config openssh-server i2c-tools python3-smbus python3-pip python3-pil git can-utils
```

## Clone this repo

```
cd ~
git clone https://github.com/e100/makerplane-configs.git .makerplane
cd .makerplane
```
![git clone](/images/git-clone.png)

## Install software for the x729 UPS board

NOTES: I2C and SPI are enabled by default in Ubuntu image so no need to enable them.
If using another image you might need to enable those options using `sudo raspi-config`

```
cd ~/.makerplane
mkdir setup
cd setup
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


## Pair BT keyboard/mouse app
I use an app on my phone that acts as a keyboard.
Handy to use in the airplane should you need a keyboard for some reason

## Install snapcraft
```
snap install snapcraft --classic
sudo snap install lxd
sudo lxd init --auto
sudo usermod -a -G lxd ${USER}
newgrp lxd # OR reboot
```

## Install FIX Gateway
I install fix gateway by making a snap. The main advantage is versioning. If some day you update and the new snap is broken, just switch back to the pervious version. Hopefully some day we will get our snaps into the snap store making installing and updating even easier.

```
cd ~/.makerplane/setup
git clone https://github.com/e100/FIX-Gateway.git
cd FIX-Gateway
```
### Currently:
Once everything is merged into the makerplan repo we will use their repo not my fork
```
git checkout combined
```
### Build the snap and install it
```
snapacraft
snap install fixgateway_0.3_arm64.snap --dangerous
```
NOTE: as snap versions change the filename to install might change.<br>
  dangerous is needed because the snap you just made is not signed.

### Might need additional configuration
You must also read the docs/snapcraft.md for Fix and follow the directions to complete setup
If using serial ports add yourself to dialout
sudo usermod -a -G dialout ${USER}

### Clone this repo again
The FIX Gateway snap runs confined and cannot access files in ~/.makerplane<br>
So we also place the config files in a folder that the confined snap does have access to.

```
mkdir ~/snap/fixgateway/common
cd ~/snap/fixgateway/common
git clone https://github.com/e100/makerplane-configs.git .makerplane
```

### Install systemd unit file to auto start FIX Gateway
```
cd ~/.makerplane/
mkdir -p ~/.config/systemd/user
cp systemd/fixgateway.service ~/.config/systemd/user/
```
NOTE: Edit `~/.config/systemd/user/user/fixgateway.service` and change the config file to use if needed.
![FIX Gateway config](/images/fix-config.png)

### Configure autostart
This command will setup the FIX Gateway service to start automatically after reboot. It will also automatically be restarted should it crash for any reason.

```
systemctl enable --user fixgateway.service
```


## Install pyEFIS
```
cd ~/.makerplane/setup
git clone https://github.com/e100/pyEfis.git
cd pyEfis
```
### Build and install:
NOTE: In the future we will use makerplane repo and specific tag once my changes are merged
```
git checkout improve_snap
snapcraft
snap install pyefis_0.1_arm64.snap --dangerous --classic
```
### Install the systemd unit file and edit it
```
cd ~/.makerplane/
cp systemd/pyefis.service ~/.config/systemd/user/
```
When copying the systemd unit file also edit the exec line and set the config file to the left or right as needed
ExecStart=/snap/bin/pyefis --config-file /home/eblevins/.makerplane/pyefis/config/left.yaml

### Configure autostart
```
systemctl enable --user pyefis.service
```

### Download the data for Virtual VFR and index it
NOTE: This is optional and only needed if you are using the VirtualVFR instrument<br>
This data should be updated periodically

#### Create directory for the CIFP data
```
mkdir ~/.makerplane/pyefis/CIFP/
cd ~/.makerplane/pyefis/CIFP/
```

#### Download the CIFP Data
Visit https://www.faa.gov/air_traffic/flight_info/aeronav/digital_products/cifp/download/ and copyt the link to the latest data.

Download the latest data using the link you copied and unzip it
```
wget https://aeronav.faa.gov/Upload_313-d/cifp/CIFP_231228.zip
unzip CIFP_231228.zip
```
Create the index:
```
pyefis.makecifpindex FAACIFP18
```

When updating in the future just delete the CIFP directory and start over at the beginning of this section


### Install waydroid
This is optional and only needed if you plan to use android applications in the EFIS.

```
sudo apt install curl ca-certificates -y
curl https://repo.waydro.id | sudo bash
sudo apt install waydroid -y
sudo apt install linux-modules-extra-raspi -y
```
#### Install lineago OS
NOTE: Remove the -s GAPPS if you do not want google play
```
sudo waydroid init -s GAPPS
```
#### Self Certify Play Store:
IF you installed the google play store you will need to self certify this installation before google Play will work.
First you need to start waydroid:
```
waydroid show-full-ui
```
Now open the waydroid shell and execute the following command, it will output an android ID:
```
sudo waydroid shell
ANDROID_RUNTIME_ROOT=/apex/com.android.runtime ANDROID_DATA=/data ANDROID_TZDATA_ROOT=/apex/com.android.tzdata ANDROID_I18N_ROOT=/apex/com.android.i18n sqlite3 /data/data/com.google.android.gsf/databases/gservices.db "select * from main where name = \"android_id\";"
```

Use the string of numbers printed by the command to register the device on your Google Account at https://www.google.com/android/uncertified


At this point you should reboot and make sure everything so far seems to be working. Then continue onto installing stratuc by reading the stratux/README.md in this repo


