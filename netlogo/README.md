# NetLogo Simulation

## Agents

### Turtles
Turtle | Interactions
:----: | :-----------
SARS-CoV-2 | * can bind to cell's ACE2 & infect it <br/> * also can bind to hrsACE2
Angiotensin II | * can be deactivated by ACE2 <br/> * !! has to respawn / minimal amount needed
hrsACE2 <br/> (_human recombinant soluble <br/> Angiotensin-converting enzyme 2_) | **same activities as cell's ACE2** <br/> * can deactivate Angiotensin II <br/> * can bind to SARS-CoV-2 <br/> * additionally: can move


### Patches
Patch | Interactions
:---: | :-----------
Lung cells | **ACE2 funcioality** <br/> * can deactivate Angiotensin II <br/> * can be infected by SARS-CoV-2 & reproduce it


## Procedures

### SARS-CoV-2 infection of cell

1. **Binding:** (Link to patch?), center on patch, change colour
2. **Intruding:** hide SARS-CoV-2 turtle, change cell color, start cell counter
3. **Reproducing:** spawn new SARS-CoV-2 turtle randomly
4. **Death:** spawn several new SARS-CoV-2 turtles, change colour
5. **Recovery:** Repair cell, change color, active again (???)

### SARS-CoV-2 binding to hrsACE2

1. **Binding:** link SARS-CoV-2 turtle with hrsACE2 turtle  
    multiple binding needed? --> reducing binding capability to cell
2. **Despawn:** ???