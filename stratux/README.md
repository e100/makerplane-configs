## AHRS from FIX Gateway
This is a small hack to get AHRS data from Makerplane FIX Gateway into stratux. I wrote this because I already had reliable and accurate AHRS data in FIX Gateway and wanted to pass it along to stratux so it could also be used in an EFB.

## Installing
These instructions are written for Ubuntu and were only tested on 23.10

### Install dependencies
```
sudo apt install librtlsdr-dev libusb-1.0-0-dev pkg-config debhelper libjpeg-dev i2c-tools python3-smbus python3-pip python3-dev python3-pil python3-daemon screen autoconf libfftw3-bin libfftw3-dev libtool build-essential mercurial libncurses-dev golang
```

### Clone stratux repo
```

```

### Replace sensors.go
```
cp sensors.go stratux/main/
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


