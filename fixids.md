# List of buttons and their function


## Touchscreen buttons
These are the buttons that are used as the fixid for on-screen buttons. In most cases these do not need sent to the gateway.<br>
These could be used as physical button inputs. This would allow triggering the touchscreen button actions from a physical buttons over the CAN bus.

### The {id} reference
A new featuer in pyEFIS allows you to set a nodeID: value inside the main configurtion file in the main section. This shouold be a single digit number. When you have multiple pyEFIS running and want to control a touchscreen button from a physical button, the fixids used on the buttons needs to be unique for each pyEFIS.<br>
To make this work you first need to edit the database.yaml file for the FIX gateway to create the variables, this configuration would produce a total of 40 buttons, 20 for each of two nodes:
```
variables:
  n: 2  # Nodes
  s: 20 # Touchscreen buttons

- key: TSBTNns
  description: Generic Button %b
  type: bool
  tol: 0
```

Within your button configuration file place `{id}` where the lowercase `n` for nodes is located in the dbkey<br>
For example if I put `TSBTN{id}15` as the dbkey for a particular button, on node 1 the dbkey would be `TSBTN115` and node 2 would be `TSBTN215`<br>
This makes it possible to use the same button configuration on both screens but still actuate them individually by updating theit unique dbkeys.

### TSBTN{id}1, TSBTN{id}2
TSBTN{id}1/2 are the fixids assigned to the BARO down and up buttons. Does not need sent to other gateways

### TSBTN{id}3, TSBTN{id}4 and TSBTN{id}5
TSBTN{id}3/4/5 are used for TRIMP up, TRIMP center and TRIMP down
These need to be output by pyEFIS

### TSBTN{id}6, TSBTN{id}7 and TSBTN{id}8
TSBTN{id}6/7/8 are used for TRIMR left, TRIMR center and TRIMR right
These need to be output by pyEFIS

### TSBTN{id}9, TSBTN{id}10 and TSBTN{id}11
TSBTN{id}9/10/11 are used for TRIMY left, TRIMY center and TRIMY right
These need to be output by pyEFIS

### TSBTN{id}12
TSBTN{id}12 is used by buttons/screen-ems-pfd.yaml

### TSBTN{id}13
TSBTN{id}13 is used by buttons/screen-map-pfd.yaml

### TSBTN{id}14
TSBTN{id}13 is used by buttons/screen-radio-pfd.yaml

### TSBTN{id}15
TSBTN{id}14 is used by buttons/units.yaml

### TSBTN{id}16
TSBTN{id}15 is used by buttons/leader.yaml
It is only used as an indicator

### TSBTN{id}17
TSBTN{id}17 is used by buttons/mgl/v16/swap-active-standby.yaml
It is used to swap the active and standby frequencies

### TSBTN{id}18
buttons/screen-sixpack-pfd.yaml

### TSBTN{id}19 
buttons/screen-android-pfd.yaml

### TSBTN{id}20
pyefis/config/buttons/screen-ems2-pfd.yaml

### TSBTN{id}21
pyefis/config/buttons/mgl/v16/active-tx-status.yaml

### TSBTN{id}22
pyefis/config/buttons/mgl/v16/active-rx-status.yaml

### TSBTN{id}23
pyefis/config/buttons/mgl/v16/standby-rx-status.yaml

## Physical Buttons
### BTN1 of ENC1
BTN1 resets BARO to 29.92

### BTN2 of ENC2
BTN2 sets the pitch trim to center

### BTN3 of ENC3
BTN2 sets the roll trim to center

### BTN4 of ENC4
BTN2 sets the yaw trim to center

## Encoders
### ENC1
ENC1 is received on CAN with id 0x300 position 1
ENC1 is used to adjust barometric pressure calculated by Fix Gateway
Its button, BTN1, is used to reset to 29.92

### ENC2
ENC2 is received in CAN with id 0x300 position 2
ENC2 is used to adjust TRIMP, the pitch trim, its button, BTN2, is used to center the trim.
TRIMP value is calculated in Fix Gateway
TRIMP is sent and received on CAN with id 0x312

### ENC3
ENC3 is received on CAN with id 0x301 position 1
ENC3 is used to adjust TRIMR, the roll trim, its button, BTN3, is used to center the trim.
TRIMR value is calculated in Fix Gateway
TRIMR is sent and received on CAN with id 0x313

### ENC4
ENC4 is received on CAN with id 0x301 position 2
ENC4 is used to adjust TRIMY, the yaw trim, its button, BTN4, is used to center the trim.
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

