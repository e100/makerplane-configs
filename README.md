# My Makerplane EFIS configurations and installation guide
This repo is my personal configuration repository for the Makerplane EFIS.
This is not intended to be a tutorial so some details may be omitted.


## Image the drive
First I imaged the boot disk using the Raspberry Pi imager with Raspberry Pi OS bookworm 64bit
![Raspberry Pi Imager](/images/rpi-imager.png)
TODO Update image
TODO Include screenshot of settings

I connected the ethernet port but you could use WiFi instead

## Initial Setup
The first thing we need to do is install the latest updates, change a few options then reboot

### Install the latest updates
Open a terminal window and run:
```
sudo apt update
sudo apt dist-upgrade -y
```
![Installing Updates](/images/apt.png)

### enable SPI, I2C, X11 and disable screen blanking
```
sudo raspi-config nonint do_blanking 1
sudo raspi-config nonint do_spi 0
sudo raspi-config nonint do_i2c 0
sudo raspi-config nonint do_wayland W1
```
NOTE: While wayland is the future its inability to reparent windows is currently and issue for pyEFIS if you would like to include a Waydroid window within it


## Enable 4k pages so Waydroid works
```
echo '# 4k pages
kernel=kernel8.img
'| sudo tee -a /boot/config.txt >/dev/null

#sudo apt purge linux-image-rpi-2712
```

Reboot


## Installing software needed
```
sudo apt update
sudo apt install -y git weston vim-nox raspi-config openssh-server i2c-tools python3-smbus python3-pip python3-pil git can-utils util-linux-extra snapd x11-utils
```

## Enable apparmor
This is optional but improves security:
```
sudo sed --follow-symlinks -i 's/quiet/apparmor=1 security=apparmor quiet/g' /boot/cmdline.txt
```

## Enable PSI
This is optional, if you plan to use Waydroid it is mandatory
```
sudo sed --follow-symlinks -i 's/quiet/psi=1 quiet/g' /boot/cmdline.txt
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
```
###Setup shutdown on power loss:
```
sudo bash pwr_ubuntu.sh
```

### Set option to allow USB Power 
```
echo '# X729 Power
usb_max_current_enable=1
'| sudo tee -a /boot/config.txt >/dev/null
```

### Setup RTC device on the x729
This is optional, you could use the RPI 5's internal RTC by adding a battery.<br>
Since the x729 already has batteries I decided to use it
echo '# X729 RTC
dtoverlay=i2c-rtc,ds1307
'| sudo tee -a /boot/config.txt >/dev/null
```

### Create udev rule to make this RTC symlinked to /dev/rtc

```
echo 'SUBSYSTEM=="rtc", KERNEL=="rtc1", SYMLINK+="rtc", OPTIONS+="link_priority=10", TAG+="systemd"
'| sudo tee -a /etc/udev/rules.d/55-i2c-rtc.rules >/dev/null

echo '[Unit]
ConditionCapability=CAP_SYS_TIME
ConditionVirtualization=!container
DefaultDependencies=no
Wants=dev-rtc.device
After=dev-rtc.device
Before=systemd-timesyncd.service ntpd.service chrony.service

[Service]
Type=oneshot
CapabilityBoundingSet=CAP_SYS_TIME
PrivateTmp=yes
ProtectSystem=full
ProtectHome=yes
DeviceAllow=/dev/rtc rw
DevicePolicy=closed
ExecStart=/usr/sbin/hwclock -f /dev/rtc --hctosys

[Install]
WantedBy=time-sync.target
'| sudo tee -a /etc/systemd/system/i2c-rtc.service >/dev/null

sudo systemctl enable  i2c-rtc.service
sudo systemctl start systemd-timesyncd.service
sudo systemctl enable systemd-timesyncd.service

```


# Not sure if this is needed on raspberry pi os or not, did not do this:
# not on ubuntu, but this is needed on RPI OS
#sudo apt-get -y remove fake-hwclock
#sudo update-rc.d -f fake-hwclock remove
#sudo systemctl disable fake-hwclock
#sudo vi /lib/udev/hwclock-set
#Comment out all except the dev= line
#reboot

## Setup waveshare CAN FD hat
```
echo '# Waveshare CAN FD HAT
dtparam=spi=on <- Needs to be before any other dtoverlay!
dtoverlay=spi1-3cs
dtoverlay=mcp251xfd,spi0-0,interrupt=25
dtoverlay=mcp251xfd,spi1-0,interrupt=24
'| sudo tee -a /boot/config.txt >/dev/null
```

NOTE: We will setup the network interfaces for CAN0 and CAN1 later when we setup Stratux

To ensure can0 and can1 do not swap their names we will apply the following udev rule:

```
echo 'ACTION=="add", SUBSYSTEM=="net", DEVPATH=="/devices/platform/soc/*/spi0.0/net/can?", NAME="can0"
ACTION=="add", SUBSYSTEM=="net", DEVPATH=="/devices/platform/soc/*/spi0.1/net/can?", NAME="can1"
ACTION=="add", SUBSYSTEM=="net", DEVPATH=="/devices/platform/soc/*/spi1.0/net/can?", NAME="can1"
'| sudo tee -a /etc/udev/rules.d/80-can.rules >/dev/null
```

Reboot


Turn on RDAC and see if it works should get output with:
candump -cae can0,0:0,#FFFFFFFF


## Pair BT keyboard/mouse app
I use an app on my phone that acts as a keyboard.
Handy to use in the airplane should you need a keyboard for some reason

## Install snapcraft
```
snap install snapcraft --classic
sudo snap install lxd
sudo /snap/bin/lxd init --auto
sudo usermod -a -G lxd ${USER}
newgrp lxd # OR reboot
```
It is easiest to just reboot at this step before continuing

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
snapcraft
snap install fixgateway_0.3_arm64.snap --dangerous
```
NOTE: as snap versions change the filename to install might change.<br>
  dangerous is needed because the snap you just made is not signed.

### Might need additional configuration
You must also read the docs/snapcraft.md for Fix and follow the directions to complete setup
If using serial ports add yourself to dialout
sudo usermod -a -G dialout ${USER}

For my setup the following commands, maybe with some slight changes will get everything working:
```
sudo usermod -a -G dialout ${USER}
sudo snap set system experimental.hotplug=true
sudo systemctl restart snapd.service
snap interface serial-port --attrs
snap connect fixgateway:serial-port snapd:ft232rusbuart

```

Granting access to the canbus:
```
snap connect fixgateway:can-bus snapd
```


### Test that the snap is working
Run `fixgateway.client` command, it should open up, type `quit` to exit

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
NOTE: Edit `~/.config/systemd/user/fixgateway.service` and change the config file to use if needed.
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
sudo apt install -y libglibutil libgbinder python3-gbinder waydroid
```
#### Install lineago OS
NOTE: Remove the -s GAPPS if you do not want google play
```
sudo waydroid init -s GAPPS
```

#### Fix apparmor TODO Not sure if this helped or not yet
https://github.com/waydroid/waydroid/issues/631
```
cd /etc/apparmor.d/
sudo ln -s lxc/lxc-waydroid .
```

#### Fix permissions errors
https://github.com/waydroid/waydroid/issues/1065
```
sudo sed --follow-symlinks -i 's/lxc.console.path/lxc.mount.entry = none acct cgroup2 rw,nosuid,nodev,noexec,relatime,nsdelegate,memory_recursiveprot 0 0\n\nlxc.console.path/g' /var/lib/waydroid/lxc/waydroid/config
```
#### Self Certify Play Store:
IF you installed the google play store you will need to self certify this installation before google Play will work.
First you need to start waydroid:
```
weston &
WAYLAND_DISPLAY=wayland-1 waydroid show-full-ui
```
Now open the waydroid shell and execute the following command, it will output an android ID:
```
sudo waydroid shell
ANDROID_RUNTIME_ROOT=/apex/com.android.runtime ANDROID_DATA=/data ANDROID_TZDATA_ROOT=/apex/com.android.tzdata ANDROID_I18N_ROOT=/apex/com.android.i18n sqlite3 /data/data/com.google.android.gsf/databases/gservices.db "select * from main where name = \"android_id\";"
```

Use the string of numbers printed by the command to register the device on your Google Account at https://www.google.com/android/uncertified


At this point you should reboot and make sure everything so far seems to be working. Then continue onto installing stratuc by reading the stratux/README.md in this repo




# Known issues
## If pyefis is killed sometimes the waydroid and weston processe are not killed. When pyefis is restarted it is not possible to get the android window working again.
 
