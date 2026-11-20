module View exposing (view)

import Html exposing (Html)
import Html.Attributes as HA
import Svg exposing (..)
import Svg.Attributes as SA
import Svg.Events exposing (onClick)
import Types exposing (..)


view : Model -> Html Msg
view model =
    Html.div
        [ HA.style "width" "100%"
        , HA.style "display" "flex"
        , HA.style "justify-content" "center"
        ]
        [ svg
            [ SA.viewBox "0 0 800 600"
            , SA.width "800"
            , SA.height "600"
            ]
            (List.concat
                [ [ viewDefs ]
                , viewBackground
                , List.map viewLadder model.level.ladders
                , List.map viewPlatform model.level.platforms
                , List.map viewLiftGuide model.level.lifts
                , List.map (viewLift model.animClock model.player.onLiftId) model.level.lifts
                , List.map (viewHazard model.animClock) model.level.hazards
                , List.map (viewSeed model.animClock) (List.filter (not << .collected) model.level.seeds)
                , List.map (viewEgg model.animClock) (List.filter (not << .collected) model.level.eggs)
                , List.map viewEnemy model.level.enemies
                , [ viewPlayer model ]
                , List.map viewParticle model.particles
                , List.map viewPopup model.popups
                , [ viewHud model ]
                , viewOverlay model
                , [ viewScanlines ]
                ]
            )
        ]



-- SVG DEFS (GRADIENTS, FILTERS, PATTERNS)


viewDefs : Svg Msg
viewDefs =
    defs []
        [ -- Atmospheric midnight background gradient
          linearGradient [ SA.id "bgGrad", SA.x1 "0%", SA.y1 "0%", SA.x2 "0%", SA.y2 "100%" ]
            [ stop [ SA.offset "0%", SA.stopColor "#070b18" ] []
            , stop [ SA.offset "52%", SA.stopColor "#101935" ] []
            , stop [ SA.offset "100%", SA.stopColor "#070a14" ] []
            ]
        , -- Soft ambient center glow
          radialGradient [ SA.id "ambientGlow", SA.cx "50%", SA.cy "42%", SA.r "55%" ]
            [ stop [ SA.offset "0%", SA.stopColor "#1e3a5f", SA.stopOpacity "0.28" ] []
            , stop [ SA.offset "60%", SA.stopColor "#0f172a", SA.stopOpacity "0.08" ] []
            , stop [ SA.offset "100%", SA.stopColor "#070a14", SA.stopOpacity "0" ] []
            ]
        , -- HUD dark metallic bezel gradient
          linearGradient [ SA.id "hudBgGrad", SA.x1 "0%", SA.y1 "0%", SA.x2 "0%", SA.y2 "100%" ]
            [ stop [ SA.offset "0%", SA.stopColor "#0b1124" ] []
            , stop [ SA.offset "45%", SA.stopColor "#151e38" ] []
            , stop [ SA.offset "100%", SA.stopColor "#090e1d" ] []
            ]
        , -- Industrial steel/teal girder gradient
          linearGradient [ SA.id "girderGrad", SA.x1 "0%", SA.y1 "0%", SA.x2 "0%", SA.y2 "100%" ]
            [ stop [ SA.offset "0%", SA.stopColor "#164e63" ] []
            , stop [ SA.offset "45%", SA.stopColor "#0f3d4c" ] []
            , stop [ SA.offset "100%", SA.stopColor "#082430" ] []
            ]
        , -- Metallic lift deck gradient (idle)
          linearGradient [ SA.id "liftGrad", SA.x1 "0%", SA.y1 "0%", SA.x2 "0%", SA.y2 "100%" ]
            [ stop [ SA.offset "0%", SA.stopColor "#f472b6" ] []
            , stop [ SA.offset "35%", SA.stopColor "#db2777" ] []
            , stop [ SA.offset "100%", SA.stopColor "#831843" ] []
            ]
        , -- Metallic lift deck gradient (energized when player rides it)
          linearGradient [ SA.id "liftEnergizedGrad", SA.x1 "0%", SA.y1 "0%", SA.x2 "0%", SA.y2 "100%" ]
            [ stop [ SA.offset "0%", SA.stopColor "#fdf2f8" ] []
            , stop [ SA.offset "30%", SA.stopColor "#f472b6" ] []
            , stop [ SA.offset "100%", SA.stopColor "#be185d" ] []
            ]
        , -- Golden 3D egg radial gradient
          radialGradient [ SA.id "eggGrad", SA.cx "50%", SA.cy "50%", SA.r "55%", SA.fx "34%", SA.fy "28%" ]
            [ stop [ SA.offset "0%", SA.stopColor "#fefce8" ] []
            , stop [ SA.offset "32%", SA.stopColor "#fde047" ] []
            , stop [ SA.offset "74%", SA.stopColor "#eab308" ] []
            , stop [ SA.offset "100%", SA.stopColor "#a16207" ] []
            ]
        , -- Egg soft golden halo
          radialGradient [ SA.id "eggHaloGrad", SA.cx "50%", SA.cy "50%", SA.r "50%" ]
            [ stop [ SA.offset "0%", SA.stopColor "#fde047", SA.stopOpacity "0.5" ] []
            , stop [ SA.offset "65%", SA.stopColor "#f59e0b", SA.stopOpacity "0.14" ] []
            , stop [ SA.offset "100%", SA.stopColor "#f59e0b", SA.stopOpacity "0" ] []
            ]
        , -- Hazard molten plasma gradient
          linearGradient [ SA.id "hazardPlasmaGrad", SA.x1 "0%", SA.y1 "0%", SA.x2 "0%", SA.y2 "100%" ]
            [ stop [ SA.offset "0%", SA.stopColor "#fb923c" ] []
            , stop [ SA.offset "30%", SA.stopColor "#ef4444" ] []
            , stop [ SA.offset "75%", SA.stopColor "#991b1b" ] []
            , stop [ SA.offset "100%", SA.stopColor "#450a0a" ] []
            ]
        , -- Metallic spike gradient
          linearGradient [ SA.id "spikeGrad", SA.x1 "0%", SA.y1 "0%", SA.x2 "100%", SA.y2 "100%" ]
            [ stop [ SA.offset "0%", SA.stopColor "#f8fafc" ] []
            , stop [ SA.offset "35%", SA.stopColor "#cbd5e1" ] []
            , stop [ SA.offset "70%", SA.stopColor "#64748b" ] []
            , stop [ SA.offset "100%", SA.stopColor "#334155" ] []
            ]
        , -- Soft neon glow filter
          filter [ SA.id "glowSoft", SA.x "-35%", SA.y "-35%", SA.width "170%", SA.height "170%" ]
            [ feGaussianBlur [ SA.stdDeviation "3.2", SA.result "coloredBlur" ] []
            , feMerge []
                [ feMergeNode [ SA.in_ "coloredBlur" ] []
                , feMergeNode [ SA.in_ "SourceGraphic" ] []
                ]
            ]
        , -- Caution stripes pattern (yellow & dark charcoal)
          pattern [ SA.id "cautionPattern", SA.width "10", SA.height "10", SA.patternUnits "userSpaceOnUse" ]
            [ rect [ SA.x "0", SA.y "0", SA.width "10", SA.height "10", SA.fill "#111827" ] []
            , polygon [ SA.points "0,10 5,0 10,0 5,10", SA.fill "#facc15" ] []
            ]
        , -- Subtle CRT scanlines pattern
          pattern [ SA.id "scanlinePattern", SA.width "4", SA.height "4", SA.patternUnits "userSpaceOnUse" ]
            [ rect [ SA.x "0", SA.y "0", SA.width "4", SA.height "2", SA.fill "#000000" ] []
            ]
        ]



-- BACKGROUND ARCHITECTURE (BARN / HENHOUSE RAFTERS & SILHOUETTES)


viewBackground : List (Svg Msg)
viewBackground =
    let
        vGrid =
            List.range 1 15
                |> List.map
                    (\i ->
                        let
                            px =
                                String.fromInt (i * 50)
                        in
                        line
                            [ SA.x1 px
                            , SA.y1 "56"
                            , SA.x2 px
                            , SA.y2 "600"
                            , SA.stroke "#1e293b"
                            , SA.strokeOpacity "0.24"
                            , SA.strokeWidth "1"
                            ]
                            []
                    )

        hGrid =
            List.range 2 11
                |> List.map
                    (\i ->
                        let
                            py =
                                String.fromInt (i * 50)
                        in
                        line
                            [ SA.x1 "0"
                            , SA.y1 py
                            , SA.x2 "800"
                            , SA.y2 py
                            , SA.stroke "#1e293b"
                            , SA.strokeOpacity "0.24"
                            , SA.strokeWidth "1"
                            ]
                            []
                    )

        barnWindow wx wy =
            g [ SA.opacity "0.28" ]
                [ rect [ SA.x (String.fromFloat wx), SA.y (String.fromFloat wy), SA.width "56", SA.height "68", SA.rx "4", SA.fill "#1e3a5f", SA.stroke "#334155", SA.strokeWidth "3" ] []
                , line [ SA.x1 (String.fromFloat (wx + 28)), SA.y1 (String.fromFloat wy), SA.x2 (String.fromFloat (wx + 28)), SA.y2 (String.fromFloat (wy + 68)), SA.stroke "#0f172a", SA.strokeWidth "3" ] []
                , line [ SA.x1 (String.fromFloat wx), SA.y1 (String.fromFloat (wy + 34)), SA.x2 (String.fromFloat (wx + 56)), SA.y2 (String.fromFloat (wy + 34)), SA.stroke "#0f172a", SA.strokeWidth "3" ] []
                ]
    in
    [ -- Base midnight gradient + ambient light
      rect [ SA.x "0", SA.y "0", SA.width "800", SA.height "600", SA.fill "url(#bgGrad)" ] []
    , rect [ SA.x "0", SA.y "54", SA.width "800", SA.height "546", SA.fill "url(#ambientGlow)" ] []
    , -- Distant barn rafters & A-frame roof silhouette
      g [ SA.opacity "0.35" ]
        [ -- Roof peak beams
          polygon [ SA.points "0,145 400,54 800,145 800,164 400,74 0,164", SA.fill "#0b1329" ] []
        , -- Horizontal loft collar beam
          rect [ SA.x "0", SA.y "142", SA.width "800", SA.height "12", SA.fill "#091024" ] []
        , -- Vertical timber support columns
          rect [ SA.x "12", SA.y "54", SA.width "14", SA.height "546", SA.fill "#080f22" ] []
        , rect [ SA.x "774", SA.y "54", SA.width "14", SA.height "546", SA.fill "#080f22" ] []
        , rect [ SA.x "224", SA.y "150", SA.width "10", SA.height "450", SA.fill "#0a1228" ] []
        , rect [ SA.x "566", SA.y "150", SA.width "10", SA.height "450", SA.fill "#0a1228" ] []
        , -- Diagonal timber braces
          line [ SA.x1 "26", SA.y1 "210", SA.x2 "90", SA.y2 "150", SA.stroke "#0b142c", SA.strokeWidth "8" ] []
        , line [ SA.x1 "774", SA.y1 "210", SA.x2 "710", SA.y2 "150", SA.stroke "#0b142c", SA.strokeWidth "8" ] []
        , line [ SA.x1 "234", SA.y1 "210", SA.x2 "290", SA.y2 "150", SA.stroke "#0b142c", SA.strokeWidth "6" ] []
        , line [ SA.x1 "566", SA.y1 "210", SA.x2 "510", SA.y2 "150", SA.stroke "#0b142c", SA.strokeWidth "6" ] []
        ]
    , -- Subtle moonlight barn windows
      barnWindow 96 250
    , barnWindow 372 255
    , barnWindow 648 250
    ]
        ++ vGrid
        ++ hGrid


viewScanlines : Svg Msg
viewScanlines =
    rect
        [ SA.x "0"
        , SA.y "0"
        , SA.width "800"
        , SA.height "600"
        , SA.fill "url(#scanlinePattern)"
        , SA.opacity "0.06"
        , SA.style "pointer-events: none;"
        ]
        []



-- POLISHED ARCADE HUD


viewHud : Model -> Svg Msg
viewHud model =
    let
        eggsRemaining =
            model.level.eggs
                |> List.filter (not << .collected)
                |> List.length

        bonusFrac =
            Basics.clamp 0 1 (model.bonusTimer / 100.0)

        bonusColor =
            if model.bonusTimer < 25 then
                "#f43f5e"

            else if model.bonusTimer < 45 then
                "#fb923c"

            else
                "#facc15"

        bonusBarWidth =
            92.0 * bonusFrac

        livesCount =
            Basics.clamp 0 5 model.lives

        livesIcons =
            List.range 0 (livesCount - 1)
                |> List.map (\i -> viewMiniCap (676 + toFloat i * 23) 34)

        divider dx =
            line
                [ SA.x1 (String.fromFloat dx)
                , SA.y1 "8"
                , SA.x2 (String.fromFloat dx)
                , SA.y2 "46"
                , SA.stroke "#1e293b"
                , SA.strokeWidth "1.5"
                ]
                []
    in
    g []
        [ -- Inset dark bezel background
          rect [ SA.x "0", SA.y "0", SA.width "800", SA.height "54", SA.fill "url(#hudBgGrad)" ] []
        , rect [ SA.x "0", SA.y "0", SA.width "800", SA.height "2", SA.fill "#334155", SA.opacity "0.5" ] []
        , -- Neon teal bottom divider with soft glow
          line [ SA.x1 "0", SA.y1 "53", SA.x2 "800", SA.y2 "53", SA.stroke "#2dd4bf", SA.strokeWidth "2", SA.filter "url(#glowSoft)" ] []
        , line [ SA.x1 "0", SA.y1 "53", SA.x2 "800", SA.y2 "53", SA.stroke "#99f6e4", SA.strokeWidth "1" ] []
        , -- Section dividers
          divider 112
        , divider 222
        , divider 456
        , divider 572
        , divider 658
        , -- SCORE
          hudLabel "16" "18" "SCORE"
        , hudValue "16" "41" "#f8fafc" "18" (padScore model.score)
        , -- HI-SCORE
          hudLabel "124" "18" "HI-SCORE"
        , hudValue "124" "41" "#38bdf8" "18" (padScore model.highScore)
        , -- LEVEL
          hudLabel "234" "18" "STAGE"
        , hudValue "234" "40" "#2dd4bf" "13.5" model.level.name
        , -- BONUS + visual meter
          hudLabel "468" "18" "BONUS"
        , hudValue "526" "18" bonusColor "13" (String.fromInt (round model.bonusTimer))
        , rect [ SA.x "468", SA.y "28", SA.width "92", SA.height "11", SA.rx "3", SA.fill "#090d1a", SA.stroke "#334155", SA.strokeWidth "1" ] []
        , rect
            [ SA.x "470"
            , SA.y "30"
            , SA.width (String.fromFloat (Basics.max 0 (bonusBarWidth - 4)))
            , SA.height "7"
            , SA.rx "2"
            , SA.fill bonusColor
            ]
            []
        , -- EGGS remaining with mini egg icon
          hudLabel "584" "18" "EGGS"
        , viewMiniEgg 594 35
        , hudValue "609" "41" "#fde047" "17" ("x" ++ String.fromInt eggsRemaining)
        , -- LIVES with mini cap icons
          hudLabel "670" "18" "LIVES"
        , g [] livesIcons
        ]


viewMiniEgg : Float -> Float -> Svg Msg
viewMiniEgg ex ey =
    g []
        [ ellipse
            [ SA.cx (String.fromFloat ex)
            , SA.cy (String.fromFloat ey)
            , SA.rx "6"
            , SA.ry "8"
            , SA.fill "url(#eggGrad)"
            , SA.stroke "#b45309"
            , SA.strokeWidth "1.2"
            ]
            []
        , ellipse
            [ SA.cx (String.fromFloat (ex - 2))
            , SA.cy (String.fromFloat (ey - 2.5))
            , SA.rx "1.6"
            , SA.ry "2.6"
            , SA.fill "#fefce8"
            ]
            []
        ]


viewMiniCap : Float -> Float -> Svg Msg
viewMiniCap cxPos cyPos =
    g []
        [ -- Cap crown
          path
            [ SA.d
                ("M "
                    ++ String.fromFloat (cxPos - 7)
                    ++ " "
                    ++ String.fromFloat (cyPos + 2)
                    ++ " Q "
                    ++ String.fromFloat cxPos
                    ++ " "
                    ++ String.fromFloat (cyPos - 9)
                    ++ " "
                    ++ String.fromFloat (cxPos + 6)
                    ++ " "
                    ++ String.fromFloat (cyPos + 2)
                    ++ " Z"
                )
            , SA.fill "#38bdf8"
            , SA.stroke "#0369a1"
            , SA.strokeWidth "1.2"
            ]
            []
        , -- Cap visor
          rect
            [ SA.x (String.fromFloat (cxPos + 1))
            , SA.y (String.fromFloat (cyPos + 0.5))
            , SA.width "8.5"
            , SA.height "3"
            , SA.rx "1.5"
            , SA.fill "#0284c7"
            ]
            []
        , -- Gold cap badge
          circle
            [ SA.cx (String.fromFloat cxPos)
            , SA.cy (String.fromFloat (cyPos - 1.5))
            , SA.r "1.6"
            , SA.fill "#facc15"
            ]
            []
        ]


hudLabel : String -> String -> String -> Svg Msg
hudLabel tx ty label =
    text_
        [ SA.x tx
        , SA.y ty
        , SA.fill "#64748b"
        , SA.fontSize "10.5"
        , SA.fontFamily "Courier New, monospace"
        , SA.fontWeight "bold"
        , SA.letterSpacing "1"
        ]
        [ text label ]


hudValue : String -> String -> String -> String -> String -> Svg Msg
hudValue tx ty col sz label =
    text_
        [ SA.x tx
        , SA.y ty
        , SA.fill col
        , SA.fontSize sz
        , SA.fontFamily "Courier New, monospace"
        , SA.fontWeight "bold"
        ]
        [ text label ]


padScore : Int -> String
padScore n =
    String.padLeft 6 '0' (String.fromInt n)



-- INDUSTRIAL GIRDER PLATFORMS


viewPlatform : Platform -> Svg Msg
viewPlatform p =
    let
        trussStep =
            18.0

        trussCount =
            Basics.max 1 (floor ((p.width - 12) / trussStep))

        trussLines =
            List.range 0 (trussCount - 1)
                |> List.concatMap
                    (\i ->
                        let
                            xA =
                                p.x + 6 + toFloat i * trussStep

                            xB =
                                Basics.min (p.x + p.width - 6) (xA + trussStep)

                            yTop =
                                p.y + 4.5

                            yBot =
                                p.y + p.height - 2.5
                        in
                        [ line
                            [ SA.x1 (String.fromFloat xA)
                            , SA.y1 (String.fromFloat yBot)
                            , SA.x2 (String.fromFloat xB)
                            , SA.y2 (String.fromFloat yTop)
                            , SA.stroke "#155e75"
                            , SA.strokeWidth "1.8"
                            ]
                            []
                        , line
                            [ SA.x1 (String.fromFloat xA)
                            , SA.y1 (String.fromFloat yTop)
                            , SA.x2 (String.fromFloat xB)
                            , SA.y2 (String.fromFloat yBot)
                            , SA.stroke "#083344"
                            , SA.strokeWidth "1.4"
                            ]
                            []
                        ]
                    )

        rivetCount =
            Basics.max 2 (floor (p.width / 46) + 1)

        rivets =
            List.range 0 (rivetCount - 1)
                |> List.map
                    (\i ->
                        let
                            rxPos =
                                if i == 0 then
                                    p.x + 7

                                else if i == rivetCount - 1 then
                                    p.x + p.width - 7

                                else
                                    p.x + 7 + (p.width - 14) * (toFloat i / toFloat (rivetCount - 1))

                            ryPos =
                                p.y + p.height / 2 + 1
                        in
                        g []
                            [ circle [ SA.cx (String.fromFloat rxPos), SA.cy (String.fromFloat ryPos), SA.r "2.1", SA.fill "#061a24" ] []
                            , circle [ SA.cx (String.fromFloat (rxPos - 0.4)), SA.cy (String.fromFloat (ryPos - 0.4)), SA.r "1.1", SA.fill "#5eead4" ] []
                            ]
                    )
    in
    g []
        ([ -- Underside drop shadow
           rect
            [ SA.x (String.fromFloat (p.x + 2))
            , SA.y (String.fromFloat (p.y + 4))
            , SA.width (String.fromFloat p.width)
            , SA.height (String.fromFloat p.height)
            , SA.rx "3"
            , SA.fill "#020617"
            , SA.opacity "0.55"
            ]
            []
         , -- Main riveted steel/teal girder body
           rect
            [ SA.x (String.fromFloat p.x)
            , SA.y (String.fromFloat p.y)
            , SA.width (String.fromFloat p.width)
            , SA.height (String.fromFloat p.height)
            , SA.rx "2.5"
            , SA.fill "url(#girderGrad)"
            , SA.stroke "#06212c"
            , SA.strokeWidth "1.2"
            ]
            []
         ]
            ++ trussLines
            ++ [ -- Bottom steel flange
                 rect
                    [ SA.x (String.fromFloat (p.x + 1))
                    , SA.y (String.fromFloat (p.y + p.height - 3))
                    , SA.width (String.fromFloat (p.width - 2))
                    , SA.height "2.5"
                    , SA.fill "#061e29"
                    ]
                    []
               , -- Bright cyan top bevel
                 rect
                    [ SA.x (String.fromFloat p.x)
                    , SA.y (String.fromFloat p.y)
                    , SA.width (String.fromFloat p.width)
                    , SA.height "4"
                    , SA.rx "2"
                    , SA.fill "#2dd4bf"
                    ]
                    []
               , -- Specular highlight along top edge
                 line
                    [ SA.x1 (String.fromFloat (p.x + 3))
                    , SA.y1 (String.fromFloat (p.y + 1))
                    , SA.x2 (String.fromFloat (p.x + p.width - 3))
                    , SA.y2 (String.fromFloat (p.y + 1))
                    , SA.stroke "#ccfbf1"
                    , SA.strokeWidth "1"
                    , SA.opacity "0.85"
                    ]
                    []
               ]
            ++ rivets
        )



-- DETAILED WOODEN / BRASS LADDERS


viewLadder : Ladder -> Svg Msg
viewLadder lad =
    let
        rungCount =
            floor ((lad.bottomY - lad.topY - 8) / 16)

        leftRailX =
            lad.x + 5

        rightRailX =
            lad.x + lad.width - 5

        rungs =
            List.range 0 rungCount
                |> List.map
                    (\i ->
                        let
                            ry =
                                lad.topY + 8 + toFloat i * 16
                        in
                        g []
                            [ -- Rung shadow
                              rect
                                [ SA.x (String.fromFloat (leftRailX + 1))
                                , SA.y (String.fromFloat (ry + 1.5))
                                , SA.width (String.fromFloat (rightRailX - leftRailX - 2))
                                , SA.height "3.5"
                                , SA.rx "1.5"
                                , SA.fill "#090d1a"
                                , SA.opacity "0.55"
                                ]
                                []
                            , -- Wooden/brass rung
                              rect
                                [ SA.x (String.fromFloat (leftRailX + 1))
                                , SA.y (String.fromFloat ry)
                                , SA.width (String.fromFloat (rightRailX - leftRailX - 2))
                                , SA.height "3.5"
                                , SA.rx "1.5"
                                , SA.fill "#d97706"
                                , SA.stroke "#451a03"
                                , SA.strokeWidth "0.8"
                                ]
                                []
                            , -- Rung top highlight
                              line
                                [ SA.x1 (String.fromFloat (leftRailX + 2.5))
                                , SA.y1 (String.fromFloat (ry + 1))
                                , SA.x2 (String.fromFloat (rightRailX - 2.5))
                                , SA.y2 (String.fromFloat (ry + 1))
                                , SA.stroke "#fde68a"
                                , SA.strokeWidth "1"
                                , SA.opacity "0.85"
                                ]
                                []
                            ]
                    )

        rail rxPos =
            g []
                [ -- Dark outline
                  rect
                    [ SA.x (String.fromFloat (rxPos - 2.8))
                    , SA.y (String.fromFloat lad.topY)
                    , SA.width "5.6"
                    , SA.height (String.fromFloat (lad.bottomY - lad.topY))
                    , SA.rx "1.5"
                    , SA.fill "#451a03"
                    ]
                    []
                , -- Main wood/brass rail
                  rect
                    [ SA.x (String.fromFloat (rxPos - 1.9))
                    , SA.y (String.fromFloat lad.topY)
                    , SA.width "3.8"
                    , SA.height (String.fromFloat (lad.bottomY - lad.topY))
                    , SA.rx "1"
                    , SA.fill "#b45309"
                    ]
                    []
                , -- Warm gold highlight strip
                  line
                    [ SA.x1 (String.fromFloat (rxPos - 0.8))
                    , SA.y1 (String.fromFloat (lad.topY + 1))
                    , SA.x2 (String.fromFloat (rxPos - 0.8))
                    , SA.y2 (String.fromFloat (lad.bottomY - 1))
                    , SA.stroke "#fbbf24"
                    , SA.strokeWidth "1.1"
                    , SA.opacity "0.85"
                    ]
                    []
                ]
    in
    g [] (rungs ++ [ rail leftRailX, rail rightRailX ])



-- MECHANICAL MOVING LIFTS & PULLEY GUIDES


viewPulley : Float -> Float -> Svg Msg
viewPulley px py =
    g []
        [ circle [ SA.cx (String.fromFloat px), SA.cy (String.fromFloat py), SA.r "6", SA.fill "#1e293b", SA.stroke "#475569", SA.strokeWidth "1.8" ] []
        , circle [ SA.cx (String.fromFloat px), SA.cy (String.fromFloat py), SA.r "3.2", SA.fill "#0f172a", SA.stroke "#94a3b8", SA.strokeWidth "0.8" ] []
        , circle [ SA.cx (String.fromFloat px), SA.cy (String.fromFloat py), SA.r "1.5", SA.fill "#f472b6" ] []
        ]


viewLiftGuide : Lift -> Svg Msg
viewLiftGuide l =
    case l.axis of
        Vertical ->
            let
                leftCableX =
                    l.x + 12

                rightCableX =
                    l.x + l.width - 12

                topY =
                    l.minPos

                botY =
                    l.maxPos + l.height
            in
            g []
                [ -- Dual vertical hoist cables
                  line
                    [ SA.x1 (String.fromFloat leftCableX)
                    , SA.y1 (String.fromFloat topY)
                    , SA.x2 (String.fromFloat leftCableX)
                    , SA.y2 (String.fromFloat botY)
                    , SA.stroke "#334155"
                    , SA.strokeWidth "2"
                    ]
                    []
                , line
                    [ SA.x1 (String.fromFloat leftCableX)
                    , SA.y1 (String.fromFloat topY)
                    , SA.x2 (String.fromFloat leftCableX)
                    , SA.y2 (String.fromFloat botY)
                    , SA.stroke "#64748b"
                    , SA.strokeWidth "1"
                    , SA.strokeDasharray "4,4"
                    ]
                    []
                , line
                    [ SA.x1 (String.fromFloat rightCableX)
                    , SA.y1 (String.fromFloat topY)
                    , SA.x2 (String.fromFloat rightCableX)
                    , SA.y2 (String.fromFloat botY)
                    , SA.stroke "#334155"
                    , SA.strokeWidth "2"
                    ]
                    []
                , line
                    [ SA.x1 (String.fromFloat rightCableX)
                    , SA.y1 (String.fromFloat topY)
                    , SA.x2 (String.fromFloat rightCableX)
                    , SA.y2 (String.fromFloat botY)
                    , SA.stroke "#64748b"
                    , SA.strokeWidth "1"
                    , SA.strokeDasharray "4,4"
                    ]
                    []
                , -- Top & bottom pulley wheels
                  viewPulley leftCableX topY
                , viewPulley rightCableX topY
                , viewPulley leftCableX botY
                , viewPulley rightCableX botY
                ]

        Horizontal ->
            let
                topRailY =
                    l.y + 4

                botRailY =
                    l.y + l.height - 4

                leftX =
                    l.minPos

                rightX =
                    l.maxPos + l.width
            in
            g []
                [ -- Dual horizontal guide rails
                  line
                    [ SA.x1 (String.fromFloat leftX)
                    , SA.y1 (String.fromFloat topRailY)
                    , SA.x2 (String.fromFloat rightX)
                    , SA.y2 (String.fromFloat topRailY)
                    , SA.stroke "#334155"
                    , SA.strokeWidth "2"
                    ]
                    []
                , line
                    [ SA.x1 (String.fromFloat leftX)
                    , SA.y1 (String.fromFloat topRailY)
                    , SA.x2 (String.fromFloat rightX)
                    , SA.y2 (String.fromFloat topRailY)
                    , SA.stroke "#64748b"
                    , SA.strokeWidth "1"
                    , SA.strokeDasharray "5,4"
                    ]
                    []
                , line
                    [ SA.x1 (String.fromFloat leftX)
                    , SA.y1 (String.fromFloat botRailY)
                    , SA.x2 (String.fromFloat rightX)
                    , SA.y2 (String.fromFloat botRailY)
                    , SA.stroke "#334155"
                    , SA.strokeWidth "2"
                    ]
                    []
                , line
                    [ SA.x1 (String.fromFloat leftX)
                    , SA.y1 (String.fromFloat botRailY)
                    , SA.x2 (String.fromFloat rightX)
                    , SA.y2 (String.fromFloat botRailY)
                    , SA.stroke "#64748b"
                    , SA.strokeWidth "1"
                    , SA.strokeDasharray "5,4"
                    ]
                    []
                , -- Left & right end pulleys
                  viewPulley leftX (l.y + l.height / 2)
                , viewPulley rightX (l.y + l.height / 2)
                ]


viewLift : Float -> Maybe Int -> Lift -> Svg Msg
viewLift clock onLiftId l =
    let
        isRiding =
            onLiftId == Just l.id

        midX =
            l.x + l.width / 2

        midY =
            l.y + l.height / 2

        chevron =
            case l.axis of
                Vertical ->
                    if l.dir < 0 then
                        "▲"

                    else
                        "▼"

                Horizontal ->
                    if l.dir < 0 then
                        "◀"

                    else
                        "▶"

        pulseOpacity =
            String.fromFloat (0.55 + 0.35 * sin (clock * 10))
    in
    g []
        [ -- Energized bright aura when player is riding
          if isRiding then
            rect
                [ SA.x (String.fromFloat (l.x - 3))
                , SA.y (String.fromFloat (l.y - 3))
                , SA.width (String.fromFloat (l.width + 6))
                , SA.height (String.fromFloat (l.height + 6))
                , SA.rx "5"
                , SA.fill "none"
                , SA.stroke "#f472b6"
                , SA.strokeWidth "2.5"
                , SA.opacity pulseOpacity
                , SA.filter "url(#glowSoft)"
                ]
                []

          else
            g [] []
        , -- Drop shadow
          rect
            [ SA.x (String.fromFloat (l.x + 1))
            , SA.y (String.fromFloat (l.y + 3))
            , SA.width (String.fromFloat l.width)
            , SA.height (String.fromFloat l.height)
            , SA.rx "3"
            , SA.fill "#020617"
            , SA.opacity "0.55"
            ]
            []
        , -- Main magenta/pink metallic lift deck
          rect
            [ SA.x (String.fromFloat l.x)
            , SA.y (String.fromFloat l.y)
            , SA.width (String.fromFloat l.width)
            , SA.height (String.fromFloat l.height)
            , SA.rx "3"
            , SA.fill
                (if isRiding then
                    "url(#liftEnergizedGrad)"

                 else
                    "url(#liftGrad)"
                )
            , SA.stroke
                (if isRiding then
                    "#fbcfe8"

                 else
                    "#500724"
                )
            , SA.strokeWidth "1.2"
            ]
            []
        , -- Caution stripes along the bottom rim
          rect
            [ SA.x (String.fromFloat (l.x + 2))
            , SA.y (String.fromFloat (l.y + l.height - 3.5))
            , SA.width (String.fromFloat (l.width - 4))
            , SA.height "3"
            , SA.rx "1"
            , SA.fill "url(#cautionPattern)"
            ]
            []
        , -- Neon top deck bevel
          rect
            [ SA.x (String.fromFloat (l.x + 1))
            , SA.y (String.fromFloat l.y)
            , SA.width (String.fromFloat (l.width - 2))
            , SA.height "3"
            , SA.rx "1.5"
            , SA.fill
                (if isRiding then
                    "#67e8f9"

                 else
                    "#f9a8d4"
                )
            ]
            []
        , -- End rivets / status LEDs
          circle
            [ SA.cx (String.fromFloat (l.x + 8))
            , SA.cy (String.fromFloat (midY - 0.5))
            , SA.r "2.2"
            , SA.fill
                (if isRiding then
                    "#67e8f9"

                 else
                    "#fdf2f8"
                )
            ]
            []
        , circle
            [ SA.cx (String.fromFloat (l.x + l.width - 8))
            , SA.cy (String.fromFloat (midY - 0.5))
            , SA.r "2.2"
            , SA.fill
                (if isRiding then
                    "#67e8f9"

                 else
                    "#fdf2f8"
                )
            ]
            []
        , -- Directional chevron indicator
          text_
            [ SA.x (String.fromFloat midX)
            , SA.y (String.fromFloat (midY + 2.5))
            , SA.textAnchor "middle"
            , SA.fill "#ffffff"
            , SA.fontSize "8.5"
            , SA.fontFamily "Courier New, monospace"
            , SA.fontWeight "bold"
            ]
            [ text chevron ]
        ]



-- LETHAL HAZARD PITS


viewHazard : Float -> Hazard -> Svg Msg
viewHazard clock h =
    let
        spikeCount =
            Basics.max 1 (floor (h.width / 16))

        pulseAlpha =
            String.fromFloat (0.55 + 0.35 * sin (clock * 7))

        waveOffset =
            sin (clock * 6) * 2.2

        spikes =
            List.range 0 (spikeCount - 1)
                |> List.map
                    (\i ->
                        let
                            sx =
                                h.x + toFloat i * 16

                            tipX =
                                sx + 8

                            tipY =
                                h.y - 5

                            baseY =
                                h.y + 10

                            fullPts =
                                String.fromFloat sx
                                    ++ ","
                                    ++ String.fromFloat baseY
                                    ++ " "
                                    ++ String.fromFloat tipX
                                    ++ ","
                                    ++ String.fromFloat tipY
                                    ++ " "
                                    ++ String.fromFloat (sx + 16)
                                    ++ ","
                                    ++ String.fromFloat baseY

                            glintPts =
                                String.fromFloat (sx + 2)
                                    ++ ","
                                    ++ String.fromFloat baseY
                                    ++ " "
                                    ++ String.fromFloat tipX
                                    ++ ","
                                    ++ String.fromFloat tipY
                                    ++ " "
                                    ++ String.fromFloat (sx + 9)
                                    ++ ","
                                    ++ String.fromFloat baseY
                        in
                        g []
                            [ polygon [ SA.points fullPts, SA.fill "url(#spikeGrad)", SA.stroke "#1e293b", SA.strokeWidth "0.8" ] []
                            , polygon [ SA.points glintPts, SA.fill "#fef08a", SA.opacity "0.45" ] []
                            , line
                                [ SA.x1 (String.fromFloat (sx + 1))
                                , SA.y1 (String.fromFloat baseY)
                                , SA.x2 (String.fromFloat tipX)
                                , SA.y2 (String.fromFloat tipY)
                                , SA.stroke "#ffffff"
                                , SA.strokeWidth "1"
                                , SA.opacity "0.8"
                                ]
                                []
                            ]
                    )
    in
    g []
        ([ -- Glowing plasma aura above the trough
           rect
            [ SA.x (String.fromFloat h.x)
            , SA.y (String.fromFloat (h.y + 3 + waveOffset * 0.4))
            , SA.width (String.fromFloat h.width)
            , SA.height "10"
            , SA.fill "#f97316"
            , SA.opacity pulseAlpha
            , SA.filter "url(#glowSoft)"
            ]
            []
         ]
            ++ spikes
            ++ [ -- Molten crimson/orange plasma trough
                 rect
                    [ SA.x (String.fromFloat h.x)
                    , SA.y (String.fromFloat (h.y + 8))
                    , SA.width (String.fromFloat h.width)
                    , SA.height (String.fromFloat (Basics.max 12 (h.height - 8)))
                    , SA.fill "url(#hazardPlasmaGrad)"
                    ]
                    []
               , -- Pulsing plasma surface wave
                 line
                    [ SA.x1 (String.fromFloat h.x)
                    , SA.y1 (String.fromFloat (h.y + 9 + waveOffset * 0.5))
                    , SA.x2 (String.fromFloat (h.x + h.width))
                    , SA.y2 (String.fromFloat (h.y + 9 - waveOffset * 0.5))
                    , SA.stroke "#fde047"
                    , SA.strokeWidth "2"
                    , SA.opacity pulseAlpha
                    , SA.filter "url(#glowSoft)"
                    ]
                    []
               , -- Yellow-black caution trim along bottom edge
                 rect
                    [ SA.x (String.fromFloat h.x)
                    , SA.y (String.fromFloat (h.y + h.height - 5))
                    , SA.width (String.fromFloat h.width)
                    , SA.height "5"
                    , SA.fill "url(#cautionPattern)"
                    ]
                    []
               ]
        )



-- SPARKLING COLLECTIBLES (GOLDEN EGGS & GRAIN SEED POUCHES)


viewEgg : Float -> Egg -> Svg Msg
viewEgg clock egg =
    let
        bob =
            sin (clock * 4 + egg.x * 0.05) * 2.8

        ey =
            egg.y + bob

        sparkleScale =
            0.5 + 0.5 * sin (clock * 7 + egg.x * 0.13)

        spX =
            egg.x + 6

        spY =
            ey - 8

        spR =
            3.5 * sparkleScale
    in
    g []
        [ -- Soft glowing golden halo
          circle
            [ SA.cx (String.fromFloat egg.x)
            , SA.cy (String.fromFloat ey)
            , SA.r "16"
            , SA.fill "url(#eggHaloGrad)"
            ]
            []
        , -- 3D shaded golden egg body
          ellipse
            [ SA.cx (String.fromFloat egg.x)
            , SA.cy (String.fromFloat ey)
            , SA.rx "9.5"
            , SA.ry "12.5"
            , SA.fill "url(#eggGrad)"
            , SA.stroke "#b45309"
            , SA.strokeWidth "1.6"
            , SA.filter "url(#glowSoft)"
            ]
            []
        , -- Crisp specular highlight
          ellipse
            [ SA.cx (String.fromFloat (egg.x - 3.2))
            , SA.cy (String.fromFloat (ey - 4.2))
            , SA.rx "2.4"
            , SA.ry "4.2"
            , SA.fill "#fefce8"
            , SA.opacity "0.9"
            ]
            []
        , -- Animated 4-point star sparkle
          if sparkleScale > 0.2 then
            g [ SA.opacity (String.fromFloat sparkleScale) ]
                [ line
                    [ SA.x1 (String.fromFloat (spX - spR))
                    , SA.y1 (String.fromFloat spY)
                    , SA.x2 (String.fromFloat (spX + spR))
                    , SA.y2 (String.fromFloat spY)
                    , SA.stroke "#ffffff"
                    , SA.strokeWidth "1.3"
                    , SA.strokeLinecap "round"
                    ]
                    []
                , line
                    [ SA.x1 (String.fromFloat spX)
                    , SA.y1 (String.fromFloat (spY - spR))
                    , SA.x2 (String.fromFloat spX)
                    , SA.y2 (String.fromFloat (spY + spR))
                    , SA.stroke "#ffffff"
                    , SA.strokeWidth "1.3"
                    , SA.strokeLinecap "round"
                    ]
                    []
                ]

          else
            g [] []
        ]


viewSeed : Float -> Seed -> Svg Msg
viewSeed clock seed =
    let
        bob =
            cos (clock * 4.5 + seed.x * 0.07) * 1.8

        sx =
            seed.x

        sy =
            seed.y + bob
    in
    g []
        [ -- Golden wheat stalks peeking out
          line [ SA.x1 (String.fromFloat (sx - 2)), SA.y1 (String.fromFloat (sy - 4)), SA.x2 (String.fromFloat (sx - 6)), SA.y2 (String.fromFloat (sy - 11)), SA.stroke "#fde047", SA.strokeWidth "1.8", SA.strokeLinecap "round" ] []
        , line [ SA.x1 (String.fromFloat sx), SA.y1 (String.fromFloat (sy - 4)), SA.x2 (String.fromFloat sx), SA.y2 (String.fromFloat (sy - 12)), SA.stroke "#facc15", SA.strokeWidth "2", SA.strokeLinecap "round" ] []
        , line [ SA.x1 (String.fromFloat (sx + 2)), SA.y1 (String.fromFloat (sy - 4)), SA.x2 (String.fromFloat (sx + 6)), SA.y2 (String.fromFloat (sy - 11)), SA.stroke "#fde047", SA.strokeWidth "1.8", SA.strokeLinecap "round" ] []
        , -- Green-gold grain pouch body
          ellipse
            [ SA.cx (String.fromFloat sx)
            , SA.cy (String.fromFloat (sy + 1))
            , SA.rx "8"
            , SA.ry "6.5"
            , SA.fill "#22c55e"
            , SA.stroke "#14532d"
            , SA.strokeWidth "1.5"
            ]
            []
        , -- Pouch highlight
          ellipse
            [ SA.cx (String.fromFloat (sx - 2.5))
            , SA.cy (String.fromFloat (sy - 0.5))
            , SA.rx "2.4"
            , SA.ry "2.2"
            , SA.fill "#86efac"
            , SA.opacity "0.75"
            ]
            []
        , -- Tied gold neck band
          rect
            [ SA.x (String.fromFloat (sx - 4.5))
            , SA.y (String.fromFloat (sy - 6))
            , SA.width "9"
            , SA.height "2.6"
            , SA.rx "1.2"
            , SA.fill "#f59e0b"
            , SA.stroke "#78350f"
            , SA.strokeWidth "0.8"
            ]
            []
        ]



-- EXPRESSIVE FEATHERED PATROLLING HENS


viewEnemy : Enemy -> Svg Msg
viewEnemy e =
    let
        facingRight =
            e.dir > 0

        dirSign =
            if facingRight then
                1.0

            else
                -1.0

        centerX =
            e.x + e.width / 2

        centerY =
            e.y + e.height / 2

        step =
            sin e.animTimer * 3.8

        wingFlap =
            sin (e.animTimer * 1.8) * 2.5

        headX =
            centerX + dirSign * 4.5

        headY =
            e.y + 9

        beakTipX =
            headX + dirSign * 11

        tailX =
            centerX - dirSign * 11

        footY =
            e.y + e.height

        leg1X =
            centerX - 3 + step

        leg2X =
            centerX + 3 - step
    in
    g []
        [ -- Ground shadow
          ellipse
            [ SA.cx (String.fromFloat centerX)
            , SA.cy (String.fromFloat footY)
            , SA.rx "11"
            , SA.ry "2.5"
            , SA.fill "#020617"
            , SA.opacity "0.45"
            ]
            []
        , -- Strutting legs & feet
          line [ SA.x1 (String.fromFloat (centerX - 3)), SA.y1 (String.fromFloat (e.y + 22)), SA.x2 (String.fromFloat leg1X), SA.y2 (String.fromFloat (footY - 1)), SA.stroke "#f59e0b", SA.strokeWidth "2.4", SA.strokeLinecap "round" ] []
        , line [ SA.x1 (String.fromFloat (leg1X - 2)), SA.y1 (String.fromFloat (footY - 1)), SA.x2 (String.fromFloat (leg1X + dirSign * 4)), SA.y2 (String.fromFloat (footY - 1)), SA.stroke "#facc15", SA.strokeWidth "2", SA.strokeLinecap "round" ] []
        , line [ SA.x1 (String.fromFloat (centerX + 3)), SA.y1 (String.fromFloat (e.y + 22)), SA.x2 (String.fromFloat leg2X), SA.y2 (String.fromFloat (footY - 1)), SA.stroke "#f59e0b", SA.strokeWidth "2.4", SA.strokeLinecap "round" ] []
        , line [ SA.x1 (String.fromFloat (leg2X - 2)), SA.y1 (String.fromFloat (footY - 1)), SA.x2 (String.fromFloat (leg2X + dirSign * 4)), SA.y2 (String.fromFloat (footY - 1)), SA.stroke "#facc15", SA.strokeWidth "2", SA.strokeLinecap "round" ] []
        , -- Fanned tail feathers
          polygon
            [ SA.points
                (String.fromFloat (centerX - dirSign * 7)
                    ++ ","
                    ++ String.fromFloat (centerY + 1)
                    ++ " "
                    ++ String.fromFloat (tailX - dirSign * 5)
                    ++ ","
                    ++ String.fromFloat (centerY - 7)
                    ++ " "
                    ++ String.fromFloat (tailX - dirSign * 2)
                    ++ ","
                    ++ String.fromFloat (centerY + 4)
                )
            , SA.fill "#be123c"
            ]
            []
        , polygon
            [ SA.points
                (String.fromFloat (centerX - dirSign * 7)
                    ++ ","
                    ++ String.fromFloat (centerY + 3)
                    ++ " "
                    ++ String.fromFloat (tailX - dirSign * 6)
                    ++ ","
                    ++ String.fromFloat (centerY - 1)
                    ++ " "
                    ++ String.fromFloat (tailX - dirSign * 1)
                    ++ ","
                    ++ String.fromFloat (centerY + 6)
                )
            , SA.fill "#e11d48"
            ]
            []
        , -- Plump feathered body
          ellipse
            [ SA.cx (String.fromFloat centerX)
            , SA.cy (String.fromFloat (centerY + 3))
            , SA.rx "12"
            , SA.ry "9.5"
            , SA.fill "#f43f5e"
            , SA.stroke "#881337"
            , SA.strokeWidth "1.3"
            ]
            []
        , -- Soft belly feather highlight
          ellipse
            [ SA.cx (String.fromFloat (centerX + dirSign * 2))
            , SA.cy (String.fromFloat (centerY + 6))
            , SA.rx "7.5"
            , SA.ry "4.5"
            , SA.fill "#fda4af"
            , SA.opacity "0.65"
            ]
            []
        , -- Animated flapping wing
          ellipse
            [ SA.cx (String.fromFloat (centerX - dirSign * 1.5))
            , SA.cy (String.fromFloat (centerY + 2 - wingFlap * 0.6))
            , SA.rx "7.2"
            , SA.ry "4.5"
            , SA.fill "#e11d48"
            , SA.stroke "#9f1239"
            , SA.strokeWidth "1"
            ]
            []
        , -- Red 3-lobed comb on head
          circle [ SA.cx (String.fromFloat (headX - dirSign * 2.5)), SA.cy (String.fromFloat (headY - 7)), SA.r "2.6", SA.fill "#dc2626" ] []
        , circle [ SA.cx (String.fromFloat headX), SA.cy (String.fromFloat (headY - 8.2)), SA.r "2.8", SA.fill "#ef4444" ] []
        , circle [ SA.cx (String.fromFloat (headX + dirSign * 2.5)), SA.cy (String.fromFloat (headY - 6.8)), SA.r "2.3", SA.fill "#dc2626" ] []
        , -- Head
          circle
            [ SA.cx (String.fromFloat headX)
            , SA.cy (String.fromFloat headY)
            , SA.r "6.5"
            , SA.fill "#fb7185"
            , SA.stroke "#881337"
            , SA.strokeWidth "1.2"
            ]
            []
        , -- Wattle under beak
          ellipse
            [ SA.cx (String.fromFloat (headX + dirSign * 4.5))
            , SA.cy (String.fromFloat (headY + 4.5))
            , SA.rx "2"
            , SA.ry "2.8"
            , SA.fill "#dc2626"
            ]
            []
        , -- Sharp golden beak
          polygon
            [ SA.points
                (String.fromFloat (headX + dirSign * 4.5)
                    ++ ","
                    ++ String.fromFloat (headY - 2)
                    ++ " "
                    ++ String.fromFloat beakTipX
                    ++ ","
                    ++ String.fromFloat (headY + 0.5)
                    ++ " "
                    ++ String.fromFloat (headX + dirSign * 4.5)
                    ++ ","
                    ++ String.fromFloat (headY + 3)
                )
            , SA.fill "#facc15"
            , SA.stroke "#b45309"
            , SA.strokeWidth "0.8"
            ]
            []
        , -- Alert eye + fierce brow
          circle [ SA.cx (String.fromFloat (headX + dirSign * 2.5)), SA.cy (String.fromFloat (headY - 1)), SA.r "2.4", SA.fill "#ffffff" ] []
        , circle [ SA.cx (String.fromFloat (headX + dirSign * 3.2)), SA.cy (String.fromFloat (headY - 1)), SA.r "1.3", SA.fill "#0f172a" ] []
        , line
            [ SA.x1 (String.fromFloat (headX + dirSign * 0.4))
            , SA.y1 (String.fromFloat (headY - 3.6))
            , SA.x2 (String.fromFloat (headX + dirSign * 4.8))
            , SA.y2 (String.fromFloat (headY - 2.6))
            , SA.stroke "#881337"
            , SA.strokeWidth "1.4"
            , SA.strokeLinecap "round"
            ]
            []
        ]



-- EXPRESSIVE PLAYER SPRITE ("HEN-HOUSE HARRY" STYLE)


viewPlayer : Model -> Svg Msg
viewPlayer model =
    let
        p =
            model.player

        isDying =
            case model.status of
                Dying _ ->
                    True

                _ ->
                    False

        blinkHide =
            isDying && (sin (model.animClock * 35) > 0)
    in
    if blinkHide then
        g [] []

    else
        let
            dirSign =
                case p.facing of
                    Right ->
                        1.0

                    Left ->
                        -1.0

            centerX =
                p.x + p.width / 2

            isAirborne =
                not p.onGround && not p.onLadder

            isWalking =
                p.onGround && abs p.vx > 1

            legSwing =
                if isWalking then
                    sin p.walkFrame * 5.2

                else if p.onLadder then
                    sin p.walkFrame * 3.5

                else
                    0

            armSwing =
                if isWalking then
                    -legSwing * 0.9

                else if p.onLadder then
                    sin (p.walkFrame + 1.5) * 4.5

                else
                    0

            bodyBob =
                if isWalking then
                    abs (sin p.walkFrame) * -1.4

                else
                    0

            py =
                p.y + bodyBob

            -- Leg & boot endpoints
            feet =
                if isAirborne then
                    -- Distinct dynamic airborne jump pose
                    { lx = centerX - 5.5
                    , ly = p.y + p.height - 2.5
                    , rx = centerX + 6.0
                    , ry = p.y + p.height - 5.0
                    }

                else if p.onLadder then
                    { lx = centerX - 4.0
                    , ly = p.y + p.height - 1.5 + legSwing * 0.5
                    , rx = centerX + 4.0
                    , ry = p.y + p.height - 1.5 - legSwing * 0.5
                    }

                else
                    { lx = centerX - 3.5 + legSwing
                    , ly = p.y + p.height - 1.5
                    , rx = centerX + 3.5 - legSwing
                    , ry = p.y + p.height - 1.5
                    }

            -- Arm endpoints
            arms =
                if isAirborne then
                    -- Arms raised for balance in mid-air
                    { bx = centerX - dirSign * 9.5
                    , by = py + 14.5
                    , fx = centerX + dirSign * 10.0
                    , fy = py + 12.0
                    }

                else if p.onLadder then
                    -- Reaching up to climb ladder rungs
                    { bx = centerX - 8.0
                    , by = py + 11.0 + armSwing
                    , fx = centerX + 8.0
                    , fy = py + 11.0 - armSwing
                    }

                else
                    { bx = centerX - 6.5 - armSwing
                    , by = py + 23.0
                    , fx = centerX + 6.5 + armSwing
                    , fy = py + 23.0
                    }

            visorX =
                case p.facing of
                    Right ->
                        centerX + 1

                    Left ->
                        centerX - 11
        in
        g []
            [ -- Ground shadow when grounded
              if p.onGround then
                ellipse
                    [ SA.cx (String.fromFloat centerX)
                    , SA.cy (String.fromFloat (p.y + p.height))
                    , SA.rx "9.5"
                    , SA.ry "2.3"
                    , SA.fill "#020617"
                    , SA.opacity "0.5"
                    ]
                    []

              else
                g [] []
            , -- Back arm (yellow shirt sleeve + hand)
              line [ SA.x1 (String.fromFloat (centerX - dirSign * 4)), SA.y1 (String.fromFloat (py + 18)), SA.x2 (String.fromFloat arms.bx), SA.y2 (String.fromFloat arms.by), SA.stroke "#eab308", SA.strokeWidth "3.2", SA.strokeLinecap "round" ] []
            , circle [ SA.cx (String.fromFloat arms.bx), SA.cy (String.fromFloat arms.by), SA.r "2", SA.fill "#fde68a" ] []
            , -- Legs (denim overalls)
              line [ SA.x1 (String.fromFloat (centerX - 3)), SA.y1 (String.fromFloat (py + 24)), SA.x2 (String.fromFloat feet.lx), SA.y2 (String.fromFloat feet.ly), SA.stroke "#1d4ed8", SA.strokeWidth "4", SA.strokeLinecap "round" ] []
            , line [ SA.x1 (String.fromFloat (centerX + 3)), SA.y1 (String.fromFloat (py + 24)), SA.x2 (String.fromFloat feet.rx), SA.y2 (String.fromFloat feet.ry), SA.stroke "#2563eb", SA.strokeWidth "4", SA.strokeLinecap "round" ] []
            , -- Leather farmer boots
              ellipse [ SA.cx (String.fromFloat (feet.lx + dirSign * 1.2)), SA.cy (String.fromFloat (feet.ly + 0.5)), SA.rx "3.6", SA.ry "2.2", SA.fill "#78350f", SA.stroke "#451a03", SA.strokeWidth "0.8" ] []
            , ellipse [ SA.cx (String.fromFloat (feet.rx + dirSign * 1.2)), SA.cy (String.fromFloat (feet.ry + 0.5)), SA.rx "3.6", SA.ry "2.2", SA.fill "#92400e", SA.stroke "#451a03", SA.strokeWidth "0.8" ] []
            , -- Yellow work shirt torso
              rect [ SA.x (String.fromFloat (centerX - 6.5)), SA.y (String.fromFloat (py + 15.5)), SA.width "13", SA.height "10", SA.rx "2.5", SA.fill "#facc15", SA.stroke "#a16207", SA.strokeWidth "0.8" ] []
            , -- Denim overalls bib & straps
              rect [ SA.x (String.fromFloat (centerX - 5.5)), SA.y (String.fromFloat (py + 19.5)), SA.width "11", SA.height "6.8", SA.rx "1.5", SA.fill "#2563eb" ] []
            , rect [ SA.x (String.fromFloat (centerX - 4.5)), SA.y (String.fromFloat (py + 16)), SA.width "2.2", SA.height "4.5", SA.fill "#2563eb" ] []
            , rect [ SA.x (String.fromFloat (centerX + 2.3)), SA.y (String.fromFloat (py + 16)), SA.width "2.2", SA.height "4.5", SA.fill "#2563eb" ] []
            , -- Gold overall buttons
              circle [ SA.cx (String.fromFloat (centerX - 3.4)), SA.cy (String.fromFloat (py + 20.5)), SA.r "1.1", SA.fill "#fde047" ] []
            , circle [ SA.cx (String.fromFloat (centerX + 3.4)), SA.cy (String.fromFloat (py + 20.5)), SA.r "1.1", SA.fill "#fde047" ] []
            , -- Red kerchief / bandana
              polygon
                [ SA.points
                    (String.fromFloat (centerX - 5.5)
                        ++ ","
                        ++ String.fromFloat (py + 15.2)
                        ++ " "
                        ++ String.fromFloat (centerX + 5.5)
                        ++ ","
                        ++ String.fromFloat (py + 15.2)
                        ++ " "
                        ++ String.fromFloat (centerX + dirSign * 1.5)
                        ++ ","
                        ++ String.fromFloat (py + 19.0)
                    )
                , SA.fill "#ef4444"
                ]
                []
            , -- Front arm (yellow sleeve + hand)
              line [ SA.x1 (String.fromFloat (centerX + dirSign * 4)), SA.y1 (String.fromFloat (py + 18)), SA.x2 (String.fromFloat arms.fx), SA.y2 (String.fromFloat arms.fy), SA.stroke "#facc15", SA.strokeWidth "3.2", SA.strokeLinecap "round" ] []
            , circle [ SA.cx (String.fromFloat arms.fx), SA.cy (String.fromFloat arms.fy), SA.r "2", SA.fill "#fde68a" ] []
            , -- Expressive head
              circle [ SA.cx (String.fromFloat centerX), SA.cy (String.fromFloat (py + 9.5)), SA.r "6.8", SA.fill "#fde68a", SA.stroke "#b45309", SA.strokeWidth "0.9" ] []
            , -- Rosy cheek
              circle [ SA.cx (String.fromFloat (centerX + dirSign * 3.5)), SA.cy (String.fromFloat (py + 11.4)), SA.r "1.5", SA.fill "#fb7185", SA.opacity "0.45" ] []
            , -- Eye (sclera + pupil)
              circle [ SA.cx (String.fromFloat (centerX + dirSign * 2.8)), SA.cy (String.fromFloat (py + 8.8)), SA.r "2.1", SA.fill "#ffffff" ] []
            , circle [ SA.cx (String.fromFloat (centerX + dirSign * 3.4)), SA.cy (String.fromFloat (py + 8.8)), SA.r "1.15", SA.fill "#0f172a" ] []
            , -- Smile
              path
                [ SA.d
                    ("M "
                        ++ String.fromFloat (centerX + dirSign * 1.5)
                        ++ " "
                        ++ String.fromFloat (py + 12.6)
                        ++ " Q "
                        ++ String.fromFloat (centerX + dirSign * 3.2)
                        ++ " "
                        ++ String.fromFloat (py + 13.8)
                        ++ " "
                        ++ String.fromFloat (centerX + dirSign * 4.8)
                        ++ " "
                        ++ String.fromFloat (py + 12.2)
                    )
                , SA.fill "none"
                , SA.stroke "#92400e"
                , SA.strokeWidth "1"
                , SA.strokeLinecap "round"
                ]
                []
            , -- Peaked farmer cap crown
              path
                [ SA.d
                    ("M "
                        ++ String.fromFloat (centerX - 7.5)
                        ++ " "
                        ++ String.fromFloat (py + 5.5)
                        ++ " Q "
                        ++ String.fromFloat centerX
                        ++ " "
                        ++ String.fromFloat (py - 4.5)
                        ++ " "
                        ++ String.fromFloat (centerX + 7.5)
                        ++ " "
                        ++ String.fromFloat (py + 5.5)
                        ++ " Z"
                    )
                , SA.fill "#38bdf8"
                , SA.stroke "#0369a1"
                , SA.strokeWidth "1.1"
                ]
                []
            , -- Cap band & gold emblem
              rect [ SA.x (String.fromFloat (centerX - 7)), SA.y (String.fromFloat (py + 3.8)), SA.width "14", SA.height "2", SA.fill "#0284c7" ] []
            , circle [ SA.cx (String.fromFloat (centerX + dirSign * 2)), SA.cy (String.fromFloat (py + 2.2)), SA.r "1.4", SA.fill "#fde047" ] []
            , -- Directional cap visor
              rect [ SA.x (String.fromFloat visorX), SA.y (String.fromFloat (py + 4.2)), SA.width "10", SA.height "2.6", SA.rx "1.3", SA.fill "#0369a1" ] []
            ]



-- PARTICLES & FLOATING SCORE POPUPS


viewParticle : Particle -> Svg Msg
viewParticle pt =
    let
        ratio =
            Basics.clamp 0 1 (pt.life / Basics.max 0.001 pt.maxLife)

        radius =
            pt.size * (0.3 + 0.7 * ratio)
    in
    circle
        [ SA.cx (String.fromFloat pt.x)
        , SA.cy (String.fromFloat pt.y)
        , SA.r (String.fromFloat radius)
        , SA.fill pt.color
        , SA.opacity (String.fromFloat ratio)
        ]
        []


viewPopup : ScorePopup -> Svg Msg
viewPopup pop =
    let
        ratio =
            Basics.clamp 0 1 (pop.life / Basics.max 0.001 pop.maxLife)

        alpha =
            Basics.min 1.0 (ratio * 1.6)
    in
    text_
        [ SA.x (String.fromFloat pop.x)
        , SA.y (String.fromFloat pop.y)
        , SA.textAnchor "middle"
        , SA.fill pop.color
        , SA.stroke "#020617"
        , SA.strokeWidth "3"
        , SA.fontSize "14"
        , SA.fontFamily "Courier New, monospace"
        , SA.fontWeight "bold"
        , SA.opacity (String.fromFloat alpha)
        , SA.style "paint-order: stroke; pointer-events: none;"
        ]
        [ text pop.text ]



-- OVERLAYS (TITLE, PAUSE, DYING, LEVEL CLEAR, GAME OVER)


viewOverlay : Model -> List (Svg Msg)
viewOverlay model =
    case model.status of
        TitleScreen ->
            [ scrim
            , overlayCard 110 108 580 388 "#2dd4bf"
            , -- Decorative title emblem: mini glowing golden egg on left & right
              viewEgg model.animClock { id = 0, x = 188, y = 174, collected = False }
            , viewEgg model.animClock { id = 0, x = 612, y = 174, collected = False }
            , centeredTextGlow "186" "#facc15" "42" "CHUCKIE LIFT"
            , centeredText "222" "#2dd4bf" "14" "A RETRO ELM ARCADE PLATFORMER"
            , line [ SA.x1 "170", SA.y1 "244", SA.x2 "630", SA.y2 "244", SA.stroke "#1e293b", SA.strokeWidth "1.5" ] []
            , centeredText "278" "#e2e8f0" "14.5" "COLLECT ALL GOLDEN EGGS ON EACH STAGE"
            , centeredText "308" "#f472b6" "14.5" "RIDE MOVING LIFTS TO CROSS MOLTEN HAZARD PITS"
            , centeredText "338" "#fb7185" "13.5" "AVOID PATROLLING HENS & WATCH YOUR STEP!"
            , rect [ SA.x "160", SA.y "364", SA.width "480", SA.height "34", SA.rx "6", SA.fill "#0f172a", SA.stroke "#1e293b", SA.strokeWidth "1" ] []
            , centeredText "386" "#94a3b8" "13" "ARROWS / WASD: MOVE & CLIMB  |  SPACE: JUMP  |  P: PAUSE"
            , arcadeButton 270 422 260 44 "#2dd4bf" "#0f766e" "#04131c" "PRESS SPACE TO START"
            ]

        Paused ->
            [ scrim
            , overlayCard 205 210 390 158 "#38bdf8"
            , centeredTextGlow "268" "#38bdf8" "34" "PAUSED"
            , line [ SA.x1 "255", SA.y1 "288", SA.x2 "545", SA.y2 "288", SA.stroke "#1e293b", SA.strokeWidth "1.5" ] []
            , centeredText "324" "#e2e8f0" "14.5" "PRESS P TO RESUME  |  R TO RESTART"
            ]

        Dying _ ->
            [ scrim
            , overlayCard 170 225 460 116 "#f43f5e"
            , centeredTextGlow "272" "#f43f5e" "26" "LIFE LOST!"
            , centeredText "308" "#fda4af" "15" model.deathReason
            ]

        LevelClear _ ->
            [ scrim
            , overlayCard 170 212 460 144 "#4ade80"
            , centeredTextGlow "266" "#4ade80" "30" "STAGE COMPLETE!"
            , centeredText "306" "#facc15" "17" ("TIME BONUS: +" ++ String.fromInt (round model.bonusTimer * 10))
            , centeredText "334" "#94a3b8" "13" "PREPARING NEXT HENHOUSE..."
            ]

        GameOver ->
            [ scrim
            , overlayCard 170 175 460 242 "#f43f5e"
            , centeredTextGlow "236" "#f43f5e" "40" "GAME OVER"
            , line [ SA.x1 "220", SA.y1 "254", SA.x2 "580", SA.y2 "254", SA.stroke "#1e293b", SA.strokeWidth "1.5" ] []
            , centeredText "292" "#f8fafc" "20" ("FINAL SCORE: " ++ padScore model.score)
            , centeredText "324" "#38bdf8" "16" ("HIGH SCORE:  " ++ padScore model.highScore)
            , arcadeButton 265 348 270 44 "#facc15" "#ca8a04" "#0b0d17" "PRESS SPACE TO RETRY"
            ]

        Playing ->
            []


scrim : Svg Msg
scrim =
    rect
        [ SA.x "0"
        , SA.y "54"
        , SA.width "800"
        , SA.height "546"
        , SA.fill "#040712"
        , SA.opacity "0.58"
        ]
        []


overlayCard : Float -> Float -> Float -> Float -> String -> Svg Msg
overlayCard cxPos cyPos cw ch accent =
    g []
        [ -- Outer glow border
          rect
            [ SA.x (String.fromFloat cxPos)
            , SA.y (String.fromFloat cyPos)
            , SA.width (String.fromFloat cw)
            , SA.height (String.fromFloat ch)
            , SA.rx "12"
            , SA.fill "rgba(8, 12, 26, 0.94)"
            , SA.stroke accent
            , SA.strokeWidth "2.5"
            , SA.filter "url(#glowSoft)"
            ]
            []
        , -- Crisp inner hairline frame
          rect
            [ SA.x (String.fromFloat (cxPos + 6))
            , SA.y (String.fromFloat (cyPos + 6))
            , SA.width (String.fromFloat (cw - 12))
            , SA.height (String.fromFloat (ch - 12))
            , SA.rx "8"
            , SA.fill "none"
            , SA.stroke accent
            , SA.strokeWidth "1"
            , SA.opacity "0.35"
            ]
            []
        ]


arcadeButton : Float -> Float -> Float -> Float -> String -> String -> String -> String -> Svg Msg
arcadeButton bx by bw bh fillCol borderCol textCol label =
    g [ onClick StartGame, SA.cursor "pointer" ]
        [ -- Shadow
          rect
            [ SA.x (String.fromFloat bx)
            , SA.y (String.fromFloat (by + 4))
            , SA.width (String.fromFloat bw)
            , SA.height (String.fromFloat bh)
            , SA.rx "7"
            , SA.fill borderCol
            ]
            []
        , -- Main button face
          rect
            [ SA.x (String.fromFloat bx)
            , SA.y (String.fromFloat by)
            , SA.width (String.fromFloat bw)
            , SA.height (String.fromFloat bh)
            , SA.rx "7"
            , SA.fill fillCol
            ]
            []
        , -- Top bevel sheen
          rect
            [ SA.x (String.fromFloat (bx + 4))
            , SA.y (String.fromFloat (by + 2))
            , SA.width (String.fromFloat (bw - 8))
            , SA.height "4"
            , SA.rx "2"
            , SA.fill "#ffffff"
            , SA.opacity "0.35"
            ]
            []
        , centeredText (String.fromFloat (by + bh / 2 + 6)) textCol "16.5" label
        ]


centeredText : String -> String -> String -> String -> Svg Msg
centeredText ty col sz label =
    text_
        [ SA.x "400"
        , SA.y ty
        , SA.textAnchor "middle"
        , SA.fill col
        , SA.fontSize sz
        , SA.fontFamily "Courier New, monospace"
        , SA.fontWeight "bold"
        ]
        [ text label ]


centeredTextGlow : String -> String -> String -> String -> Svg Msg
centeredTextGlow ty col sz label =
    text_
        [ SA.x "400"
        , SA.y ty
        , SA.textAnchor "middle"
        , SA.fill col
        , SA.fontSize sz
        , SA.fontFamily "Courier New, monospace"
        , SA.fontWeight "bold"
        , SA.letterSpacing "2"
        , SA.filter "url(#glowSoft)"
        ]
        [ text label ]
