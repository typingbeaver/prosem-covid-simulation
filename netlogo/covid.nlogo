;;;;;;;;;;;;;;;
; DECLARATIONS
;;;;;;;;;;;;;;;

breed [sars a-sars]
breed [ang2 an-ang2]
breed [ace2 an-ace2]

; -------------------------------

; For "Enzyme Kinetics":

breed [ enzymes enzyme]      ;; red turtles that bind with and catalyze substrate
breed [ substrates substrate ]   ;; green turtles that bind with enzyme
breed [ inhibitors inhibitor ]   ;; yellow turtle that binds to enzyme, but does not react
breed [ products product ]     ;; blue turtle generated from enzyme catalysis

; ------------------------------


; globals []
globals [
  substrate-added ;; keeps track of how much substrate has been added
  v               ;; rate of complex formation at each time step
]

; turtles-own []   ; variables for all turtles
turtles-own [
  partner      ;; holds the turtle this turtle is complexed with,
               ;; or nobody if not complexed
]

sars-own [
  bound?
]
ang2-own [
  deactivated?
]
ace2-own []

patches-own [
  infected?
  dead?
  remaining-lifetime
]

;;;;;;;;;;;;;;;;;;;
; SETUP PROCEDURES
;;;;;;;;;;;;;;;;;;;

;to setup
;  clear-all
;  reset-ticks
;  setup-cells
;  setup-sars
;  setup-ang2
;  setup-ace2
;  recolor
;end

to setup-cells
  ask patches [
    ;set pcolor grey ; move to recolor
  ]
end

to setup-sars
  set-default-shape sars "virus"
  create-sars initial-sars-infection [
    setxy random-xcor random-ycor
    set size 1.5
    set color red ; move to recolor
  ]
end

to setup-ang2
  set-default-shape ang2 "triangle"
  create-ang2 angiotensin2-concentration [
    setxy random-xcor random-ycor
    set color yellow ; move to recolor
  ]
end

to setup-ace2
  set-default-shape ace2 "x"
  create-ace2 hrsace2-concentration [
    setxy random-xcor random-ycor
    set color blue ; move to recolor
  ]
end

;;;;;;;;;;;;;;;;
; GO PROCEDURES
;;;;;;;;;;;;;;;;

;to go
;  ask turtles[
;   ; random movement
;    fd 0.75 + random-float 0.5
;    rt random-float 360
;  ]
;end

to recolor  ; change color of turtles
            ; & cells based on current status

end

;;;;;;;;;;;;;;;;;;;;
; TURTLE PROCEDURES
;;;;;;;;;;;;;;;;;;;;



;;;;;;;;;;;;;;;;;;;
; PATCH PROCEDURES
;;;;;;;;;;;;;;;;;;;

; ------------------------------------------------------------------------------

;; observer procedure to set up model
to setup
  clear-turtles                    ;; clears view -- don't use clear-all so MM plot doesn't clear
  set substrate-added 0
  set v 0
  add enzymes 150                   ;; starts with constant number of enzymes
  add substrates volume             ;; add substrate based on slider
  reset-ticks

  ;----------
  setup-cells
  setup-sars
  setup-ang2
  setup-ace2
  recolor
  ;----------
end

;; observer procedure to add molecules to reaction
to add [kind amount]
  create-turtles amount
    [ set breed kind
      setxy random-xcor random-ycor
      set partner nobody
      setshape ]
  if kind = substrates
    [ set substrate-added substrate-added + amount ]
end

;; procedure that assigns a specific shape to a turtle, and shows
;; or hides it, depending on its state
to setshape
  ifelse breed = enzymes
    [ set color red
      ifelse partner = nobody
        [ set shape "enzyme" ]
        [ ifelse ([breed] of (partner) = substrates)
            [ set shape "complex" ]
            [ set shape "inhib complex" ] ] ]
    [ ifelse breed = substrates
        [ set color green
          set shape "substrate"
          set hidden? (partner != nobody) ]
        [ ifelse breed = inhibitors
            [ set color yellow
              set shape "inhibitor"
              set hidden? (partner != nobody) ]
            [ if breed = products
                [ set color blue
                  set shape "substrate"
                  set hidden? false ] ] ] ]
end

;; main procedure
to go

  ;-------------
  ask turtles[
    ; random movement
    fd 0.75 + random-float 0.5
    rt random-float 360
  ]
  ;-------------

  ask turtles [ move ]                ;; only non-complexed turtles will move
  ask enzymes [ form-complex ]         ;; enzyme may form complexes with substrate or inhibitor
  ask substrates [ react-forward ]     ;; complexed substrate may turn into product
  ask enzymes [ dissociate ]           ;; or complexes may just split apart
  tick
end

to move  ;; turtle procedure
  if partner = nobody
    [ fd 1
      rt random-float 360 ]
end

;; An enzyme forms a complex by colliding on a patch with a substrate
;; or inhibitor.  If it collides with an inhibitor, it always forms
;; a complex.  If it collides with a substrate, Kc is its percent chance
;; of forming a complex.
to form-complex  ;; enzyme procedure
  if partner != nobody [ stop ]
  set partner one-of (other turtles-here with [partner = nobody])
  if partner = nobody [ stop ]
  if [partner] of partner != nobody [ set partner nobody stop ]  ;; just in case two enzymes grab the same partner
  ifelse ((([breed] of partner) = substrates) and ((random-float 100) < Kc))
     or (([breed] of partner) = inhibitors)
    [ ask partner [ set partner myself ]
      setshape
      ask partner [ setshape ] ]
    [ set partner nobody ]
end

;; substrate procedure that controls the rate at which complexed substrates
;; are converted into products and released from the complex
to react-forward
  if (partner != nobody) and (random-float 1000 < Kr)
    [ set breed products
      ask partner [ set partner nobody ]
      let old-partner partner
      set partner nobody
      setshape
      ask old-partner [ setshape ] ]
end

;; enzyme procedure that controls the rate at which complexed turtles break apart
to dissociate
  if partner != nobody
    [ if ([breed] of partner = substrates) and (random-float 1000 < Kd)
      [ ask partner [ set partner nobody ]
        let old-partner partner
        set partner nobody
        setshape
        ask old-partner [ setshape ] ] ]
end


; Copyright 2001 Uri Wilensky.
; See Info tab for full copyright and license.
@#$#@#$#@
GRAPHICS-WINDOW
289
10
809
531
-1
-1
16.0
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
31
0
31
1
1
1
ticks
30.0

BUTTON
4
41
68
74
setup
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
69
41
130
74
go
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

SLIDER
133
146
287
179
Kr
Kr
0.0
100.0
100.0
1.0
1
NIL
HORIZONTAL

SLIDER
133
76
287
109
Kc
Kc
0.0
100.0
80.0
1.0
1
NIL
HORIZONTAL

SLIDER
133
111
287
144
Kd
Kd
0.0
100.0
62.0
1.0
1
NIL
HORIZONTAL

BUTTON
20
146
120
179
add inhibitor
add inhibitors volume
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

BUTTON
20
111
120
144
add substrate
add substrates volume
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

PLOT
3
181
287
359
Concentrations
time
C
0.0
50.0
0.0
50.0
true
true
"" ""
PENS
"Substrate" 1.0 0 -10899396 true "" "plot count substrates with [partner = nobody]"
"Complex" 1.0 0 -2674135 true "" "plot count enzymes with [partner != nobody]"
"Product" 1.0 0 -13345367 true "" "plot count products"

SLIDER
133
41
287
74
volume
volume
0.0
1000.0
1000.0
25.0
1
molecules
HORIZONTAL

SLIDER
86
361
287
394
angiotensin2-concentration
angiotensin2-concentration
0
100
48.0
1
1
NIL
HORIZONTAL

SLIDER
115
396
287
429
initial-sars-infection
initial-sars-infection
0
100
50.0
1
1
NIL
HORIZONTAL

SLIDER
113
431
287
464
hrsace2-concentration
hrsace2-concentration
0
100
50.0
1
1
NIL
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
