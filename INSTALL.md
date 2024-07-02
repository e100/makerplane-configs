
## Image the drive
First I imaged the boot disk using the Raspberry Pi imager with Raspberry Pi OS bookworm 64bit
![Raspberry Pi Imager](/images/rpi-imager.png)

I connected the ethernet port but you could use WiFi instead

## Open Chrome
Open Chrome and navigate to my profile on github: `https://github.com/e100/`<br>
Click on Repositories, then click on the repository named `makerplane-configs`<rb>
In the file list, click on INSTALL.md to pull up this page.

So you can easily return to this page after rebooting we will change some settings in Chrome.<br>
Click on the three dots on the top right then click settings.<br>
On the left click `On start-up` then select the option `Continue where you left off`

## Initial Setup
After booting the PI for the first time the first thing we need to do is install the latest updates, change a few options then reboot

### Install the latest updates
Open a terminal window and run:
```
sudo apt update
sudo apt dist-upgrade -y
```
![Installing Updates](/images/apt.png)

### Change equired settings
Disable screen blanking, we do not want the display to turn off in flight!
```
sudo raspi-config nonint do_blanking 1
```

Enable spi:
```
sudo raspi-config nonint do_spi 0
```

Enable i2c:
```
sudo raspi-config nonint do_i2c 0
```

Disable wayland and use x11:
```
sudo raspi-config nonint do_wayland W1
```
NOTE: While wayland is the future its inability to reparent windows is currently an issue for pyEFIS if you would like to include a Waydroid window within it. Hopefully in the future we can incorporate a Wayland compositor within pyEFIS.


## On the PI 5, Enable 4k pages so Waydroid works
Only perform this step if you are using a PI 5 and plan to also use Waydroid.
```
echo '# 4k pages
kernel=kernel8.img
'| sudo tee -a /boot/firmware/config.txt >/dev/null
```

## diable/remove panel notifications
This just removes the desktop notifications, we do not need to be informed of an update being avaliable while landing...
```
sudo apt remove lxplug-updater -y
```

## Optional - Enable PCIe 3.0 on Raspberry PI 5 
If you are using a PCIe SSD you can optionally enable PCIe 3.0 to increase speed.
```
echo 'dtparam=pciex1
dtparam=pciex1_gen=3
'| sudo tee -a /boot/firmware/config.txt >/dev/null
```

Now it is time to reboot.


## Installing software needed
```
sudo apt update
sudo apt install -y git weston vim-nox raspi-config openssh-server i2c-tools python3-smbus python3-pip python3-pil git can-utils util-linux-extra snapd x11-utils
```

## Optional - Enable apparmor
This is optional but improves security:
```
sudo sed --follow-symlinks -i 's/quiet/apparmor=1 security=apparmor quiet/g' /boot/firmware/cmdline.txt
```

## Optional - Enable PSI
This is optional, if you plan to use Waydroid it is mandatory
```
sudo sed --follow-symlinks -i 's/quiet/psi=1 quiet/g' /boot/firmware/cmdline.txt
```

## Clone this repo
Everything related to the installation will be located in the folder `~/makerplane`

```
cd ~
git clone https://github.com/e100/makerplane-configs.git makerplane
cd makerplane
```
![git clone](/images/git-clone.png)

## Optional - Change splash screen to Makerplane logo
First make a copy of a theme:
```
sudo cp -rp /usr/share/plymouth/themes/pix /usr/share/plymouth/themes/makerplane
sudo mv /usr/share/plymouth/themes/makerplane/pix.plymouth /usr/share/plymouth/themes/makerplane/makerplane.plymouth
sudo mv /usr/share/plymouth/themes/makerplane/pix.script /usr/share/plymouth/themes/makerplane/makerplane.script
sudo sed -i 's/pix/makerplane/g' /usr/share/plymouth/themes/makerplane/makerplane.plymouth
```
Replace the splash.png with the Makerplane logog
```
sudo cp ~/makerplane/images/Makerplane_Pi_Logo_Screen.png /usr/share/plymouth/themes/makerplane/splash.png
```

Set the theme and update initrd:
```
sudo plymouth-set-default-theme --rebuild-initrd makerplane
```

Setup wallpaper to Makerplane logo:
```
pcmanfm --set-wallpaper ~/makerplane/images/Makerplane_Pi_Logo_Screen.png
```

Auto-Hide menu bar by right clicking task bar and selecting panel settings, advanced tab, Minimize panel when not in use, set to 0 pixels
Hide desktop icons, from GUI appearance settings desktop tab uncheck three checkboxes at the bottom

## Optional - Install software for the x729 UPS board
This will setup the software for the x729, if you are not using this device you can skip any section related to it.<br>

```
cd ~/makerplane
mkdir setup
cd setup
git clone https://github.com/e100/x729
cd x729
git checkout ubuntu
```
### Setup shutdown on power loss:
Answer yes to the questions when asked, this will setup the software to gracefully shutdown when the power is disconnected allowing us to power the PI from a simple on/off switch.
```
sudo bash pwr_ubuntu.sh
```
NOTE: I have noticed that sometimes it does not shutdown when power is lost. In the cases this has happend I had use ssh to log into the PI from another computer. Need to resolve this so it will always shutdown on power loss.

### Set option to allow USB Power
When the PI is powered from the header pins it is necessary to add this configuration if you want the USB ports to provide maximum power to any connected devices. 
```
echo '# X729 Power
usb_max_current_enable=1
'| sudo tee -a /boot/firmware/config.txt >/dev/null
```

### Optional - Setup RTC device on the x729
This is optional, you could use the RPI 5's internal RTC by adding a battery.<br>
Since the x729 already has batteries I decided to use it instead of the PIs RTC.

#### Configure the RTC hardware
This will add the settings needed for the RTC hardware:
```
echo '# X729 RTC
dtoverlay=i2c-rtc,ds1307
'| sudo tee -a /boot/firmware/config.txt >/dev/null
```

#### Create udev rule to make this RTC symlinked to /dev/rtc
This is to ensure the x729 RTC is used.

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


## Optional - Setup waveshare CAN FD hat
This adds the configurations needed to enable the Waveshare CAN FD HAT.<br>
This is only needed if you are using that HAT
```
echo '# Waveshare CAN FD HAT
dtparam=spi=on <- Needs to be before any other dtoverlay!
dtoverlay=spi1-3cs
dtoverlay=mcp251xfd,spi0-0,interrupt=25
dtoverlay=mcp251xfd,spi1-0,interrupt=24
'| sudo tee -a /boot/firmware/config.txt >/dev/null
```

By default these are named can0 and can1, but sometimes they would swap places.<br>
It is not possible to rename the interfaces if the name is already taken, if can0 and can1 are swapped neither can be renamed to the other.<br>
This will rename them to can10 and can11 so they do not swap their names.<br><br>

NOTE: Select the correct section below for the PI version you have

PI4 ONLY:

```
echo 'ACTION=="add", SUBSYSTEM=="net", DEVPATH=="/devices/platform/soc/*/spi0.0/net/can?", NAME="can10"
ACTION=="add", SUBSYSTEM=="net", DEVPATH=="/devices/platform/soc/*/spi0.1/net/can?", NAME="can11"
ACTION=="add", SUBSYSTEM=="net", DEVPATH=="/devices/platform/soc/*/spi1.0/net/can?", NAME="can11"
'| sudo tee -a /etc/udev/rules.d/80-can.rules >/dev/null
```

PI5 ONLY:
```
echo 'ACTION=="add", SUBSYSTEM=="net", DEVPATH=="/devices/platform/axi/*/*.spi/spi_master/spi0/spi0.0/net/can?", NAME="can10"
ACTION=="add", SUBSYSTEM=="net", DEVPATH=="/devices/platform/axi/*/*.spi/spi_master/spi1/spi1.0/net/can?", NAME="can11"
ACTION=="add", SUBSYSTEM=="net", DEVPATH=="/devices/platform/soc/*/*.spi/spi_master/spi0/spi1.0/net/can?", NAME="can11"
'| sudo tee -a /etc/udev/rules.d/80-can.rules >/dev/null
```

Install some needed packages:
```
sudo apt install -y ifupdown net-tools bridge-utils
```

Configure /etc/network/interfaces
```
sudo apt remove -y network-manager
sudo apt autoremove -y

echo 'auto lo

iface lo inet loopback

# Bridge for local ethernet and waydroid
iface eth0 inet manual

auto br0
allow-hotplug br0
iface br0 inet dhcp
  bridge_ports eth0
  bridge_stp off
  bridge_waitport 0
  bridge_fd 0

# iLevil IP
auto br0:0
iface br0:0 inet static
  address 192.168.1.1
  netmask 255.255.255.0

# CAN Networks

auto can10
  iface can10 inet manual
  pre-up /sbin/ip link set can10 type can bitrate 250000 restart-ms 500
  up /sbin/ifconfig can10 up
  down /sbin/ifconfig can10 down
  post-up /sbin/ip link set can10 txqueuelen 1000

auto can11
  iface can11 inet manual
  pre-up /sbin/ip link set can11 type can bitrate 500000 restart-ms 500
  up /sbin/ifconfig can11 up
  down /sbin/ifconfig can11 down
  post-up /sbin/ip link set can11 txqueuelen 1000' | sudo tee -a /etc/network/interfaces >/dev/null
```

Now we should reboot

## Optional - Disable mouse in vim and preserve other settings
This is my personal preference and disables the mouse in vim without removing the other default settings.
```
echo 'source $VIMRUNTIME/defaults.vim
set mouse=' >> ~/.vimrc
```

## Optional - if the RDAC is connected you could check to see if CAN10 is working or not:
Turn on RDAC and see if it works should get output with:
```
candump -cae can10,0:0,#FFFFFFFF
```

## Optional - Pair BT keyboard/mouse app
I use an app on my phone that acts as a keyboard.
Handy to use in the airplane should you need a keyboard for some reason

## Optional - Install snapcraft
This is only needed if you want to make your own snaps for development purposes.

Install snapcraft:
```
snap install snapcraft --classic
sudo snap install lxd
sudo /snap/bin/lxd init --auto
sudo usermod -a -G lxd ${USER}
newgrp lxd
```
It is easiest to just reboot at this step before continuing

## Reboot
```
reboot
```

## Prepare for installing FIX Gateway
Enable hotplug option in snapd:
```
sudo snap set system experimental.hotplug=true
```
Enable user daemon support:
```
sudo snap set system experimental.user-daemons=true
```
Restart snapd to apply the hotplug change:
```
sudo systemctl restart snapd.service
```

## Install FIX Gateway
To install FIX Gateway use snap:
```
sudo snap install fixgateway
```

### Might need additional configuration
You must also read the docs/snapcraft.md for Fix and follow the directions to complete setup<br>

For my setup the following commands worked, maybe with some slight changes you will get everything working.
Add yourself to the dialout group:
```
sudo usermod -a -G dialout ${USER}
newgrp dialout
```

List serial ports:
```
snap interface serial-port --attrs
```
Allow fixgateway to use the serial port:
```
sudo snap connect fixgateway:serial-port snapd:ft232rusbuart
```

Allow fixgateway to use the canbus:
```
sudo snap connect fixgateway:can-bus snapd
```


### Test that the snap is working
Run `fixgateway.client` command, it should open up, type `quit` to exit:
```
fixgateway.client
```


## Install pyEFIS
Install pyefis with snap:
```
sudo snap install pyefis
```

Installing pyefis will also install the content snap faa-cifp-data, this contains the FAA CIFP data needed for the Virtual VFR feature to work.
This is all automated so nothing extra is required.



### Install waydroid
This is optional and only needed if you plan to use android applications in the EFIS.<br>
Install waydroid:

```
sudo apt install curl ca-certificates -y
curl https://repo.waydro.id | sudo bash
sudo apt install -y libglibutil libgbinder python3-gbinder waydroid
```

#### Install lineago OS
NOTE: Remove the `-s GAPPS` if you do not want google play
This wil download and install Lineage OS:

```
sudo waydroid init -s GAPPS
```

#### Fix apparmor TODO Not sure if this helped or not yet
This is related to this bug: https://github.com/waydroid/waydroid/issues/631
```
cd /etc/apparmor.d/
sudo ln -s lxc/lxc-waydroid .
```

#### Fix permissions errors
This is related to this bug: https://github.com/waydroid/waydroid/issues/1065
```
sudo sed --follow-symlinks -i 's/lxc.console.path/lxc.mount.entry = none acct cgroup2 rw,nosuid,nodev,noexec,relatime,nsdelegate,memory_recursiveprot 0 0\n\nlxc.console.path/g' /var/lib/waydroid/lxc/waydroid/config
```

#### Self Certify Play Store:
IF you installed the google play store you will need to self certify this installation before google Play will work.
First you need to start waydroid, to do that we first run weston:
```
weston &
```

Then we run the command to start android:
```
WAYLAND_DISPLAY=wayland-1 waydroid show-full-ui
```
NOTE, you might need to use this command instead:
```
WAYLAND_DISPLAY=wayland-0 waydroid show-full-ui
```

In another terminal window or tab open up the waydroid shell:
```
sudo waydroid shell
```

Once the shell is open run this command:
```
ANDROID_RUNTIME_ROOT=/apex/com.android.runtime ANDROID_DATA=/data ANDROID_TZDATA_ROOT=/apex/com.android.tzdata ANDROID_I18N_ROOT=/apex/com.android.i18n sqlite3 /data/data/com.google.android.gsf/databases/gservices.db "select * from main where name = \"android_id\";"
```

Use the string of numbers printed by the command to register the device on your Google Account navigate to [https://www.google.com/android/uncertified](https://www.google.com/android/uncertified) login with you Google Account and enter in the code that was output in the previous command.


At this point you should reboot and make sure everything so far seems to be working. Then continue onto installing stratux by reading the [stratux/README.md](stratux/README.md) in this repo<br>
NOTE: I only installed Stratux on one PI, not both. The 2nd one gets internet access through the Sttratux using the wired ethernet port.

#### waydroid service
For waydroid to start/restart when needed for pyefis we need to setup a service that monitors for the right conditions.

You might need to make this directory:
```
mkdir -p ~/.config/systemd/user/
```

Now symlink the waydroid-monitor service into that folder:
```
ln -s /snap/pyefis/current/extras/waydroid-monitor.service ~/.config/systemd/user/waydroid-monitor.service
```

Enable the waydroid monitor
```
systemctl --user enable waydroid-monitor.service
```

Start the waydroid monitor:
```
systemctl --user start waydroid-monitor.service
```

With this monitor running if you navigate to a page setup to show waydroid you will see Lineage OS boot up.


