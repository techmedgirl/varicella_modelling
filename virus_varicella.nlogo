turtles-own
[
  infected?           ;; if true, the turtle is infectious
  has-shingles?       ;; reactivated vzv
  vaccinated?
  recovered?          ;; had chicken pox
  resistant?
  virus-check-timer   ;; number of ticks since this turtle's last virus-check
  isolating?
  isolation-duration
  isolation-progress
  infection-duration ;; how long turtle stays infected before recovering
  shingles-timer
  immune-boost
  symptom-delay
]

globals
[
  old-average-node-degree
]

to setup
  clear-all
  setup-nodes
  setup-spatially-clustered-network
  ask n-of initial-outbreak-size turtles
    [ become-infected ]
  ask links [ set color white ]
  reset-ticks
end

to setup-nodes
  set-default-shape turtles "circle"
  create-turtles number-of-nodes
  [
    ; for visual reasons, we don't put any nodes *too* close to the edges
    setxy (random-xcor * 0.95) (random-ycor * 0.95)
    set isolating? false
    set infected? false
    set has-shingles? false
    set vaccinated? false
    set recovered? false
    set immune-boost 0
    become-susceptible
    set virus-check-timer random virus-check-frequency
  ]
  ask n-of (vaccinated-fraction * number-of-nodes) turtles [
    set vaccinated? true
    set resistant? true
    set color gray
  ]
end

to setup-spatially-clustered-network
  let num-links (average-node-degree * number-of-nodes) / 2
  while [ count links < num-links ]
  [
    ask one-of turtles
    [
      let choice (min-one-of (other turtles with [not link-neighbor? myself])
                   [distance myself])
      if choice != nobody [
        create-link-with choice
      ]
    ]
  ]
  ; make the network look a little prettier
  repeat 10
  [
    layout-spring turtles links 0.3 (world-width / (sqrt number-of-nodes)) 1
  ]
  set old-average-node-degree average-node-degree
end

to change-spatially-clustered-network
  let num-links (average-node-degree * ( count turtles with [ not isolating? ] ) * ( count turtles with [ not isolating? ]) / ( 2 * count turtles ))
  let change-links num-links - count links
  if change-links < 0
  [
    ask n-of ( count links - num-links ) links [die]
  ]
  if change-links > 0
  [
    let attempts 0
    while [count links < num-links and attempts < 10000]
    [
      set attempts attempts + 1
      ask one-of turtles with [ not isolating? ]
      [
        let choice (min-one-of (other turtles with [not link-neighbor? myself and not isolating?])
          [distance myself])
        if choice != nobody [
          create-link-with choice
        ]
      ]
    ]
    ask links [ set color white ]
  ]
end

to go

  if all? turtles [not infected?]
    [ stop ]
  if old-average-node-degree != average-node-degree [change-spatially-clustered-network]
  ask turtles with [infected? and infection-duration >= 0] [
  set symptom-delay symptom-delay + 1
]
  ask turtles
  [
     set virus-check-timer virus-check-timer + 1
     if virus-check-timer >= virus-check-frequency
       [ set virus-check-timer 0 ]
  ]
  do-virus-checks
  update-isolation-status
  update-recovery
  spread-virus
  update-reactivation
  boost-immunity
  tick
end

to become-infected
  if infected? or recovered? or resistant? [ stop ]
  set infected? true
  set resistant? false
  set recovered? false
  set infection-duration ( -1 * (7 + random 15) )
  set symptom-delay 0
  set virus-check-timer 0
  set color cyan
end

to become-susceptible
  set infected? false
  set resistant? false
  set recovered? false
  set color blue
end

to become-resistant
  set infected? false
  set resistant? true
  set color gray
  ask my-links [ set color gray - 2 ]
end

to spread-virus
  ask turtles with [(infected? and infection-duration >= 0)  ;;   incubation finished
    or has-shingles?                        ;;   or shingles case
    and not isolating?]
    [ ask link-neighbors with [not infected? and not resistant? and not has-shingles? and not recovered? and not isolating? ]
        [ if random-float 100 < virus-spread-chance
            [ become-infected ] ] ]
end

to recover
  set infected? false
  set resistant? true
  set recovered? true
  set infection-duration 0
  set symptom-delay 0
  set color gray

  ;; Reconnect if isolation already completed
  if isolating? and isolation-progress >= isolation-duration [
    set isolating? false
    set isolation-progress 0
    change-spatially-clustered-network
  ]
end

to boost-immunity
  ask turtles with [recovered?]
  [
    if any? link-neighbors with [infected?] [
      set immune-boost shingles-boost-duration
    ]
  ]
end

to update-recovery
  ask turtles with [infected?]
  [
    set infection-duration infection-duration + 1
    if infection-duration = 0 [ set color red ]
    if infection-duration >= infection-length [
      recover
    ]
  ]
end

to update-reactivation
  ask turtles with [recovered? and not has-shingles?]
  [
    if immune-boost <= 0 and random-float 100 < shingles-risk [
      set has-shingles? true
      set shingles-timer 0
      set color orange
    ]
    set immune-boost immune-boost - 1
  ]

  ask turtles with [has-shingles?]
  [
    set shingles-timer shingles-timer + 1
    if shingles-timer > shingles-length [
      set has-shingles? false
      set resistant? true
      set color gray
    ]
  ]
end

to update-isolation-status
  ask turtles with [isolating?]
  [
    set isolation-progress isolation-progress + 1
    if isolation-progress >= isolation-duration and not infected?[
      set isolating? false
      set isolation-progress 0
      change-spatially-clustered-network
    ]
  ]
end

to do-virus-checks
  if isolation-enabled? [
    ask turtles with [infected? and symptom-delay >= 2 and virus-check-timer = 0]
    [
      ask my-links [die]
      set isolating? true
      set isolation-duration default-isolation-duration
      set isolation-progress 0
    ]
  ]
end


@#$#@#$#@
GRAPHICS-WINDOW
688
26
1352
691
-1
-1
16.0
1
10
1
1
1
0
0
0
1
-20
20
-20
20
1
1
1
ticks
30.0

SLIDER
21
191
229
224
virus-spread-chance
virus-spread-chance
0.0
100.00
11.4
0.1
1
%
HORIZONTAL

BUTTON
12
680
107
720
NIL
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
122
680
217
720
NIL
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

PLOT
8
430
301
661
Status of Epidemic
time (days)
% of people infected
0.0
52.0
0.0
100.0
true
true
"" ""
PENS
"susceptible" 1.0 0 -13345367 true "" "plot (count turtles with [not infected? and not resistant?]) / (count turtles) * 100"
"infected" 1.0 0 -2674135 true "" "plot (count turtles with [infected?]) / (count turtles) * 100"

SLIDER
25
15
230
48
number-of-nodes
number-of-nodes
10
3000
500.0
5
1
NIL
HORIZONTAL

SLIDER
21
230
226
263
virus-check-frequency
virus-check-frequency
1
91
2.0
1
1
days
HORIZONTAL

SLIDER
24
55
229
88
initial-outbreak-size
initial-outbreak-size
1
number-of-nodes
40.0
1
1
NIL
HORIZONTAL

SLIDER
21
149
226
182
average-node-degree
average-node-degree
1
30
15.0
1
1
NIL
HORIZONTAL

MONITOR
245
677
326
722
time (days)
ticks
17
1
11

SLIDER
24
101
202
134
vaccinated-fraction
vaccinated-fraction
0
1
0.7
0.01
1
NIL
HORIZONTAL

SLIDER
18
278
190
311
infection-length
infection-length
0
21
9.0
1
1
NIL
HORIZONTAL

SLIDER
14
370
222
403
default-isolation-duration
default-isolation-duration
0
30
5.0
1
1
NIL
HORIZONTAL

SWITCH
17
325
188
358
isolation-enabled?
isolation-enabled?
1
1
-1000

SLIDER
260
74
432
107
shingles-risk
shingles-risk
0
1
0.1
0.01
1
%
HORIZONTAL

SLIDER
260
23
453
56
shingles-length
shingles-length
0
100
10.0
1
1
(ticks)
HORIZONTAL

SLIDER
256
124
496
157
shingles-boost-duration
shingles-boost-duration
0
300
300.0
1
1
ticks
HORIZONTAL

@#$#@#$#@
## WHAT IS IT?

This is an agent-based simulation model representing the spread and reactivation of the Varicella Zoster Virus (VZV), commonly known for causing chickenpox and shingles. The model expands on a standard SI (Susceptible-Infected) network epidemic model by incorporating immunity, recovery, reactivation (shingles), vaccination, and isolation policies. Each node in the network represents an individual (or possibly household) and may exist in various states such as susceptible, infected, recovered, or reactivated.

## HOW IT WORKS

Each node (turtle) connects in a spatially-clustered network, where proximity determines link formation. At each tick (time step):

Virus Spread: Infected or shingles-reactivated nodes can spread the virus to susceptible, non-resistant neighbors with a probability defined by VIRUS-SPREAD-CHANCE.

Recovery: Infected individuals remain infectious for INFECTION-LENGTH days before recovering and gaining resistance.

Reactivation: Recovered individuals can develop shingles (a reactivation of VZV) with probability SHINGLES-RISK, unless their immunity is boosted by proximity to new infections.

Immunity Boost: Recovered individuals near infected nodes receive temporary immunity (boosted for SHINGLES-BOOST-DURATION).

Virus Checks & Isolation: If ISOLATION-ENABLED? is on, nodes periodically check for infection every VIRUS-CHECK-FREQUENCY days. If infected, they isolate, cutting all links for DEFAULT-ISOLATION-DURATION.

The model tracks the number of susceptible, infected, and reactivated individuals over time. The system halts when the virus dies out or infects everyone.

## HOW TO USE IT

Use the sliders to configure the simulation parameters:

NUMBER-OF-NODES: Total individuals in the network.

INITIAL-OUTBREAK-SIZE: Number of nodes initially infected.

VACCINATED-FRACTION: Proportion of nodes immune from the start.

AVERAGE-NODE-DEGREE: Determines the network’s connectivity.

VIRUS-SPREAD-CHANCE: Probability of virus transmission per contact.

VIRUS-CHECK-FREQUENCY: How often nodes detect and isolate.

INFECTION-LENGTH: Duration an individual stays infected.

ISOLATION-ENABLED?: Toggle isolation policy.

DEFAULT-ISOLATION-DURATION: Length of isolation after infection detection.

SHINGLES-RISK: Probability of shingles reactivation.

SHINGLES-LENGTH: Duration of shingles infection.

SHINGLES-BOOST-DURATION: Duration of temporary immunity from reactivation.

Press SETUP to initialize the network and GO to run the simulation. The network diagram on the right visualizes connections (white lines) and node states (blue: susceptible, red: infected, orange: shingles, gray: resistant/recovered/vaccinated).

The epidemic status plot shows how the proportions of susceptible and infected nodes evolve over time. 

## RELATED MODELS

Virus, Disease, Preferential Attachment, Diffusion on a Directed Network
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

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

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

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

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

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

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

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

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.4.0
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
