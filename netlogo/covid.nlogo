; Simulation of SARS-CoV-2 infection with impact on RAAS

;;;;;;;;;;;;;;;
; DECLARATIONS
;;;;;;;;;;;;;;;

breed [sars a-sars]    ;; SARS-CoV-2
breed [ang2 an-ang2]   ;; Angiotensin II
breed [ace2 an-ace2]   ;; hrsACE2 (enzyme)
breed [ang17 an-ang17] ;; Angiotensin 1-7 (product of enzymatic reaction)

globals [
  binding-ang2           ;; chance Angiotensin II will bind to ACE2
  binding-sars           ;; chance SARS-CoV-2 will bind to ACE2
  react-ang2             ;; chance of enzymatic reaction of Angiotensin II
  cell-infection         ;; chance SARS-CoV-2 will enter cell & infect it
  infection-sprouting    ;; chance new SARS will leave cell before cell death
  average-despawn-time   ;; average time after which unbound molecules will disappear
  max-ang2-concentration ;; limits Angitensin II-addition rate
]

turtles-own [
  partner         ;; holds the turtle this turtle is complexed with,
                  ;; or nobody if not complexed
  bound?          ;; states if SARS-CoV-2 or Ang2 is bound to an enzyme
  remaining-time  ;; states time after which turtles will despawn on inactitvity
                  ;; e. g. getting broken down or reacting with other enzymes
]

patches-own [
  ppartner           ;; holds the turtle this patch is complexed with,
                     ;; or nobody if not complexed
  infected?          ;; states if cell is infected with SARS-CoV-2, reproducing virus
  remaining-lifetime ;; states remaining lifetime when infected or
                     ;; remaining time until cell is replaced by a new one
  dead?              ;; states if cell is dead
]

; ------------------------------------------------------------------------------
;;;;;;;;;;;;;;;;;;;
; SETUP PROCEDURES
;;;;;;;;;;;;;;;;;;;

to setup
  clear-all
  reset-ticks

  ;; define static values
  set binding-ang2 60       ;; %
  set binding-sars 80       ;; %
  set react-ang2 30         ;; %
  set cell-infection 20     ;; %
  set infection-sprouting 5 ;; %
  set average-despawn-time 15  ;; ticks
  set max-ang2-concentration 2000  ;; turtles

  setup-cells
  setup-turtles
end

to setup-cells
  ask patches
  [ set-patch-values ]
end

;; sets default values
to set-patch-values
  set ppartner nobody
  set infected? false
  set remaining-lifetime random-poisson cell-average-infection-time
  set dead? false
  precolor
end

to setup-turtles
  ;; SARS-CoV-2
  set-default-shape sars "virus"
  add sars sars-initial-infection

  ;; Angiotensin II
  set-default-shape ang2 "substrate"
  add ang2 ang2-initial-amount

  ;; ACE2
  set-default-shape ace2 "enzyme"

  ;; Angiotensin 1-7
  set-default-shape ang17 "dot"
  add ang17 ang2-initial-amount
end

;; observer procedure to add molecules to reaction
to add [kind amount]
  create-turtles amount
  [ set breed kind
    setxy random-xcor random-ycor
    set-turtle-values
  ]
end

;; sets default turtle values
to set-turtle-values
    set size 0.8
    set partner nobody
    set bound? false
    set remaining-time (random-poisson average-despawn-time)
    recolor
end

; ------------------------------------------------------------------------------
;;;;;;;;;;;;;;;;
; GO PROCEDURES
;;;;;;;;;;;;;;;;

to go
  ask turtles [ despawn ]            ;; remove old turtles
  add-ang2                           ;; add newly produced Angiotensin II
  add-hrsace2                        ;; add given hrsHCE2
  ask turtles [ move ]               ;; random movement

  ask ace2 [ form-ace2-complex ]     ;; free enzymes have higher priority than
  ask patches [ form-cell-complex ]  ;; cells's due to free movement
  ask ang2 [ react-forward ]         ;; enzyme catalysation
  ask sars [ infect ]                ;; infect cells
  ask patches [ reproduce ]          ;; let cells produce new SARS
  ask patches [ replace ]            ;; let (new) cells come back to life

  tick
end

;; change color of turtles based on current status
to recolor
  ;; SARS-CoV-2
  ifelse (breed = sars)
  [ ifelse bound?
      [ set color red - 1 ]     ;; darken if bound
      [ set color red ]
  ]
  ;; Angiotensin II
  [ ifelse (breed = ang2)
    [ ifelse bound?
      [ set color yellow - 1 ]  ;; darken if bound
      [ set color yellow ]
    ]
    ;; ACE2
    [ ifelse (breed = ace2)
      [ set color blue ]
      ;; Angiotensin 1-7
      [ if (breed = ang17)
        [ set color green ]
      ]
    ]
  ]
end

;; change color of cells based on current status
to precolor
  ifelse (infected? = false)
  [ set pcolor pink - 1.5 ]  ;; cell alive & healthy
  [ ifelse (dead? = false)
    [ set pcolor remaining-lifetime * (4 / cell-average-infection-time) ]  ;; progressively darkens cell, grey to black
    [ set pcolor black ]     ;; cell is dead
  ]
end

;; adds Angiotensin 2 regularly until max is reached
to add-ang2
  if (count ang2 < max-ang2-concentration)
  [ ;; parabola / quadratic function
    let factor ( - ang2-add-every-tick / (max-ang2-concentration * max-ang2-concentration))
    let amount ( factor * (count ang2 * count ang2) + ang2-add-every-tick )

    add ang2 amount
  ]
end

;; adds given amount of hrsACE2 every x tick if activated
to add-hrsACE2
  if add-hrsace2? and (ticks > hrsace2-add-after)
  [ if (ticks mod hrsace2-add-every = 0)
    [ add ace2 hrsace2-amount ]
  ]
end

; ------------------------------------------------------------------------------
;;;;;;;;;;;;;;;;;;;;
; TURTLE PROCEDURES
;;;;;;;;;;;;;;;;;;;;

;; random movement
to move
  if (bound? = false)
  [ rt random-float 360
    fd 0.75 + random-float 0.5
  ]
end

;; (based on Enzyme Kinetics)
to form-ace2-complex
  if (partner != nobody)
    [ stop ] ;; can't bind to multiple molecules in this simulation

  set partner one-of other turtles-here  ;; search for reaction partner

  if (partner = nobody)
    [ stop ]  ;; stop when no reaction partners available on this patch

  if ([partner] of partner != nobody)
    [ set partner nobody stop ]  ;; just in case two cells grab the same partner

  ifelse ( ([breed] of partner = ang2) and (random-float 100 < binding-ang2) )  ;; chance of binding
      or ( ([breed] of partner = sars) and (random-float 100 < binding-sars) )  ;; can't bind to another hrsACE2 or Angiotensin 1-7
  [ ifelse ([breed] of partner = sars)
    [ ;; if complexed with SARS-CoV-2 remove turtles
      ask partner [ die ]
      die
    ]
    [ ;; if complexed with Angiotensin II create complex
      ask partner
      [ set partner myself
        set bound? true
        hide-turtle
      ]
      create-link-to partner  ;; add link for combined movement
      [ tie
        hide-link
      ]
      set shape "complex"
    ]
  ]

  [ set partner nobody ]  ;; compex-forming unsucessful
end

;; SARS-CoV-2 procedure
to infect
  if is-patch? partner  ;; hrsACE2 can't get infected
  [ if (random-float 100 < cell-infection)  ;; chance to intrude cell
    [ ask partner
      [ set infected? true
        set ppartner nobody
      ]
      die
    ]
  ]
end

;; Angiotensin II procedure that controls the rate at which complexed Ang2
;; are converted into Angiotensin 1-7 and released from the complex
;; (based on Enzyme Kinetics)
to react-forward
  if (partner != nobody) and (random-float 100 < react-ang2)  ;; chance of reacting
  [ ifelse is-patch? partner
    [ ;; if bound to cell
      ask partner [set ppartner nobody]
    ]
    [ ;; if bound to hrsACE2
      ask partner
      [ ;; reset enzyme
        set partner nobody
        set shape "enzyme"
      ]
      ask my-links [ die ]
    ]

    ;; convert to Angiotensin 1-7
    set breed ang17
    set-turtle-values
  ]
end

;; removes turtles from simulation after given time
to despawn
  if (partner = nobody)
  [ ifelse (remaining-time > 0)
    [ set remaining-time (remaining-time - 1) ]
    [ die ]
  ]
end

; ------------------------------------------------------------------------------
;;;;;;;;;;;;;;;;;;;
; PATCH PROCEDURES
;;;;;;;;;;;;;;;;;;;

;; (based on Enzyme Kinetics)
to form-cell-complex
  if (infected? = false)  ;; only healty cells have enzymatic function
  [ if (ppartner != nobody)
    [ stop ]  ;; can't bind to multiple molecules in this simulation

    set ppartner one-of turtles-here  ;; search for reaction partner
    if (ppartner = nobody)
    [ stop ]  ;; stop when no reaction partners available on this patch

    if ([partner] of ppartner != nobody)
      [ set ppartner nobody stop ]  ;; just in case two cells grab the same partner

    ifelse ( [breed] of ppartner = ang2 and random-float 100 < binding-ang2 )  ;; chance of binding
        or ( [breed] of ppartner = sars and random-float 100 < binding-sars )  ;; cell can't bind to a free hrsACE2 or Angiotensin 1-7
    [ ask ppartner
      [ set partner myself
        set bound? true
        recolor
      ]
    ]
    [ set ppartner nobody ]  ;; compex-forming unsucessful
  ]
end

; lets infected cells reproduce the virus, release on death
to reproduce
  if (dead? = false) and infected?
  [ ifelse (remaining-lifetime > 0)  ;; reduce lifetime
    [ set remaining-lifetime (remaining-lifetime - 1)

      ;; random virus ejecting during infection
      if remaining-lifetime < (cell-average-infection-time / 2)  ;; only possible on half remaining liftime
      [ if random-float 100 < infection-sprouting  ;; chance of sprouting
        [ eject-sars 1 ]
      ]
    ]
    [ ;; death of cell
      set dead? true
      set remaining-lifetime (0 - cell-average-repair-time)
      eject-sars sars-reproduction-factor
    ]
    precolor
  ]
end

;; spawns given amount SARS-CoV-2 on executing patch
to eject-sars [amount]
  sprout-sars amount
  [ set-turtle-values ]
end

to replace
  if dead?
  [ ifelse (remaining-lifetime < 0)
    [ set remaining-lifetime (remaining-lifetime + 1) ]
    [ ;; cell gets replaced with new one
      set-patch-values
    ]
  ]
end

; ------------------------------------------------------------------------------

; Copyright 2021 Niclas Bartsch
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
0
0
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
17
628
252
661
ang2-initial-amount
ang2-initial-amount
50
600
500.0
50
1
Angiotensin II
HORIZONTAL

SLIDER
281
550
521
583
sars-initial-infection
sars-initial-infection
0
20
2.0
1
1
NIL
HORIZONTAL

SLIDER
547
626
725
659
hrsace2-amount
hrsace2-amount
0
250
90.0
10
1
hrsACE2
HORIZONTAL

SLIDER
17
664
253
697
ang2-add-every-tick
ang2-add-every-tick
0
200
95.0
5
1
Angiotensin II
HORIZONTAL

TEXTBOX
19
700
254
761
when changing initial amount of Angiotensin II, recalibrate this value so Angiotensin II concentration stays stable w/o SARS & hrsACE2
11
0.0
0

TEXTBOX
11
608
261
626
╒═ Angiotensin 2 ═══════════════════╕
11
0.0
1

TEXTBOX
272
534
536
552
╒═ SARS-CoV-2 ═════════════════════╕
11
0.0
1

TEXTBOX
540
534
733
552
╒═ hrsACE2 ═══════════════╕
11
0.0
1

TEXTBOX
12
537
249
555
╒═ CONTROLS ═════════════════╕
11
0.0
1

SLIDER
284
657
523
690
cell-average-infection-time
cell-average-infection-time
1
50
25.0
1
1
tick(s)
HORIZONTAL

SLIDER
281
586
520
619
sars-reproduction-factor
sars-reproduction-factor
1
10
5.0
1
1
x
HORIZONTAL

PLOT
827
528
1328
813
Cell Monitor
time
no. of cells
0.0
400.0
0.0
1000.0
true
true
"" ""
PENS
"healthy" 1.0 0 -10899396 true "" "plot count patches with [ infected? = false ]"
"infected" 1.0 0 -13345367 true "" "plot count patches with [ infected? = true and dead? = false ]"
"dead" 1.0 0 -2674135 true "" "plot count patches with [ dead? = true ]"

PLOT
826
10
1362
520
Concentrations
time
no. of turtles
0.0
400.0
0.0
1500.0
true
true
"" ""
PENS
"Angiotensin II" 1.0 0 -4079321 true "" "plot count ang2"
"SARS-CoV-2" 1.0 0 -2674135 true "" "plot count sars with [ bound? = false ]"
"hrsACE2" 1.0 0 -13345367 true "" "plot count ace2"
"initial Ang2" 1.0 2 -7171555 false "" "plot ang2-initial-amount"
"Angiotensin 1-7" 1.0 0 -10899396 true "" "plot count ang17"

MONITOR
745
576
819
621
% infected
count patches with [ infected? = true and dead? = false ] / 10
3
1
11

MONITOR
744
528
820
573
% healthy
count patches with [ infected? = false ] / 10
3
1
11

MONITOR
746
623
819
668
% dead
count patches with [ dead? = true ] / 10
3
1
11

SWITCH
547
554
678
587
add-hrsace2?
add-hrsace2?
1
1
-1000

SLIDER
547
661
726
694
hrsace2-add-every
hrsace2-add-every
1
20
1.0
1
1
tick(s)
HORIZONTAL

SLIDER
283
694
524
727
cell-average-repair-time
cell-average-repair-time
0
100
40.0
1
1
tick(s)
HORIZONTAL

TEXTBOX
278
639
531
657
╒═ Cells ═════════════════════════╕
11
0.0
1

TEXTBOX
17
770
167
788
NIL
11
0.0
1

SLIDER
547
590
726
623
hrsace2-add-after
hrsace2-add-after
0
400
200.0
20
1
ticks
HORIZONTAL

@#$#@#$#@
## WHAT IS IT?

This model tries to show the replication of SARS-CoV-2 using membrane enzyme ACE2 as receptor for cell entry, with resulting effects on the human Renin-Angiogentin-System of which ACE2 is a part of.

Therefore this model implements the enzymatic reaction
```text
                 ACE2
Angiotensin II ========> Angiotensin (1-7)
```
to show side effects of a SARS-CoV-2 infection, as Angiotensin II and Angiotensin (1-7) are counteregulatory. Angiotensin II has a vasoconstrictive and inflammatory effect whilst Angiotensin (1-7) is vasodilative.

In addition it is possible to show the effects of treatment with human recombiant soulable ACE2.

## HOW TO USE IT

Reset the simulation before every run with `setup` or 'S' on your keyboard.

Simply hit `go` or 'G' on your keyboard to start a simulation with SARS-CoV-2 infection but without hrsACE2 treatment. If you want to add hrsACE2 to the simulation simply activate `add-hrsace2?`!

------

You can change the amount of Angiotensin II turtles with the `ang2-initial-amount` slider. Please readjust `ang2-add-every-tick` as described when doing this!

The start amount of SARS-CoV-2 turtles can be changed with the slider `sars-initial infection`, as well as the reproduction factor (how many turtles will be ejected after cell death) with `sars-reproduction-factor`.

In the hrsACE2 section you can set whether or not hrsACE2 should be added to the simulation ('add-hrsace2?'). Determine the point of time from when it should get added with `hrsace2-add-after` as well as the amount of turtles every chosen interval with `hrsace2-amount` and `hrsace2-add-every`.

Change the cells behaviour with `cell-average-infection-time` (time until cell dies and releases SARS-CoV-2 turtles) and `cell-average-repair-time` (time until cell is replaced and available again).

## THINGS TO NOTICE

How does the replication of SARS-CoV-2 affect the amount of Angiotensin II and Angiotensin (1-7) turtles? Is it affected by the amount of healthy cells?

Which difference do you see after the addition of hrsACE2 to the simulation?

## THINGS TO TRY

What effect do different amounts of hrsACE2 turtles have? Which influence does the time of addition have on effectiveness?

## EXTENDING THE MODEL

The overall simlation is very basic and abstract in many places.
You can implement a more realistic cell replacement, add a immune response or effects of inflammation or realise many other ideas.

## CREDITS AND REFERENCES

This model is based on:

* Stieff, M. and Wilensky, U. (2001).  NetLogo Enzyme Kinetics model.  http://ccl.northwestern.edu/netlogo/models/EnzymeKinetics.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL. (modified)

## HOW TO CITE

If you mention this model or the NetLogo software in a publication, we ask that you include the citations below.

For the model itself:

* Bartsch, N. (2021). NetLogo SARS-CoV-2 replication with effects on RAS model. Department of Computer Science, University of Applied Sciences Bonn-Rhein-Sieg, Sankt Augustin, Germany.

Please cite the NetLogo software as:

* Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

## COPYRIGHT AND LICENSE

Copyright 2021 Niclas Bartsch.

![CC BY-NC-SA 3.0](http://ccl.northwestern.edu/images/creativecommons/byncsa.png)

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.  To view a copy of this license, visit https://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.
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
Polygon -13345367 true false 76 47 197 150 76 254 257 255 257 47
Polygon -1184463 true false 79 46 198 148 78 254

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
1
Polygon -13345367 true false 76 47 197 150 76 254 257 255 257 47

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
NetLogo 6.2.0
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
