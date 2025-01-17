breed[cats cat]
breed[mice mouse]
globals [a b c d w z]
mice-own [tipo poisoned tempo]
turtles-own [energy]

to setup
  ca
  (ifelse
    Modelo = "Original" [
      setup-patches-original
      setup-agents-original
    ]
    Modelo = "Comportamento Racional" [  ; Same startup as "Original"
      setup-patches-original
      setup-agents-original
    ]
    Modelo = "Generalizacao do Comportamento Racional" [
      setup-patches-original
      setup-agents-original
      set-color-mice
      setup-food
      setup-energy
      set-label
      if traps? [ setup-traps ]
    ]
  )
  reset-ticks
end

to go
  ; Check execution end
  if ticks >= maxTick? [ export-data stop ]

  (ifelse
    Modelo = "Original" [
      move-mice-original
      move-cats-original
      lunch-time-original
    ]
    Modelo = "Comportamento Racional" [
      move-cats-original
      ifelse smartMice?
      [ move-mice-racional ]
      [ move-mice-original ]
      ifelse smartCats?
      [ lunch-time-rational ]
      [ lunch-time-original ]
    ]
    Modelo = "Generalizacao do Comportamento Racional" [
      move-cats-original
      move-mice-racional
      lunch-time-advanced
      set-label
      energy-check
      poisoned-check
      trap-check
    ]
  )
  tick
  if count mice = 0 or count cats = 0[
    export-data
    stop
  ]
end

;; ADVANCED RACIONAL BEHAVIOR
to trap-check
  ask mice [
    if [pcolor] of patch-here = red [
      color-default
      die
    ]
  ]

  ask cats [
    if [pcolor] of patch-here = red [
      set energy energy - 15
    ]
  ]
end

to setup-traps
  ask patches with [not any? turtles-here and pcolor != yellow and pcolor != green and pcolor != white] [
    if random 101 < 2 [ ; 2 % traps
      set pcolor red
    ]
  ]
end

to poisoned-check
  ask mice [
    if poisoned = true [
      if tempo = 15 [ ; Poisoned ticks
        set poisoned false
        set-color-mice
      ]
      if tempo < 15 [
        set tempo tempo + 1
      ]
    ]
  ]
end

to set-color-mice
  ask mice [
    ifelse tipo = "loner" [
      set color brown
    ]
    [
      set color gray
    ]
  ]
end

to setup-energy
  ask turtles [
    set energy startEnergy?
  ]
end

to energy-check
  ask turtles [
    if energy <= 0 [die]
  ]
end

to color-default
  ask patch-here [
    let x 28
    let y 48
    if pycor mod 2 = 0
    [set x 48 set y 28]
    ifelse pxcor mod 2 = 0
    [set pcolor x]
    [set pcolor y]
  ]
end

to lunch-time-advanced
  ask cats [
    (ifelse
      any? mice-on neighbors[
        let miceEnergy 0
        ask one-of mice-on neighbors [
          if poisoned = false [
            set miceEnergy energy
            die
          ]
        ]
        set energy energy + round(miceEnergy / 2)
      ]
      any? mice-on patch-ahead 2 [
        fd 1
        let miceEnergy 0
        ask one-of mice-on patch-ahead 1 [
          if poisoned = false [
            set miceEnergy energy
            die
          ]
        ]
        set energy energy + round(miceEnergy / 2)
      ]
      any? neighbors with [pcolor = white] [
        move-to one-of neighbors with [pcolor = white]
        set energy energy + 10
        color-default ; Return to default color
      ]
      any? neighbors with [pcolor = green] [
        move-to one-of neighbors with [pcolor = green]
        set energy energy - 25
        color-default ; Return to default color
    ])
  ]

  ask mice [
    (ifelse
      any? neighbors with [pcolor = yellow] [
        move-to one-of neighbors with [pcolor = yellow]
        set energy energy + 10
        color-default ; Return to default color
      ]
      any? neighbors with [pcolor = green] [
        move-to one-of neighbors with [pcolor = green]
        set energy energy - 25
        color-default ; Return to default color
        set poisoned true
        set tempo 1
        set color green
    ])
  ]
end

to setup-food
  let food 0
  while [food != maxFood?] [
    ask one-of patches with [not any? turtles-here and pcolor != yellow and pcolor != green and pcolor != white] [
      ifelse random 101 < 50
      [ set pcolor yellow ]
      [ set pcolor white ]
      if poisonedFood? [
        if random 101 < 20 [ set pcolor green ]
      ]
    ]
    set food food + 1
  ]
end

;; RATIONAL BEHAVIOR
to set-label
  ask turtles [
    ifelse energyLabel?
    [
      set label energy
      set label-color orange
    ]
    [ set label ""  ]
  ]
end

to lunch-time-rational
  ask cats [
    (ifelse
      any? mice-on neighbors[
      ask one-of mice-on neighbors [die]
    ]
      any? mice-on patch-ahead 2 [
        fd 1
        ask one-of mice-on patch-ahead 1 [die]
      ]
    )
  ]
end

to move-mice-racional
  ask mice [
    ifelse any? cats-on neighbors [
      ; Cat on 3 front neighbors => Move back 2
      ifelse (is-patch? patch-left-and-ahead 45 1 AND any? cats-on patch-left-and-ahead 45 1) OR (is-patch? patch-ahead 1 AND any? cats-on patch-ahead 1) OR (is-patch? patch-right-and-ahead 45 1 AND any? cats-on patch-right-and-ahead 45 1)
      [
        ifelse is-patch? patch-ahead (-2)
        [fd (-2) set energy energy - 1]
        [move-to one-of neighbors with [not any? cats] set energy energy - 1]
      ]
      [
        ; Cat on 3 back neighbors => Move forward 2
        ifelse (is-patch? patch-left-and-ahead 135 1 AND any? cats-on patch-left-and-ahead 135 1) OR (is-patch? patch-ahead (-1) AND any? cats-on patch-ahead (-1)) OR (is-patch? patch-right-and-ahead 135 1 AND any? cats-on patch-right-and-ahead 135 1)
        [
          ifelse is-patch? patch-ahead 2
          [fd 2 set energy energy - 1]
          [move-to one-of neighbors with [not any? cats-here] set energy energy - 1]
        ]
        [
          ; Cat on left => Move to Right 2
          ifelse is-patch? patch-left-and-ahead 90 1 AND any? cats-on patch-left-and-ahead 90 1
          [
            ifelse is-patch? patch-right-and-ahead 90 2
            [move-to patch-right-and-ahead 90 2 set energy energy - 1]
            [move-to one-of neighbors with [not any? cats-here] set energy energy - 1]
          ]
          [
            ; Cat on right => Move to Left 2
            if is-patch? patch-right-and-ahead 90 1 AND any? cats-on patch-right-and-ahead 90 1
            [
              ifelse is-patch? patch-right-and-ahead 90 2
              [move-to patch-left-and-ahead 90 2 set energy energy - 1]
              [move-to one-of neighbors with [not any? cats-here] set energy energy - 1]
            ]
          ]
        ]
      ]
    ]
    [
      ; If any cats on neighbors, check for mice
      ifelse any? mice-on neighbors
      [
        let vizinho one-of mice-on neighbors
        ifelse tipo = "loner" and [tipo] of vizinho = "loner"
        [
          move-to one-of neighbors
          set energy energy - 1
        ]
        [
          ifelse tipo = "loner" and [tipo] of vizinho = "friendly"
          [
            let friendEnergy 0
            ask vizinho [
              set friendEnergy energy
              die
            ]
            set energy energy + friendEnergy
          ]
          [
            ifelse tipo = "friendly" and [tipo] of vizinho = "friendly" and breed? = true [
              hatch 4 [
                setxy random-pxcor random-pycor
                set tipo one-of ["friendly" "loner"]
                set poisoned false
                set tempo 0
                ;set child true
                ;set child-time 0
                ;set size 1
                set energy 25
              ]
            ]
            [
              let ourEnergy energy
              ask vizinho [
                set energy energy + ourEnergy
              ]
              die
            ]
          ]
        ]
      ]
      [
        move-to one-of neighbors
        set energy energy - 1
      ]
    ]
  ]
end

;; Original Behavior Code
to setup-patches-original
  ask patches[
    let x 28
    let y 48
    if pycor mod 2 = 0
    [set x 48 set y 28]
    ifelse pxcor mod 2 = 0
    [set pcolor x]
    [set pcolor y]
  ]
end

to setup-agents-original
  create-mice N-mice
  [
    set shape "mouse side"
    set color 4
    set size 1.5
    setxy random-pxcor random-pycor
    if Modelo = "Generalizacao do Comportamento Racional"
    [ set tipo one-of ["friendly" "loner"] set poisoned false set tempo 0 ]
  ]

  create-cats N-cats
  [
    set shape "cat"
    set color black
    set size 1.2
    let x one-of patches with [not any? mice-here and not any? mice-on neighbors and not any? cats-here]
    setxy [pxcor] of x [pycor] of x
    set heading one-of [0 90 180 270]
  ]
end

to move-mice-original
  ask mice[
    let x one-of neighbors
    move-to x
  ]
end

to move-cats-original
  ask cats[
    if patch-ahead 1 != nobody [set a patch-ahead 1]
    if patch-ahead 2 != nobody [set b patch-ahead 2]
    if patch-right-and-ahead 90 1 != nobody [set c patch-right-and-ahead 90 1]
    if patch-right-and-ahead -90 1 != nobody [set d patch-right-and-ahead -90 1]
    if patch-right-and-ahead 45 1 != nobody [set w patch-right-and-ahead 45 1]
    if patch-right-and-ahead -45 1 != nobody [set z patch-right-and-ahead -45 1]
    let y (patch-set a b c d w z)
    let x one-of y
    move-to x
    if random 100 < 25
    [set heading one-of [0 90 180 270]]
    set energy energy - 1
  ]
end

to lunch-time-original
  ask mice[
    if any? cats-on neighbors [die]
  ]
end

;; EXPORT DATA TO TXT
to pt [string] ; Means Print
  file-type string
end

to ptln [string] ; Means PrintLine
  file-print string
end

to export-data
  let filename "dataTest.txt"
  file-open filename
  pt "Settings: " ptln Modelo
  pt "N-Mice: " pt N-Mice pt "\tN-Cats: " ptln N-Cats
  pt "Max-Ticks: " pt maxTick? pt "\tTicks: " pt ticks pt "\tExceeds: " ptln ticks = maxTick?
  pt "Mice-end: " pt count mice pt "\tCats-end: " ptln count cats
  pt "Loners:" pt count mice with [tipo = "loner"] pt "\tFriendly: " ptln count mice with [tipo = "friendly"]
  pt "\n"
  file-close
end
@#$#@#$#@
GRAPHICS-WINDOW
238
67
775
605
-1
-1
16.03030303030303
1
14
1
1
1
0
1
1
1
-16
16
-16
16
0
0
1
ticks
30.0

SLIDER
33
102
205
135
N-mice
N-mice
0
20
10.0
1
1
NIL
HORIZONTAL

SLIDER
33
136
205
169
N-cats
N-cats
0
10
5.0
1
1
NIL
HORIZONTAL

BUTTON
33
66
115
99
NIL
setup\n
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
123
66
205
99
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
1

MONITOR
792
162
982
207
NIL
ticks
17
1
11

MONITOR
792
208
887
253
Nº de Ratos
count mice
17
1
11

MONITOR
887
208
982
253
Nº de Gatos
count cats
17
1
11

CHOOSER
33
204
205
249
Modelo
Modelo
"Original" "Comportamento Racional" "Generalizacao do Comportamento Racional"
2

SWITCH
11
505
140
538
energyLabel?
energyLabel?
0
1
-1000

SLIDER
33
170
205
203
maxTick?
maxTick?
0
1500
1500.0
10
1
NIL
HORIZONTAL

SLIDER
36
471
208
504
maxFood?
maxFood?
0
200
100.0
2
1
NIL
HORIZONTAL

SWITCH
11
539
140
572
poisonedFood?
poisonedFood?
0
1
-1000

MONITOR
792
300
855
345
Milk
count patches with [pcolor = white]
17
1
11

MONITOR
918
300
982
345
Cheese
count patches with [pcolor = yellow]
17
1
11

MONITOR
855
300
918
345
Poisoned
count patches with [pcolor = green]
17
1
11

SLIDER
36
437
208
470
startEnergy?
startEnergy?
0
100
50.0
50
1
NIL
HORIZONTAL

MONITOR
887
254
982
299
Loner
count mice with [tipo = \"loner\"]
17
1
11

MONITOR
792
254
887
299
Friendly
count mice with [tipo = \"friendly\"]
17
1
11

SWITCH
51
330
177
363
smartCats?
smartCats?
1
1
-1000

SWITCH
51
294
177
327
smartMice?
smartMice?
1
1
-1000

TEXTBOX
381
14
623
56
Cats-And-Mice
32
0.0
1

TEXTBOX
31
254
237
305
Comportamento Racional\nSettings:
14
0.0
1

TEXTBOX
32
378
212
446
Generalizacao do Comportamento Racional\nSettings:
14
0.0
1

TEXTBOX
796
135
893
179
Variáveis:
18
0.0
1

PLOT
792
346
983
492
Ratos / Gatos
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"Ratos" 1.0 0 -4539718 true "" "plot count mice"
"Gatos" 1.0 0 -13840069 true "" "plot count cats"

SWITCH
141
505
235
538
traps?
traps?
0
1
-1000

SWITCH
141
539
235
572
breed?
breed?
0
1
-1000

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
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

cat
false
0
Line -7500403 true 285 240 210 240
Line -7500403 true 195 300 165 255
Line -7500403 true 15 240 90 240
Line -7500403 true 285 285 195 240
Line -7500403 true 105 300 135 255
Line -16777216 false 150 270 150 285
Line -16777216 false 15 75 15 120
Polygon -7500403 true true 300 15 285 30 255 30 225 75 195 60 255 15
Polygon -7500403 true true 285 135 210 135 180 150 180 45 285 90
Polygon -7500403 true true 120 45 120 210 180 210 180 45
Polygon -7500403 true true 180 195 165 300 240 285 255 225 285 195
Polygon -7500403 true true 180 225 195 285 165 300 150 300 150 255 165 225
Polygon -7500403 true true 195 195 195 165 225 150 255 135 285 135 285 195
Polygon -7500403 true true 15 135 90 135 120 150 120 45 15 90
Polygon -7500403 true true 120 195 135 300 60 285 45 225 15 195
Polygon -7500403 true true 120 225 105 285 135 300 150 300 150 255 135 225
Polygon -7500403 true true 105 195 105 165 75 150 45 135 15 135 15 195
Polygon -7500403 true true 285 120 270 90 285 15 300 15
Line -7500403 true 15 285 105 240
Polygon -7500403 true true 15 120 30 90 15 15 0 15
Polygon -7500403 true true 0 15 15 30 45 30 75 75 105 60 45 15
Line -16777216 false 164 262 209 262
Line -16777216 false 223 231 208 261
Line -16777216 false 136 262 91 262
Line -16777216 false 77 231 92 261

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

mouse side
false
0
Polygon -7500403 true true 38 162 24 165 19 174 22 192 47 213 90 225 135 230 161 240 178 262 150 246 117 238 73 232 36 220 11 196 7 171 15 153 37 146 46 145
Polygon -7500403 true true 289 142 271 165 237 164 217 185 235 192 254 192 259 199 245 200 248 203 226 199 200 194 155 195 122 185 84 187 91 195 82 192 83 201 72 190 67 199 62 185 46 183 36 165 40 134 57 115 74 106 60 109 90 97 112 94 92 93 130 86 154 88 134 81 183 90 197 94 183 86 212 95 211 88 224 83 235 88 248 97 246 90 257 107 255 97 270 120
Polygon -16777216 true false 234 100 220 96 210 100 214 111 228 116 239 115
Circle -16777216 true false 246 117 20
Line -7500403 true 270 153 282 174
Line -7500403 true 272 153 255 173
Line -7500403 true 269 156 268 177

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

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

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

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

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
<experiments>
  <experiment name="SmartMice" repetitions="500" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles</metric>
    <metric>count mice</metric>
    <metric>count cats</metric>
    <metric>ticks</metric>
    <enumeratedValueSet variable="smartMice?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maxTick?">
      <value value="1500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="N-cats">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="smartCats?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Modelo">
      <value value="&quot;Comportamento Racional&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="startEnergy?">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="poisonedFood?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="N-mice">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="energyLabel?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maxFood?">
      <value value="100"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Original" repetitions="500" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles</metric>
    <metric>count mice</metric>
    <metric>count cats</metric>
    <metric>ticks</metric>
    <enumeratedValueSet variable="smartMice?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maxTick?">
      <value value="1500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="N-cats">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="smartCats?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Modelo">
      <value value="&quot;Original&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="startEnergy?">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="poisonedFood?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="N-mice">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="energyLabel?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maxFood?">
      <value value="100"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="SmartCats" repetitions="500" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles</metric>
    <metric>count mice</metric>
    <metric>count cats</metric>
    <metric>ticks</metric>
    <enumeratedValueSet variable="smartMice?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maxTick?">
      <value value="1500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="N-cats">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="smartCats?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Modelo">
      <value value="&quot;Comportamento Racional&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="startEnergy?">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="poisonedFood?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="N-mice">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="energyLabel?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maxFood?">
      <value value="100"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="RationalBehavior" repetitions="500" sequentialRunOrder="false" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles</metric>
    <metric>count mice</metric>
    <metric>count cats</metric>
    <metric>ticks</metric>
    <enumeratedValueSet variable="smartMice?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maxTick?">
      <value value="1500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="N-cats">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="smartCats?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Modelo">
      <value value="&quot;Comportamento Racional&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="startEnergy?">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="poisonedFood?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="N-mice">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="energyLabel?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maxFood?">
      <value value="100"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="PoisonedFood" repetitions="500" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles</metric>
    <metric>count mice</metric>
    <metric>count cats</metric>
    <metric>ticks</metric>
    <metric>count mice with [tipo = "friendly"]</metric>
    <metric>count mice with [tipo = "loner"]</metric>
    <metric>count patches with [pcolor = white]</metric>
    <metric>count patches with [pcolor = green]</metric>
    <metric>count patches with [pcolor = yellow]</metric>
    <enumeratedValueSet variable="breed?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maxTick?">
      <value value="1500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="N-cats">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="smartCats?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="especies?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Modelo">
      <value value="&quot;Generalizacao do Comportamento Racional&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="N-mice">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="energyLabel?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="smartMice?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="energia?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="traps?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="come?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="startEnergy?">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="poisonedFood?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="food?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maxFood?">
      <value value="100"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Energia" repetitions="500" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles</metric>
    <metric>count mice</metric>
    <metric>count cats</metric>
    <metric>ticks</metric>
    <metric>count mice with [tipo = "friendly"]</metric>
    <metric>count mice with [tipo = "loner"]</metric>
    <metric>count patches with [pcolor = white]</metric>
    <metric>count patches with [pcolor = green]</metric>
    <metric>count patches with [pcolor = yellow]</metric>
    <enumeratedValueSet variable="breed?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maxTick?">
      <value value="1500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="N-cats">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="smartCats?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="especies?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Modelo">
      <value value="&quot;Generalizacao do Comportamento Racional&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="N-mice">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="energyLabel?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="smartMice?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="energia?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="traps?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="come?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="startEnergy?">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="poisonedFood?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="food?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maxFood?">
      <value value="100"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Traps" repetitions="500" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles</metric>
    <metric>count mice</metric>
    <metric>count cats</metric>
    <metric>ticks</metric>
    <metric>count mice with [tipo = "friendly"]</metric>
    <metric>count mice with [tipo = "loner"]</metric>
    <metric>count patches with [pcolor = white]</metric>
    <metric>count patches with [pcolor = green]</metric>
    <metric>count patches with [pcolor = yellow]</metric>
    <enumeratedValueSet variable="breed?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maxTick?">
      <value value="1500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="N-cats">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="smartCats?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="especies?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Modelo">
      <value value="&quot;Generalizacao do Comportamento Racional&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="N-mice">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="energyLabel?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="smartMice?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="energia?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="traps?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="come?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="startEnergy?">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="poisonedFood?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="food?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maxFood?">
      <value value="100"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="EspeciesRatos" repetitions="500" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles</metric>
    <metric>count mice</metric>
    <metric>count cats</metric>
    <metric>ticks</metric>
    <metric>count mice with [tipo = "friendly"]</metric>
    <metric>count mice with [tipo = "loner"]</metric>
    <metric>count patches with [pcolor = white]</metric>
    <metric>count patches with [pcolor = green]</metric>
    <metric>count patches with [pcolor = yellow]</metric>
    <enumeratedValueSet variable="breed?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maxTick?">
      <value value="1500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="N-cats">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="smartCats?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="especies?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Modelo">
      <value value="&quot;Generalizacao do Comportamento Racional&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="N-mice">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="energyLabel?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="smartMice?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="energia?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="traps?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="come?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="startEnergy?">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="poisonedFood?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="food?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maxFood?">
      <value value="100"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Reproducao" repetitions="500" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles</metric>
    <metric>count mice</metric>
    <metric>count cats</metric>
    <metric>ticks</metric>
    <metric>count mice with [tipo = "friendly"]</metric>
    <metric>count mice with [tipo = "loner"]</metric>
    <metric>count patches with [pcolor = white]</metric>
    <metric>count patches with [pcolor = green]</metric>
    <metric>count patches with [pcolor = yellow]</metric>
    <enumeratedValueSet variable="breed?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maxTick?">
      <value value="1500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="N-cats">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="smartCats?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="especies?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Modelo">
      <value value="&quot;Generalizacao do Comportamento Racional&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="N-mice">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="energyLabel?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="smartMice?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="energia?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="traps?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="come?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="startEnergy?">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="poisonedFood?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="food?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maxFood?">
      <value value="100"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="canibalismo" repetitions="500" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles</metric>
    <metric>count mice</metric>
    <metric>count cats</metric>
    <metric>ticks</metric>
    <metric>count mice with [tipo = "friendly"]</metric>
    <metric>count mice with [tipo = "loner"]</metric>
    <metric>count patches with [pcolor = white]</metric>
    <metric>count patches with [pcolor = green]</metric>
    <metric>count patches with [pcolor = yellow]</metric>
    <enumeratedValueSet variable="breed?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maxTick?">
      <value value="1500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="N-cats">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="smartCats?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="especies?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Modelo">
      <value value="&quot;Generalizacao do Comportamento Racional&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="N-mice">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="energyLabel?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="smartMice?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="energia?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="traps?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="come?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="startEnergy?">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="poisonedFood?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="food?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maxFood?">
      <value value="100"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Alimentos" repetitions="500" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles</metric>
    <metric>count mice</metric>
    <metric>count cats</metric>
    <metric>ticks</metric>
    <metric>count mice with [tipo = "friendly"]</metric>
    <metric>count mice with [tipo = "loner"]</metric>
    <metric>count patches with [pcolor = white]</metric>
    <metric>count patches with [pcolor = green]</metric>
    <metric>count patches with [pcolor = yellow]</metric>
    <enumeratedValueSet variable="breed?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maxTick?">
      <value value="1500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="N-cats">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="smartCats?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="especies?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Modelo">
      <value value="&quot;Generalizacao do Comportamento Racional&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="N-mice">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="energyLabel?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="smartMice?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="energia?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="traps?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="come?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="startEnergy?">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="poisonedFood?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="food?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maxFood?">
      <value value="100"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="TUDO" repetitions="500" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles</metric>
    <metric>count mice</metric>
    <metric>count cats</metric>
    <metric>ticks</metric>
    <metric>count mice with [tipo = "friendly"]</metric>
    <metric>count mice with [tipo = "loner"]</metric>
    <metric>count patches with [pcolor = white]</metric>
    <metric>count patches with [pcolor = green]</metric>
    <metric>count patches with [pcolor = yellow]</metric>
    <enumeratedValueSet variable="breed?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maxTick?">
      <value value="1500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="N-cats">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="smartCats?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="especies?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Modelo">
      <value value="&quot;Generalizacao do Comportamento Racional&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="N-mice">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="energyLabel?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="smartMice?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="energia?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="traps?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="come?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="startEnergy?">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="poisonedFood?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="food?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maxFood?">
      <value value="100"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Come" repetitions="500" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles</metric>
    <metric>count mice</metric>
    <metric>count cats</metric>
    <metric>ticks</metric>
    <metric>count mice with [tipo = "friendly"]</metric>
    <metric>count mice with [tipo = "loner"]</metric>
    <metric>count patches with [pcolor = white]</metric>
    <metric>count patches with [pcolor = green]</metric>
    <metric>count patches with [pcolor = yellow]</metric>
    <enumeratedValueSet variable="breed?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maxTick?">
      <value value="1500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="N-cats">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="smartCats?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="especies?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Modelo">
      <value value="&quot;Generalizacao do Comportamento Racional&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="N-mice">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="energyLabel?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="smartMice?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="energia?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="traps?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="come?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="startEnergy?">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="poisonedFood?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="food?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maxFood?">
      <value value="100"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
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
