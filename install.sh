#!/bin/bash
#
# Copy this script and execute it to setup fixgateway, pyEFIS and stratux
#

sudo apt update
sudo apt install -y weston vim-nox raspi-config openssh-server i2c-tools python3-smbus python3-pip python3-pil git can-utils

cd ~
git clone https://github.com/e100/makerplane-configs.git .makerplane
cd .makerplane

mkdir setup
cd setup
git clone https://github.com/e100/x729
cd x729
git checkout ubuntu

sudo bash pwr_ubuntu.sh

if ! grep -q "# X729" /boot/firmware/config.txt; then
    echo '# X729 Power
usb_max_current_enable=1

# X729 RTC
dtoverlay=i2c-rtc,ds1307
' | sudo tee -a /boot/firmware/config.txt >/dev/null
fi


if ! grep -q "# Waveshare" /boot/firmware/config.txt; then
echo '# Waveshare CAN FD HAT
dtparam=spi=on
dtoverlay=spi1-3cs
dtoverlay=mcp251xfd,spi0-0,interrupt=25
dtoverlay=mcp251xfd,spi1-0,interrupt=24
' | sudo tee -a /boot/firmware/config.txt >/dev/null
fi


# TODO Setup can interface when modifying stratux template
# The CAN interfaces are setup later when installing stratux
#
#

snap install snapcraft --classic

sudo snap install lxd
sudo lxd init --auto
sudo usermod -a -G lxd ${USER}
newgrp lxd


cd ~/.makerplane/setup
git clone https://github.com/e100/FIX-Gateway.git
cd FIX-Gateway
git checkout combined
snapacraft
snap install fixgateway_0.3_amd64.snap --dangerous

mkdir -p ~/.config/systemd/user
cp ~/.makerplane/systemd/fixgateway.service ~/.config/systemd/user/
systemctl enable --user fixgateway.service

cp ~/.makerplane/systemd/pyefis.service ~/.config/systemd/user/
systemctl enable --user pyefis.service


sudo apt install curl ca-certificates -y
curl https://repo.waydro.id | sudo bash
sudo apt install waydroid -y
sudo apt install linux-modules-extra-raspi

sudo waydroid init -s GAPPS

sudo sed -i 's/waydroid0/br0/g' /var/lib/waydroid/lxc/waydroid/config


