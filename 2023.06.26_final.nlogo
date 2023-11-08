; ------------------------------------------------------------ ;
; Authors: Grace Brophy, Audrey Rips-Goodwin, and Lucy Wilson  ;
; Date: June 26th, 2023                                        ;
; File Name: 2023.06.23_final                                  ;
; Purpose: A working ABM simulating voter turnout in a         ;
;          2-party political system with a political spectrum. ;
; ------------------------------------------------------------ ;

; attributes known to all agents, patches, and procedures
globals
[
  demo-data ;; list of probabilities imported from a file
  party-data ;; list of party affiliations imported from a file
  count-blue ;; final count of blue voters in the election
  count-red ;; final count of red voters in the election
  count-total ;; final count of all voters in the election
  count-non ;; final count of non-voters in the election
  blue-vals ;; subset of blue voters in party-data
  blue-demo ;; subset of demo-data corresponding to blue-vals
  red-vals ;; subset of red voters in party-data
  red-demo ;; subset of demo-data corresponding to red-vals
]

; attributes known to all agents
turtles-own
[
  party ;; represents party affiliation
  party-cat ;; categorical party boolean
  similarity ;; percentage of like-minded people in a given radius
  radius ;; an agent's radius of "neighbors"
  demo-prob ;; probability of voting based on demographics
  comm-prob ;; probability of voting based on community
  vote-prob ;; result of a linear combo of demo-prob and comm-prob
]

; ------------------------------------------------------------ ;
;                          SETUP PHASE                         ;
; ------------------------------------------------------------ ;

; assigns color to an agent's patch based on ranges of party values
to assign-color

  if (0 < party and party <= 0.143)
  [ set pcolor 103 ] ;; dark blue

  if (0.143 < party and party <= 0.286)
  [ set pcolor 106 ] ;; lighter blue

  if (0.286 < party and party <= 0.429)
  [ set pcolor 108 ] ;; moderate, leaning blue

  if (0.429 < party and party <= 0.572)
  [ set pcolor 8.5 ] ;; moderate, true purple

  if (0.572 < party and party <= 0.715)
  [ set pcolor 18 ] ;; moderate, leaning red

  if (0.715 < party and party <= 0.858)
  [ set pcolor 16 ] ;; lighter red

  if (0.858 < party and party <= 1.0)
  [ set pcolor 13 ] ;; dark red
end

; creates a number of cluster seeds with party values from the
; party distribution list from an input file
to create-cluster-seeds

  let n 0
  while [n < 26] ;; assign all cluster seeds (26 is 1% of total pop for seeds)
  [
    let k random (length party-data - 1) ;; pick a random index in the list
    let val item k party-data ;; value at the given index
    let demo-val item k demo-data ;; same index for demographic
    ask one-of turtles with [party = -1] ;; one of the uninitialized agents
    [
      set party val ;; set party as the value at the selected index
      set demo-prob demo-val
    ]

    set party-data remove-item k party-data ;; remove that item from the list
    set demo-data remove-item k demo-data ;; remove the same index from demo
    set n n + 1 ;; increment loop counter
  ]
end

; randomly picks a party value and corresponding demographic probability
; within the blue party subset and removes the items from the lists
to update-blue-subset

  let k random (length blue-vals - 1)
  set party item k blue-vals
  set demo-prob item k blue-demo
  set blue-vals remove-item k blue-vals
  set blue-demo remove-item k blue-demo
end

; randomly picks a party value and corresponding demographic probability
; within the red party subset and removes the items from the lists
to update-red-subset

  let k random (length red-vals - 1)
  set party item k red-vals
  set demo-prob item k red-demo
  set red-vals remove-item k red-vals
  set red-demo remove-item k red-demo
end

; grows party clusters around initialized cluster seeds
to grow-clusters

  ask turtles with [party = -1] ;; consider all uninitialized agents
  [
    ;; pick an agent with an assigned party who is closest
    ;; to the agent being considered
    let closest-agent min-one-of turtles with [party != -1] [distance myself]
    let z random-float 1.0 ;; prob that an agent aligns with its closest agent
    let closest-party [party] of closest-agent

    ifelse (z < degree-clustered) ;; will the agent match its neighbor?
    [ ;; same party
      ifelse (closest-party <= 0.5)
      [ ;; blue
        if (length blue-vals != 0)
        [update-blue-subset]
      ]
      [ ;; red
        if (length red-vals != 0)
        [update-red-subset]
      ]
    ]
    [ ;; different party
      ifelse (closest-party <= 0.5)
      [ ;; red
        if (length red-vals != 0)
        [update-red-subset]
       ]
      [ ;; blue
        if (length blue-vals != 0)
        [update-blue-subset]
      ]
    ]
  ]
end

; assigns remaining agents following the grow-clusters procedure
to assign-remainder

 ifelse (length blue-vals = 0)
 [
  let n length red-vals
  while [n > 0]
  [
    let k random (length red-vals - 1) ;; pick a random index in the list
    let val item k red-vals ;; value at the given index
    let demo-val item k red-demo ;; same index for demographic
    ask one-of turtles with [party = -1] ;; one of the uninitialized agents
    [
      set party val ;; set party as the value at the selected index
      set demo-prob demo-val
    ]
    set red-vals remove-item k red-vals ;; remove that item from the list
    set red-demo remove-item k red-demo ;; remove the same index from demo
    set n n - 1 ;; decrement loop counter
  ]
 ]
 [
  let n length blue-vals
  while [n > 0]
  [
    let k random (length blue-vals - 1) ;; pick a random index in the list
    let val item k blue-vals ;; value at the given index
    let demo-val item k blue-demo ;; same index for demographic
    ask one-of turtles with [party = -1] ;; one of the uninitialized agents
    [
      set party val ;; set party as the value at the selected index
      set demo-prob demo-val
    ]
    set blue-vals remove-item k blue-vals ;; remove that item from the list
    set blue-demo remove-item k blue-demo ;; remove the same index from demo
    set n n - 1 ;; decrement loop counter
  ]
 ]
end

; divides party affiliation and demographic data into red and blue
; subsets after cluster leaders have been initialized
to initialize-party-subsets

  set blue-vals []
  set blue-demo []
  set red-vals []
  set red-demo []
  let i 0 ;; index counter

  foreach party-data
  [ x ->
    ifelse (0 < x and x <= 0.5) ;; check which party
    [ ;; blue
      set blue-vals lput x blue-vals
      set blue-demo lput (item i demo-data) blue-demo
    ]
    [ ;; red
      set red-vals lput x red-vals
      set red-demo lput (item i demo-data) red-demo
    ]
    set i i + 1 ;; increment
  ]
end

; creates clusters based on user-specified level of mixing
; @param degree-clustered: the probability an agent will align with its neighbor's party
to create-clusters

  ask turtles [set party -1] ;; initialize party values out of range
  create-cluster-seeds
  initialize-party-subsets
  grow-clusters
  assign-remainder
  ask turtles [assign-color] ;; clustered party values are set
end

; assign party attributes of agents
to initialize-attributes

  set size 0 ;; arbitrary agent size
  set radius random-normal mean-radius (2 / 3) ;; radius of who each agent talks to
end

; gives all agents a boolean party value based on their numerical one
to initialize-party-cat

  ifelse (party <= 0.5)
  [ set party-cat true ]
  [ set party-cat false ]
end

; reports the filename depending on the party split scenario selected
; @return the filename to be read in from
to-report set-filename

  let filename ""

  if (party-split = "Strong Blue Majority")
  [ set filename "strong_blue.txt" ]


  if (party-split = "Partial Blue Majority")
  [ set filename "partial_blue.txt" ]

  if (party-split = "No Majority")
  [ set filename "no_majority.txt" ]

  if (party-split = "Partial Red Majority")
  [ set filename "partial_red.txt" ]

  if (party-split = "Strong Red Majority")
  [ set filename "strong_red.txt" ]

  report filename
end

; loads in probability and party affiliation data from the proper file
to load-file-data

  let filename set-filename ;; get the correct file based on party split

  ; check for file existence
  ifelse (file-exists? filename)
  [
    set demo-data [] ;; initialize as a list
    set party-data []
    file-open filename ;; open the file

    ; read in from the file until the end is reached
    while [not file-at-end?]
    [ ;; add file information to the list
      set demo-data lput file-read demo-data
      set party-data lput file-read party-data
    ]
    file-close
  ]
  [ user-message "There is no such file in current directory!" ]
end

; creates a histogram based on continuous party values of agents
to display-party-split

  set-current-plot "Party Split"
  set-histogram-num-bars 25
  histogram [party] of turtles
end

; runs when the setup button is pressed on the interface
to setup

  ca ;; clear all

  ask n-of 2601 patches [sprout 1] ;; spawn 1 agent per patch
  ask turtles [initialize-attributes]
  load-file-data ;; demographic probabilities and correspondong party affiliation
  create-clusters
  ask turtles [initialize-party-cat]
  display-party-split

  reset-ticks ;; resets the tick count each time world is set up
end

; ------------------------------------------------------------ ;
;                          GO PHASE                            ;
; ------------------------------------------------------------ ;

; helper function for check-neighbors to set a agent's community probability
to set-comm-prob

  let x similarity

  ;; which effect are we implementing to decide community probability?
  ifelse ( comm-effect = "Competition Effect" )
  [ ;; competition effect (arbitrary parameters): parabolic
    set comm-prob ((((x - 0.5) ^ 2) / -0.25) + 1)
  ]
  [ ;; underdog effect (arbitrary parameters): sigmoid
    set comm-prob (1 + ((-1) / (1 + (6 * exp (-20 * ( x - 0.6 ))))))
  ]

  set-current-plot "Community Probability"
  plotxy similarity comm-prob
end

; allows a given agent to inspect a specified number of neighbors
to check-neighbors

  let my-avg 0
  let total-avg 0

  while [count turtles in-radius radius <= 1]
  [
    set radius random-normal mean-radius (2 / 3)
  ]

  ask turtles in-radius radius
  [
    let y party
    if (party-cat)
    [ set y (1 - party) ] ;; adjust for weighting for blue party

    if (self != myself)
    [ ;; don't include agent doing the checking

      if ([party-cat] of self = [party-cat] of myself) ;; include in my average?
      [ set my-avg my-avg + y ]

      set total-avg total-avg + y
    ]
  ]
  set similarity (my-avg / total-avg)
  set-comm-prob ;; sets the community probability of an agent based on a phenomenon
end

; sets the agent's overall probability of voting as a
; linear combination of demo-prob and comm-prob
to set-vote-prob

    set vote-prob ((a * demo-prob) + ((1 - a) * comm-prob))
end

; reports the results of the election to the interface:
; who won and with how many votes
; @return: the winner of the election and the number of votes
to-report results

  ;; check which party has the higher vote tally
  ifelse (count-blue > count-red)
  [
    report  (word "The blue party wins with " count-blue " votes.")
  ]
  [ ;; account for a possible tie
    ifelse (count-blue = count-red)
    [
      report (word "It's a tie! Both parties have " count-blue " votes.")
    ]
    [
      report (word "The red party wins with " count-red " votes.")
    ]
  ]
end

; reports the overall voter turnout from the election
; @return: the voter turnout from the election
to-report turnout

  let percentage round (100 * count-total / count turtles)
  report (word "The voter turnout was " percentage "%.")
end

; runs the election of the agents based on their vote-prob and reports outputs
; when the interface button is pressed
to elect

  set count-red 0
  set count-blue 0
  set count-total 0
  set count-non 0

  ask turtles [
    set-vote-prob ;; set its overall vote-prob
    let rand-num random-float 1.0 ;; pick a random number for each agent

    ; if the number generated is less than or equal to their voting probability,
    ; the agent voted
    ifelse (rand-num <= vote-prob)
    [ ; voted: check the agent's party to increment the appropriate tally
      ifelse (party-cat)
      [ set count-blue (count-blue + 1) ] ;; increment blue count
      [ set count-red (count-red + 1) ] ;; increment red count

      set count-total (count-total + 1) ;; update the count total - still voted
    ]
    [ ; did not vote: color the patch black and increment the appropriate tally
      set pcolor black
      set count-non (count-non + 1)
    ]
  ]

  output-print results ;; output the results to the interface
  output-print turnout ;; output the voter turnout to the interface
end

; runs when the interface button is pressed to control pre-election procedures
to go

  tick
  ask turtles [check-neighbors] ;; agents survey who's around them
end
@#$#@#$#@
GRAPHICS-WINDOW
91
17
507
434
-1
-1
8.0
1
10
1
1
1
0
1
1
1
-25
25
-25
25
0
0
1
ticks
30.0

BUTTON
11
17
77
50
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
11
62
77
95
NIL
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

PLOT
523
16
782
195
Community Probability
similarity
comm-prob
0.0
1.0
0.0
1.0
true
false
"" ""
PENS
"default" 1.0 2 -16777216 true "" ""

SLIDER
93
441
265
474
a
a
0
1
1.0
0.1
1
NIL
HORIZONTAL

OUTPUT
523
392
792
459
13

CHOOSER
277
486
449
531
comm-effect
comm-effect
"Competition Effect" "Underdog Effect"
1

PLOT
523
208
781
377
Party Split
affiliation
frequency
0.0
1.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 1 -16777216 true "" ""

CHOOSER
93
486
266
531
party-split
party-split
"Strong Blue Majority" "Partial Blue Majority" "No Majority" "Partial Red Majority" "Strong Red Majority"
0

BUTTON
11
108
77
141
elect
elect
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

SLIDER
277
441
449
474
degree-clustered
degree-clustered
0.5
1
1.0
0.01
1
NIL
HORIZONTAL

CHOOSER
461
486
599
531
mean-radius
mean-radius
4 5 6
2

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
NetLogo 6.3.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="comp_total_varying_a_and_degclustered" repetitions="10" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go
elect</go>
    <timeLimit steps="1"/>
    <metric>round 100 * (count-total / count turtles)</metric>
    <steppedValueSet variable="degree-clustered" first="0.5" step="0.05" last="1"/>
    <enumeratedValueSet variable="party-split">
      <value value="&quot;Majority&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean-radius">
      <value value="5"/>
    </enumeratedValueSet>
    <steppedValueSet variable="a" first="0" step="0.1" last="1"/>
    <enumeratedValueSet variable="comm-effect">
      <value value="&quot;Competition Effect&quot;"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="udog_total_varying_a_and_degclustered" repetitions="10" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go
elect</go>
    <timeLimit steps="1"/>
    <metric>round 100 * (count-total / count turtles)</metric>
    <steppedValueSet variable="degree-clustered" first="0.5" step="0.05" last="1"/>
    <enumeratedValueSet variable="party-split">
      <value value="&quot;Majority&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean-radius">
      <value value="5"/>
    </enumeratedValueSet>
    <steppedValueSet variable="a" first="0" step="0.1" last="1"/>
    <enumeratedValueSet variable="comm-effect">
      <value value="&quot;Underdog Effect&quot;"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="terminal test" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go
elect</go>
    <timeLimit steps="1"/>
    <metric>count turtles</metric>
    <enumeratedValueSet variable="degree-clustered">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="party-split">
      <value value="&quot;Majority&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean-radius">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="comm-effect">
      <value value="&quot;Underdog Effect&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="a">
      <value value="1"/>
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
