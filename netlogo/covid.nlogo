; Helpfull vocabulary:
; "Agents" are objects in NetLogo, like viruses.
; Field is divided into squares & those squares are called "Patches".

; To go 1 patch forward, you can use "forward 1".
; You can also use "right", "left" or "random" for moving stuff.
; ------------------------------------------------------------------------------
;;;;;;;;;;;;;;;
; DECLARATIONS
;;;;;;;;;;;;;;;

; "breed" can only be used at the beginning of code.
; It's helpfull to define for all species a breed, 'cause of different behaviour etc.
; & you can change all "viruses" for example at the same time,
; & you can spawn new "virus"-objects by writing "sars a-sars <PutNumberHere>".
breed [sars a-sars]  ; SARS-CoV-2
breed [ang2 an-ang2] ; Angiotensin II
breed [ace2 an-ace2] ; hrsACE2 (enzyme)

globals [

]

turtles-own [
  partner      ;; holds the turtle this turtle is complexed with,
               ;; or nobody if not complexed
  bound?  ;; states if SARS-CoV-2 or Ang2 is bound to an enzyme
]

ang2-own [
  deactivated?
]

patches-own [
  ppartner
  infected? ; when cell is infected with SARS-CoV-2, reproducing virus
  remaining-lifetime
  dead?     ; self-expainatory
]

; ------------------------------------------------------------------------------
;;;;;;;;;;;;;;;;;;;
; SETUP PROCEDURES
;;;;;;;;;;;;;;;;;;;

; Defines what happens when "setup"-button is clicked:
to setup
  ; "clear-all" deletes all agents etc. from past iterations, to have a clean next start:
  clear-all
  ; "reset-ticks" is setting up the NetLogo-time to "0":
  reset-ticks

  ; Other "setup-" named methods are called here:
  setup-cells
  setup-turtles
end

to setup-cells
  ; You have to call "ask patches", when you want to do things with patches.
  ; Here you change "all" patches (square-field) at the same time:
  ask patches [
    ; "set" is everywhere setting up or changing:
    set ppartner nobody
    set infected? false
    set remaining-lifetime infection-time  ;; TODO: add random?
    set dead? false
    precolor
  ]
end

to setup-turtles
  ;; SARS-CoV-2
  set-default-shape sars "virus"
  add sars initial-sars-infection
  ;; Angiotensin II
  set-default-shape ang2 "triangle"
  add ang2 initial-ang2-concentration
  ;; ACE2
  set-default-shape ace2 "x"
  add ace2 hrsace2-concentration
end

;; observer procedure to add molecules to reaction
to add [kind amount]
  create-turtles amount [
    set breed kind
    setxy random-xcor random-ycor
    set size 0.8
    set partner nobody
    set bound? false
    if breed = ang2 [ set deactivated? false ]
    recolor
  ]
end

; ------------------------------------------------------------------------------
;;;;;;;;;;;;;;;;
; GO PROCEDURES
;;;;;;;;;;;;;;;;

; When "go"-button is clicked:
to go
  add-ang2
  ask turtles [ move ]               ;; random movement
  ask ace2 [ form-ace2-complex ]     ;; free enzymes have higher priority than
  ask patches [ form-cell-complex ]  ;; cells's due to free movement
  ask ang2 [ react-forward ]         ;; enzyme catalysation
  ask sars [ infect ]                ;; infect cells
  ; leave out dissociate?
  ; ask enzymes [ dissociate ]
  ask patches [ reproduce ]          ;; let cells produce new SARS
  ask patches [ repair ]             ;; let cells come back to life
  tick
end

; change color of turtles based on current status
to recolor
  ifelse breed = sars [
    ifelse bound?
      [ set color red - 2 ]
      [ set color red ]
  ] [ ifelse breed = ang2 [
    ifelse bound?
      [ set color yellow - 2 ]
      [ set color yellow ]
  ] [ if breed = ace2
    [ set color blue ]
  ] ]
end

; change color of cells based on current status
to precolor
  ifelse infected? = false [
    set pcolor pink - 1.5
  ] [ ifelse dead? = false [
    set pcolor remaining-lifetime * (3.5 / infection-time) ; darkens cell, grey to black
  ] [ ; dead? = true
    set pcolor black
  ] ]
end

;; adds Angiotensin 2 regularly until max is reached
to add-ang2
  if count ang2 < max-ang2-concentration [
      add ang2 add-every-tick ; TODO: needs some function
  ]
end

;; button method
to add-hrsACE2
  add ace2 hrsace2-concentration
end

; ------------------------------------------------------------------------------
;;;;;;;;;;;;;;;;;;;;
; TURTLE PROCEDURES
;;;;;;;;;;;;;;;;;;;;

;; random movement
to move
  if bound? = false [
    fd 0.75 + random-float 0.5
    rt random-float 360
  ]
end

to form-ace2-complex
  if partner != nobody
    [ stop ]  ;; can't bind to multiple molecules in this simulation
  set partner one-of other turtles-here with [bound? = false]  ;; search for reaction partner
  if partner = nobody
    [ stop ]  ;; stop when no reaction partners available on this patch
  if [partner] of partner != nobody
    [ set partner nobody stop ]  ;; just in case two cells grab the same partner
  ifelse ( [breed] of partner = ang2 and random-float 100 < k-binding-ang2 )    ;; chance of binding
      or ( [breed] of partner = sars and random-float 100 < k-binding-sars ) [  ;; chance of binding
    ifelse [breed] of partner = sars [
      ;; if complexed with SARS-CoV-2 remove turtles
      ask partner [ die ]
      die
    ] [ ;; else bind with Angiotensin II
      ask partner [
        set partner myself
        set bound? true
        recolor
      ]
      setxy [xcor] of partner [ycor] of partner  ;; center enzyme on substrate
      create-link-to partner [                   ;; & link for combined movement
        tie
        hide-link
      ]
    ]
  ]
  [ set partner nobody ]  ;; compex-forming unsucessful
end

; SARS-CoV-2 procedure
to infect
  if is-patch? partner [  ;; hrsACE2 can't get infected
    if (random-float 100 < k-cell-infection) [  ;; chance to intrude cell
      ask partner [
        set infected? true
        set ppartner nobody
      ]
    ; "die" removes agents from simulation:
    die
 ] ]
end

;; substrate procedure that controls the rate at which complexed substrates
;; are converted into products and released from the complex
to react-forward
  if (partner != nobody) and (random-float 100 < k-react-ang2) [
    ;set deactivated? true
    ;set bound? false
    ifelse is-patch? partner
      [ ask partner [set ppartner nobody] ]  ;; if bound to cell
    [
      ask partner [set partner nobody]
      ask my-links [ die ]
    ]   ;; if bound to hrsACE2
    ;set partner nobody
    ;recolor
    die
  ]
end

;; enzyme procedure that controls the rate at which complexed turtles break apart
;to dissociate
;  if partner != nobody
;    [ if ([breed] of partner = substrates) and (random-float 1000 < Kd)
;      [ ask partner [ set partner nobody ]
;        let old-partner partner
;        set partner nobody
;        setshape
;        ask old-partner [ setshape ] ] ]
;end

; ------------------------------------------------------------------------------
;;;;;;;;;;;;;;;;;;;
; PATCH PROCEDURES
;;;;;;;;;;;;;;;;;;;

to form-cell-complex
  if infected? = false [  ;; only healty cells have enzymatic

    if ppartner != nobody
      [ stop ]  ;; can't bind to multiple molecules in this simulation
    set ppartner one-of turtles-here with [bound? = false]  ;; search for reaction partner
    if ppartner = nobody
      [ stop ]  ;; stop when no reaction partners available on this patch
    if [partner] of ppartner != nobody
      [ set ppartner nobody stop ]  ;; just in case two cells grab the same partner
    ifelse ( [breed] of ppartner = ang2 and random-float 100 < k-binding-ang2 )    ;; chance of binding
        or ( [breed] of ppartner = sars and random-float 100 < k-binding-sars ) [  ;; chance of binding
      ask ppartner [
        set partner myself
        set bound? true
        recolor
    ] ]
    [ set ppartner nobody ]  ;; compex-forming unsucessful

  ]
end

; lets cells reproduce the virus, release on death
to reproduce
  if dead? = false and infected? [
    ; reduce lifetime
    ifelse remaining-lifetime > 0 [
      set remaining-lifetime remaining-lifetime - 1   ;; reduce lifetime
      ; random virus ejecting
      if remaining-lifetime < (infection-time / 2) [  ;; only possible on half remaining liftime
        if random-float 100 < 2 [  ; 2% chance
          eject-sars 1
      ] ]
    ] [ ; remaining lifetime = 0 --> death
      set dead? true
      set remaining-lifetime (remaining-lifetime - cell-repair-time)
      eject-sars reproduction-factor
    ]
    precolor
  ]
end

;; spawns given amount SARS-CoV-2 on executing patch
to eject-sars [ amount ]
  sprout-sars amount [
    set partner nobody
    set bound? false
    set size 0.8
    recolor
  ]
end

to repair
  if dead? = true [
    ifelse remaining-lifetime < 0 [
      set remaining-lifetime (remaining-lifetime + 1)
    ] [  ;; remianing-lifetime = 0 --> back alive
      set dead? false
      set infected? false
      set remaining-lifetime infection-time
      precolor
    ]
  ]
end

; ------------------------------------------------------------------------------

; Copyright 2001 Uri Wilensky.
; See Info tab for full copyright and license.
@#$#@#$#@
GRAPHICS-WINDOW
11
10
819
519
-1
-1
20.0
1
10
1
1
1
0
1
1
1
0
39
0
24
1
1
1
ticks
30.0

BUTTON
20
556
111
589
setup
setup
NIL
1
T
OBSERVER
NIL
S
NIL
NIL
1

BUTTON
125
557
216
590
go
go
T
1
T
OBSERVER
NIL
G
NIL
NIL
0

SLIDER
21
614
263
647
initial-ang2-concentration
initial-ang2-concentration
50
250
250.0
10
1
Angiotensin 2
HORIZONTAL

SLIDER
294
551
534
584
initial-sars-infection
initial-sars-infection
0
20
2.0
1
1
NIL
HORIZONTAL

SLIDER
563
554
801
587
hrsace2-concentration
hrsace2-concentration
0
100
0.0
1
1
NIL
HORIZONTAL

SLIDER
21
650
263
683
add-every-tick
add-every-tick
0
100
56.0
2
1
Angiotensin 2
HORIZONTAL

TEXTBOX
23
686
269
713
set this value so Ang2 concentration stays stable\nw/o SARS & hrsACE2
11
0.0
0

TEXTBOX
11
596
275
614
╒═ Angiotensin 2 ═════════════════════╕
11
0.0
1

TEXTBOX
285
535
549
553
╒═ SARS-CoV-2 ═════════════════════╕
11
0.0
1

TEXTBOX
557
535
815
553
╒═ hrsACE2 ═══════════════════════╕
11
0.0
1

TEXTBOX
12
537
249
555
╒═ CONTROLS ═════════════════╕\n
11
0.0
1

BUTTON
698
590
801
623
add hrsACE2
add-hrsACE2
NIL
1
T
OBSERVER
NIL
A
NIL
NIL
0

SLIDER
295
587
534
620
infection-time
infection-time
1
50
36.0
1
1
ticks
HORIZONTAL

SLIDER
295
622
435
655
reproduction-factor
reproduction-factor
1
5
2.0
1
1
x
HORIZONTAL

SLIDER
22
721
263
754
max-ang2-concentration
max-ang2-concentration
60
500
500.0
20
1
Angiotensin 2
HORIZONTAL

PLOT
834
526
1370
811
Cell Monitor
time
cells
0.0
10.0
0.0
1000.0
true
true
"" ""
PENS
"healthy" 1.0 0 -10899396 true "" "plot count patches with [ infected? = false ]"
"infected" 1.0 0 -13345367 true "" "plot count patches with [ infected? = true and dead? = false ]"
"dead" 1.0 0 -2674135 true "" "plot count patches with [ dead? = true ]"

SLIDER
362
706
534
739
k-binding-ang2
k-binding-ang2
0
100
40.0
5
1
%
HORIZONTAL

SLIDER
361
742
533
775
k-binding-sars
k-binding-sars
0
100
80.0
5
1
%
HORIZONTAL

SLIDER
540
706
712
739
k-react-ang2
k-react-ang2
0
100
30.0
5
1
%
HORIZONTAL

PLOT
835
10
1371
520
Concentrations
time
C
0.0
50.0
0.0
500.0
true
true
"" ""
PENS
"Angiotensin 2" 1.0 0 -10899396 true "" "plot count ang2"
"SARS-CoV-2" 1.0 0 -2674135 true "" "plot count sars with [ bound? = false ]"
"hrsACE2" 1.0 0 -13345367 true "" "plot count ace2"
"initial Ang2" 1.0 2 -13210332 false "" "plot initial-ang2-concentration"
"max Ang2" 1.0 2 -8053223 false "" "plot max-ang2-concentration"

MONITOR
1376
574
1450
619
% infected
count patches with [ infected? = true and dead? = false ] / 10
3
1
11

MONITOR
1375
526
1451
571
% healthy
count patches with [ infected? = false ] / 10
3
1
11

MONITOR
1377
621
1450
666
% dead
count patches with [ dead? = true ] / 10
3
1
11

SLIDER
541
743
713
776
k-cell-infection
k-cell-infection
0
100
50.0
1
1
%
HORIZONTAL

SLIDER
362
778
534
811
cell-repair-time
cell-repair-time
0
100
10.0
1
1
Ticks
HORIZONTAL

@#$#@#$#@
## WHAT IS IT?

This model demonstrates the kinetics of single-substrate enzyme-catalysis. The interactions between enzymes and substrates are often difficult to understand and the model allows users to visualize the complex reaction.

The standard equation for this reaction is shown below.

```text
                  Kc          Kr
        E + S <=======> E-S ------> E + P
                  Kd
```

Here E represents Enzyme, S Substrate, E-S Enzyme-Substrate complex, and P product.  The rate constants are Kc for complex formation, Kd for complex dissociation, Kr for catalysis.  The first step in catalysis is the formation of the E-S complex.  This can consist of either covalent or non-covalent bonding.  The rates of complex formation and dissociation are very fast because they are determined by collision and separation of the molecules.  The next step is for the enzyme to catalyze the conversion of substrate to product.  This rate is much slower because the energy required for catalysis is much higher than that required for collision or separation.

The model demonstrates several important properties of enzyme kinetics.  Enzyme catalysis is often assumed to be controlled by the rate of complex formation and dissociation, because it occurs much faster than the rate of catalysis. Thus, the reaction becomes dependent on the ratio of Kc / Kd.  The efficiency of catalysis can be studied by observing catalytic behavior at different substrate concentrations.

By measuring the rate of complex formation at different substrate concentrations, a Michaelis-Menten Curve can be plotted.  Analysis of the plot provides biochemists with the maximum rate (Vmax) at which the reaction can proceed. As can be seen from the model, this plot is linear at low levels of substrate, and non-linear at higher levels of substrate.  By examining the model, the reasons for this relationship can be seen easily.

Enzyme catalysis can also be controlled using inhibitors. Inhibitors are molecules that are structurally similar to substrate molecules that can complex with the enzyme and interfere with the E-S complex formation.  Subsequently, the shape of the Michaelis-Menten Curve will be altered. The model demonstrates the effects of inhibitors on catalysis.

## HOW TO USE IT

Choose the values of Kc, Kd, and Kr with appropriate sliders:
- Kc controls the rate at which substrates (green) and enzymes (red) stick together so that catalysis can occur
- Kd controls the rate at which they come unstuck
- Kr controls the rate of the forward reaction by which an enzyme (red) converts a substrate (green) to a product (blue)

Having chosen appropriate values of the constants, press SETUP to clear the world and create a constant initial number of enzyme (red) molecules. Play with several different values to observe variable effects on complex formation and catalysis.

Press GO to start the simulation.  A constant amount of enzyme (red) will be generated.  The concentrations of substrate, complex, and product are plotted in the CONCENTRATIONS window.

Experiment with using the ADD-SUBSTRATE and ADD-INHIBITOR buttons to observe the effects of adding more molecules to the system manually as it runs.  The default setting for Kr is 0, which means that no product (blue) will be generated unless you change Kr to a non-zero value.

Note that when complexes form they stop moving.  This isn't intended to be physically realistic; it just makes the formation of complexes easier to see.  (This shouldn't affect the overall behavior of the model.)

## THINGS TO NOTICE

Watch the rate at which the enzyme and substrate stick together. How does this affect the conversion of substrate into product? What would happen if Kd is very high and Kc is very low? If Kr were the same order of magnitude as Kd and Kc?

## THINGS TO TRY

Run the simulation with VOLUME set to various amounts. How does this affect the curve?

If Kr is MUCH greater than Kd, what affect does this have on the reaction?  How important does complex formation become in this situation?

If Kc is MUCH less than Kd, what does this mean in the real-world? How are the enzyme and substrate related under these conditions?

What effect does adding inhibitor to the model have on the plot? Is Vmax affected?

## EXTENDING THE MODEL

What would happen if yellow inhibitor molecules could react to form a product? How would this affect the plot?

Inhibitors can be irreversible or reversible. That is, they can bind to an enzyme and never let go, or they can stick and fall off. Currently, the model simulates irreversible inhibitors. Modify the code so that the yellow molecules reversibly bind to the enzyme. How does this affect catalysis?

Often, the product of catalysis is an inhibitor of the enzyme. This is called a feedback mechanism. In this model, product cannot complex with enzyme. Modify the procedures so that the product is a reversible inhibitor. How does this affect catalysis with and without yellow inhibitor?

Include a slider that allows you to change the concentration of enzyme.  What affect does this have on the plot?  Vmax?  Look closely!

## NETLOGO FEATURES

It is a little difficult to ensure that a reactant never participates in two reactions simultaneously.  In the future, a primitive called GRAB may be added to NetLogo; then the code in the FORM-COMPLEX procedure wouldn't need to be quite so tricky.

## CREDITS AND REFERENCES

Thanks to Mike Stieff for his work on this model.

## HOW TO CITE

If you mention this model or the NetLogo software in a publication, we ask that you include the citations below.

For the model itself:

* Stieff, M. and Wilensky, U. (2001).  NetLogo Enzyme Kinetics model.  http://ccl.northwestern.edu/netlogo/models/EnzymeKinetics.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

Please cite the NetLogo software as:

* Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

## COPYRIGHT AND LICENSE

Copyright 2001 Uri Wilensky.

![CC BY-NC-SA 3.0](http://ccl.northwestern.edu/images/creativecommons/byncsa.png)

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.  To view a copy of this license, visit https://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.

Commercial licenses are also available. To inquire about commercial licenses, please contact Uri Wilensky at uri@northwestern.edu.

This model was created as part of the projects: PARTICIPATORY SIMULATIONS: NETWORK-BASED DESIGN FOR SYSTEMS LEARNING IN CLASSROOMS and/or INTEGRATED SIMULATION AND MODELING ENVIRONMENT. The project gratefully acknowledges the support of the National Science Foundation (REPP & ROLE programs) -- grant numbers REC #9814682 and REC-0126227.

<!-- 2001 Cite: Stieff, M. -->
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

complex
true
0
Polygon -2674135 true false 76 47 197 150 76 254 257 255 257 47
Polygon -10899396 true false 79 46 198 148 78 254

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

enzyme
true
0
Polygon -2674135 true false 76 47 197 150 76 254 257 255 257 47

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

inhib complex
true
0
Polygon -2674135 true false 76 47 197 150 76 254 257 255 257 47
Polygon -1184463 true false 77 48 198 151 78 253 0 253 0 46

inhibitor
true
0
Polygon -1184463 true false 197 151 60 45 1 45 1 255 60 255

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

substrate
true
5
Polygon -10899396 true true 76 47 197 151 75 256

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

virus
true
0
Circle -7500403 true true 75 75 150
Circle -7500403 true true 45 45 40
Circle -7500403 true true 45 215 40
Circle -7500403 true true 215 45 40
Circle -7500403 true true 215 215 40
Circle -7500403 true true 10 130 40
Circle -7500403 true true 130 10 40
Circle -7500403 true true 130 250 40
Circle -7500403 true true 250 130 40
Line -7500403 true 61 59 105 105
Line -7500403 true 240 60 195 105
Line -7500403 true 270 150 210 150
Line -7500403 true 240 240 195 195
Line -7500403 true 150 270 150 210
Line -7500403 true 60 240 105 195
Line -7500403 true 30 150 90 150
Line -7500403 true 150 30 150 90

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.1.1
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
