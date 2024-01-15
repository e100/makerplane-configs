# List of buttons and their function


## Touchscreen buttons
These are the buttons that are used as the fixid for on-screen buttons. In most cases these do not need sent to the gateway.
These could be used as physical button inputs. This would allow triggering the touchscreen button actions from a physical button.

### TSBTN1, TSBTN2
TSBTN1/2 are the fixids assigned to the BARO down and up buttons. Does not need sent to other gateways

### TSBTN3, TSBTN4 and TSBTN5
TSBTN3/4/5 are used for TRIMP up, TRIMP center and TRIMP down
These need to be output by pyEFIS

### TSBTN6, TSBTN7 and TSBTN8
TSBTN6/7/8 are used for TRIMR left, TRIMR center and TRIMR right
These need to be output by pyEFIS

### TSBTN9, TSBTN10 and TSBTN11
TSBTN9/10/11 are used for TRIMY left, TRIMY center and TRIMY right
These need to be output by pyEFIS

### TSBTN12
TSBTN12 is used by buttons/screen-ems-pfd.yaml

### TSBTN13
TSBTN13 is used by buttons/screen-map-pfd.yaml

### TSBTN14
TSBTN14 is used by buttons/units.yaml
## Physical Buttons
### BTN1 of ENC1
BTN1 resets BARO to 29.92, currently do not have a function it implement this

### TSBTN4 of ENC2
TSBTN4 sets the pitch trim to center
NOTE: Would like to implement function in fixgateway for this instead of using a touchscreen button



## Encoders
### ENC1
ENC1 is received on CAN with id 0x300 position 1
ENC1 is used to adjust barometric pressure calculated by Fix Gateway

### ENC2
ENC2 is received in CAN with id 0x300 position 2
ENC2 is used to adjust TRIMP, the pitch trim, its button, TSBTN4, is used to center the trim.
TRIMP value is calculated in Fix Gateway
TRIMP is sent and received on CAN with id 0x312

### ENC3
ENC3 is received on CAN with id 0x301 position 1
ENC3 is used to adjust TRIMR, the roll trim, its button, TSBTN7, is used to center the trim.
TRIMR value is calculated in Fix Gateway
TRIMR is sent and received on CAN with id 0x313

### ENC4
ENC4 is received on CAN with id 0x301 position 2
ENC4 is used to adjust TRIMY, the yaw trim, its button, TSBTN10, is used to center the trim.
TRIMY value is calculated in Fix Gateway
TRIMY is sent and received on CAN with id 0x314


## Auto Pilot 
These are the buttons/fixids are used by the auto pilot
### APREQ
APREQ can be set to request one of three auto pilot modes, TRIM, GUIDED and CRUISE.<br>
This must be output from pyEFIS to the Fix Gateway<br>
CRUISE mode is Heading Hold<br>
GUIDED mode is Flight Plan<br>
TRIM mode allows manual control of the TRIM tabs<br>

### BTNHH
BTNHH is the button to activate Heading Hold mode<br>
This must be output from pyEFIS to the Fix Gateway<br>

### BTNFP
BTNFP is the button to activate Flight Plan mode of the auto pilot<br>
This must be output from pyEFIS to the Fix Gateway

### APADJ
APDJ is used to adjust altitude or heading while the auto pilot is enaged.<br>
This must be output from pyefis to the Fix Gateway<br>
When in Heading Hold mode and APADJ is on, you can use the TRIM Pitch and Yaw controls to change altitude and heading.<br>
When in Flight Plan mode and APADJ is on, you can use the TRIM Pitch controls to adjust altitude.<br>
In either mode, once you reach the desired altitude or heading you can senter the trims or just press APADJ to return the auto pilot to normal.

old:
-  BARO: OnChange
-  BTN16: OnChange
-  BTN1: OnChange
-  BTN2: OnChange
-  BTN3: OnChange
-  BTN4: OnChange
-  BTN5: OnChange
-  BTN6: OnChange
-  BTN8: OnChange
-  BTN9: OnChange
-  ACID: OnChange  
-  BTNAP: OnChange
-  BTNHH: OnChange
-  BTNFP: OnChange
-  APREQ: OnChange
-  APADJ: OnChange
-  TRIMR: OnChange
-  TRIMP: OnChange
-  TRIMY: OnChange

