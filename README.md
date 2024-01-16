# My Makerplane EFIS configurations and installation guide
This is currnetly a WIP
This repo is my personal configuration repository for the Makerplane EFIS and documents the installation and setup of all the components.<br>
This is not intended to be a tutorial so some details may be omitted.<br>
But hopefully, if you plan to build something similar this will be enough to get you on your way to success.

# Description
I am building a Fisher Dakota Hawk and the [Makerplane EFIS](https://github.com/makerplane/pyEfis) will be my primary flight display.<br>
The system will consist of two 13" 1920x1080 touchscreen displays, each powered by a Raspberry PI 5. Each Pi will be connected, over seral port, to a CubeOrange Flight Controller that will be used as a source for AHRS data and an auto pilot. The Auto Pilot only controls trim tabs on the Alieron, Elevator and Rudder to ensure the pilot can always override the auto pilot should it malfunction. [Stratux](https://github.com/b3nn0/stratux) will be modified to get AHRS data from the [FIX Gateway](https://github.com/makerplane/FIX-Gateway) and also serve as a source for ADBS in. An instance of Android will run on the Raspberry PIs so I can run my favorite mapping application iFLY EFB directly inside the Makerplane EFIS. A plugin in the Fix Gateway will receive NMEA data from iFLY allowing the next waypoint to be sent to the auto pilot.

# Hardware
I selected the [GeekWorm X729 UPS](https://geekworm.com/products/x729) to provide reliable power to the PIs. The UPS also makes it simple to cleanly shutdown the PIs with the flip of a switch and we do not need to worry about vlotage fluctuations such as when starting the engine. The [Waveshare 2ch CAN FD Hat](https://www.waveshare.com/2-ch-can-fd-hat.htm) will be used to connect the various components. One channel will be used for to collect engine data from the ECU while the other channel will be used to connect the MGL RDAC and other FIX Gateway components.  

# Components used:
| Quantity | Part | Description |
|----------|------|-------------|
| 2 | Raspberry PI 5 | Compute|
| 2 | 13" 1920x1080 screen | Display and input| 
| 1 | [MGL RDAC XG](https://www.michiganavionics.com/product/rdac/) | Sensor Input |
| 1 | Megasquirt ECU | ECU for the Aeromomentum AM 13|
| 2 | [Waveshare 2ch CAN FD Hat](https://www.waveshare.com/2-ch-can-fd-hat.htm)| CAN-bus input/output|
| 2 | [GeekWorm X729 UPS](https://geekworm.com/products/x729) | UPS for the PIs|
| 2 | [Pimoroni NVME Base with 500GB SSD](https://shop.pimoroni.com/products/nvme-base?variant=41219587211347)| Storage|
| ? | [adafruit RP2040 CAN BUS Feather](https://www.adafruit.com/product/5724)  | Button/Encoder inputs, indicators and relays |


# Software Installation
[Installation Process](INSTALL.md)
