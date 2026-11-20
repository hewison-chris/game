module View exposing (view)

import Html exposing (Html)
import Html.Attributes as HA
import Svg exposing (..)
import Svg.Attributes exposing (..)
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
            [ viewBox "0 0 800 600"
            , Svg.Attributes.width "800"
            , Svg.Attributes.height "600"
            ]
            (List.concat
                [ [ rect [ x "0", y "0", width "800", height "600", fill "#0b0d17" ] [] ]
                , viewBackgroundGrid
                , [ viewHud model ]
                , List.map viewLadder model.level.ladders
                , List.map viewPlatform model.level.platforms
                , List.map (viewLiftGuide) model.level.lifts
                , List.map viewLift model.level.lifts
                , List.map (viewHazard model.animClock) model.level.hazards
                , List.map (viewSeed model.animClock) (List.filter (not << .collected) model.level.seeds)
                , List.map (viewEgg model.animClock) (List.filter (not << .collected) model.level.eggs)
                , List.map viewEnemy model.level.enemies
                , [ viewPlayer model ]
                , viewOverlay model
                ]
            )
        ]


viewBackgroundGrid : List (Svg Msg)
viewBackgroundGrid =
    let
        vLines =
            List.range 1 15
                |> List.map
                    (\i ->
                        let
                            px =
                                String.fromInt (i * 50)
                        in
                        line
                            [ x1 px
                            , y1 "56"
                            , x2 px
                            , y2 "600"
                            , stroke "#13172b"
                            , strokeWidth "1"
                            ]
                            []
                    )

        hLines =
            List.range 2 11
                |> List.map
                    (\i ->
                        let
                            py =
                                String.fromInt (i * 50)
                        in
                        line
                            [ x1 "0"
                            , y1 py
                            , x2 "800"
                            , y2 py
                            , stroke "#13172b"
                            , strokeWidth "1"
                            ]
                            []
                    )
    in
    vLines ++ hLines


viewHud : Model -> Svg Msg
viewHud model =
    let
        eggsRemaining =
            model.level.eggs
                |> List.filter (not << .collected)
                |> List.length

        livesIcons =
            List.range 1 (Basics.max 0 model.lives)
                |> List.map
                    (\i ->
                        circle
                            [ cx (String.fromInt (665 + i * 22))
                            , cy "28"
                            , r "7"
                            , fill "#facc15"
                            , stroke "#fb923c"
                            , strokeWidth "2"
                            ]
                            []
                    )
    in
    g []
        [ rect [ x "0", y "0", width "800", height "54", fill "#11162a" ] []
        , line [ x1 "0", y1 "54", x2 "800", y2 "54", stroke "#2dd4bf", strokeWidth "2" ] []
        , hudText "20" "22" "#94a3b8" "12" "SCORE"
        , hudText "20" "43" "#f8fafc" "18" (padScore model.score)
        , hudText "140" "22" "#94a3b8" "12" "HI-SCORE"
        , hudText "140" "43" "#38bdf8" "18" (padScore model.highScore)
        , hudText "275" "22" "#94a3b8" "12" "LEVEL"
        , hudText "275" "43" "#2dd4bf" "16" model.level.name
        , hudText "525" "22" "#94a3b8" "12" "BONUS"
        , hudText "525" "43"
            (if model.bonusTimer < 25 then
                "#f43f5e"

             else
                "#facc15"
            )
            "18"
            (String.fromInt (round model.bonusTimer))
        , hudText "610" "22" "#94a3b8" "12" ("EGGS:" ++ String.fromInt eggsRemaining)
        , hudText "610" "43" "#94a3b8" "12" "LIVES"
        , g [] livesIcons
        ]


hudText : String -> String -> String -> String -> String -> Svg Msg
hudText tx ty col sz label =
    text_
        [ x tx
        , y ty
        , fill col
        , fontSize sz
        , fontFamily "Courier New, monospace"
        , fontWeight "bold"
        ]
        [ text label ]


padScore : Int -> String
padScore n =
    String.padLeft 6 '0' (String.fromInt n)


viewPlatform : Platform -> Svg Msg
viewPlatform p =
    g []
        [ rect
            [ x (String.fromFloat p.x)
            , y (String.fromFloat p.y)
            , width (String.fromFloat p.width)
            , height (String.fromFloat p.height)
            , fill "#0f766e"
            , rx "3"
            ]
            []
        , rect
            [ x (String.fromFloat p.x)
            , y (String.fromFloat p.y)
            , width (String.fromFloat p.width)
            , height "4"
            , fill "#2dd4bf"
            , rx "2"
            ]
            []
        ]


viewLadder : Ladder -> Svg Msg
viewLadder lad =
    let
        rungCount =
            floor ((lad.bottomY - lad.topY) / 16)

        rungs =
            List.range 0 rungCount
                |> List.map
                    (\i ->
                        let
                            ry =
                                String.fromFloat (lad.topY + 6 + toFloat i * 16)
                        in
                        line
                            [ x1 (String.fromFloat (lad.x + 4))
                            , y1 ry
                            , x2 (String.fromFloat (lad.x + lad.width - 4))
                            , y2 ry
                            , stroke "#fbbf24"
                            , strokeWidth "3"
                            ]
                            []
                    )
    in
    g []
        ([ line
            [ x1 (String.fromFloat (lad.x + 5))
            , y1 (String.fromFloat lad.topY)
            , x2 (String.fromFloat (lad.x + 5))
            , y2 (String.fromFloat lad.bottomY)
            , stroke "#d97706"
            , strokeWidth "4"
            ]
            []
         , line
            [ x1 (String.fromFloat (lad.x + lad.width - 5))
            , y1 (String.fromFloat lad.topY)
            , x2 (String.fromFloat (lad.x + lad.width - 5))
            , y2 (String.fromFloat lad.bottomY)
            , stroke "#d97706"
            , strokeWidth "4"
            ]
            []
         ]
            ++ rungs
        )


viewLiftGuide : Lift -> Svg Msg
viewLiftGuide l =
    case l.axis of
        Vertical ->
            line
                [ x1 (String.fromFloat (l.x + l.width / 2))
                , y1 (String.fromFloat l.minPos)
                , x2 (String.fromFloat (l.x + l.width / 2))
                , y2 (String.fromFloat (l.maxPos + l.height))
                , stroke "#334155"
                , strokeWidth "2"
                , strokeDasharray "5,5"
                ]
                []

        Horizontal ->
            line
                [ x1 (String.fromFloat l.minPos)
                , y1 (String.fromFloat (l.y + l.height / 2))
                , x2 (String.fromFloat (l.maxPos + l.width))
                , y2 (String.fromFloat (l.y + l.height / 2))
                , stroke "#334155"
                , strokeWidth "2"
                , strokeDasharray "5,5"
                ]
                []


viewLift : Lift -> Svg Msg
viewLift l =
    g []
        [ rect
            [ x (String.fromFloat l.x)
            , y (String.fromFloat l.y)
            , width (String.fromFloat l.width)
            , height (String.fromFloat l.height)
            , fill "#db2777"
            , rx "3"
            ]
            []
        , rect
            [ x (String.fromFloat l.x)
            , y (String.fromFloat l.y)
            , width (String.fromFloat l.width)
            , height "4"
            , fill "#f472b6"
            , rx "2"
            ]
            []
        , circle
            [ cx (String.fromFloat (l.x + 10))
            , cy (String.fromFloat (l.y + 8))
            , r "2.5"
            , fill "#fdf2f8"
            ]
            []
        , circle
            [ cx (String.fromFloat (l.x + l.width - 10))
            , cy (String.fromFloat (l.y + 8))
            , r "2.5"
            , fill "#fdf2f8"
            ]
            []
        ]


viewHazard : Float -> Hazard -> Svg Msg
viewHazard clock h =
    let
        spikeCount =
            floor (h.width / 16)

        pulse =
            if sin (clock * 8) > 0 then
                "#ef4444"

            else
                "#f97316"

        spikes =
            List.range 0 (spikeCount - 1)
                |> List.map
                    (\i ->
                        let
                            sx =
                                h.x + toFloat i * 16

                            pts =
                                String.fromFloat sx
                                    ++ ","
                                    ++ String.fromFloat (h.y + 10)
                                    ++ " "
                                    ++ String.fromFloat (sx + 8)
                                    ++ ","
                                    ++ String.fromFloat (h.y - 4)
                                    ++ " "
                                    ++ String.fromFloat (sx + 16)
                                    ++ ","
                                    ++ String.fromFloat (h.y + 10)
                        in
                        polygon [ points pts, fill pulse ] []
                    )
    in
    g []
        ([ rect
            [ x (String.fromFloat h.x)
            , y (String.fromFloat (h.y + 8))
            , width (String.fromFloat h.width)
            , height (String.fromFloat h.height)
            , fill "#7f1d1d"
            ]
            []
         ]
            ++ spikes
        )


viewEgg : Float -> Egg -> Svg Msg
viewEgg clock egg =
    let
        bob =
            sin (clock * 4 + egg.x * 0.05) * 2.5
    in
    g []
        [ ellipse
            [ cx (String.fromFloat egg.x)
            , cy (String.fromFloat (egg.y + bob))
            , rx "9"
            , ry "12"
            , fill "#fde047"
            , stroke "#ca8a04"
            , strokeWidth "2"
            ]
            []
        , ellipse
            [ cx (String.fromFloat (egg.x - 3))
            , cy (String.fromFloat (egg.y + bob - 4))
            , rx "2.5"
            , ry "4"
            , fill "#fef9c3"
            ]
            []
        ]


viewSeed : Float -> Seed -> Svg Msg
viewSeed clock seed =
    let
        bob =
            cos (clock * 5 + seed.x * 0.07) * 1.5
    in
    g []
        [ rect
            [ x (String.fromFloat (seed.x - 7))
            , y (String.fromFloat (seed.y - 5 + bob))
            , width "14"
            , height "10"
            , rx "4"
            , fill "#4ade80"
            , stroke "#16a34a"
            , strokeWidth "2"
            ]
            []
        ]


viewEnemy : Enemy -> Svg Msg
viewEnemy e =
    let
        centerX =
            e.x + e.width / 2

        centerY =
            e.y + e.height / 2

        step =
            sin e.animTimer * 3

        beakX =
            if e.dir > 0 then
                e.x + e.width + 4

            else
                e.x - 4
    in
    g []
        [ -- Body
          ellipse
            [ cx (String.fromFloat centerX)
            , cy (String.fromFloat (centerY + 3))
            , rx "12"
            , ry "11"
            , fill "#f43f5e"
            ]
            []
        , -- Head
          circle
            [ cx (String.fromFloat centerX)
            , cy (String.fromFloat (e.y + 7))
            , r "7"
            , fill "#fb7185"
            ]
            []
        , -- Beak
          polygon
            [ points
                (String.fromFloat centerX
                    ++ ","
                    ++ String.fromFloat (e.y + 5)
                    ++ " "
                    ++ String.fromFloat beakX
                    ++ ","
                    ++ String.fromFloat (e.y + 8)
                    ++ " "
                    ++ String.fromFloat centerX
                    ++ ","
                    ++ String.fromFloat (e.y + 11)
                )
            , fill "#facc15"
            ]
            []
        , -- Eye
          circle
            [ cx
                (String.fromFloat
                    (if e.dir > 0 then
                        centerX + 3

                     else
                        centerX - 3
                    )
                )
            , cy (String.fromFloat (e.y + 6))
            , r "1.8"
            , fill "#0f172a"
            ]
            []
        , -- Legs
          line
            [ x1 (String.fromFloat (centerX - 4))
            , y1 (String.fromFloat (e.y + 23))
            , x2 (String.fromFloat (centerX - 4 + step))
            , y2 (String.fromFloat (e.y + e.height))
            , stroke "#facc15"
            , strokeWidth "2.5"
            ]
            []
        , line
            [ x1 (String.fromFloat (centerX + 4))
            , y1 (String.fromFloat (e.y + 23))
            , x2 (String.fromFloat (centerX + 4 - step))
            , y2 (String.fromFloat (e.y + e.height))
            , stroke "#facc15"
            , strokeWidth "2.5"
            ]
            []
        ]


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
            centerX =
                p.x + p.width / 2

            legSwing =
                if p.onGround && abs p.vx > 1 then
                    sin p.walkFrame * 4

                else if p.onLadder then
                    sin p.walkFrame * 3

                else
                    0

            eyeX =
                case p.facing of
                    Right ->
                        centerX + 3.5

                    Left ->
                        centerX - 3.5
        in
        g []
            [ -- Hat / Cap
              rect
                [ x (String.fromFloat (p.x + 3))
                , y (String.fromFloat p.y)
                , width (String.fromFloat (p.width - 6))
                , height "6"
                , rx "2"
                , fill "#38bdf8"
                ]
                []
            , -- Head
              circle
                [ cx (String.fromFloat centerX)
                , cy (String.fromFloat (p.y + 10))
                , r "7"
                , fill "#fde68a"
                ]
                []
            , -- Eye
              circle
                [ cx (String.fromFloat eyeX)
                , cy (String.fromFloat (p.y + 9))
                , r "1.8"
                , fill "#0f172a"
                ]
                []
            , -- Overalls / Torso
              rect
                [ x (String.fromFloat (p.x + 5))
                , y (String.fromFloat (p.y + 16))
                , width (String.fromFloat (p.width - 10))
                , height "10"
                , rx "2"
                , fill "#facc15"
                ]
                []
            , -- Legs
              line
                [ x1 (String.fromFloat (centerX - 3))
                , y1 (String.fromFloat (p.y + 26))
                , x2 (String.fromFloat (centerX - 3 + legSwing))
                , y2 (String.fromFloat (p.y + p.height))
                , stroke "#38bdf8"
                , strokeWidth "3.5"
                ]
                []
            , line
                [ x1 (String.fromFloat (centerX + 3))
                , y1 (String.fromFloat (p.y + 26))
                , x2 (String.fromFloat (centerX + 3 - legSwing))
                , y2 (String.fromFloat (p.y + p.height))
                , stroke "#38bdf8"
                , strokeWidth "3.5"
                ]
                []
            ]


viewOverlay : Model -> List (Svg Msg)
viewOverlay model =
    case model.status of
        TitleScreen ->
            [ rect [ x "120", y "120", width "560", height "350", rx "12", fill "rgba(11, 13, 23, 0.92)", stroke "#2dd4bf", strokeWidth "3" ] []
            , centeredText "200" "#facc15" "40" "CHUCKIE LIFT"
            , centeredText "245" "#2dd4bf" "16" "A RETRO ELM PLATFORMER"
            , centeredText "295" "#e2e8f0" "15" "COLLECT ALL GOLDEN EGGS ON EACH LEVEL"
            , centeredText "325" "#f472b6" "15" "JUMP ONTO MOVING LIFTS TO CROSS HAZARD PITS!"
            , centeredText "355" "#f87171" "14" "MISSING A LIFT OR TOUCHING A HEN COSTS A LIFE"
            , centeredText "400" "#94a3b8" "14" "ARROWS / WASD: MOVE & CLIMB  |  SPACE: JUMP  |  P: PAUSE"
            , g [ onClick StartGame, Svg.Attributes.cursor "pointer" ]
                [ rect [ x "290", y "420", width "220", height "38", rx "6", fill "#2dd4bf" ] []
                , centeredText "445" "#0b0d17" "18" "PRESS SPACE TO START"
                ]
            ]

        Paused ->
            [ rect [ x "220", y "220", width "360", height "140", rx "10", fill "rgba(11, 13, 23, 0.9)", stroke "#38bdf8", strokeWidth "3" ] []
            , centeredText "275" "#38bdf8" "32" "PAUSED"
            , centeredText "320" "#e2e8f0" "15" "PRESS P TO RESUME  |  R TO RESTART"
            ]

        Dying _ ->
            [ rect [ x "180", y "235", width "440", height "95", rx "10", fill "rgba(11, 13, 23, 0.88)", stroke "#f43f5e", strokeWidth "3" ] []
            , centeredText "278" "#f43f5e" "24" "LIFE LOST!"
            , centeredText "308" "#fda4af" "15" model.deathReason
            ]

        LevelClear _ ->
            [ rect [ x "180", y "225", width "440", height "120", rx "10", fill "rgba(11, 13, 23, 0.9)", stroke "#4ade80", strokeWidth "3" ] []
            , centeredText "275" "#4ade80" "28" "LEVEL COMPLETE!"
            , centeredText "312" "#facc15" "16" ("TIME BONUS: +" ++ String.fromInt (round model.bonusTimer * 10))
            ]

        GameOver ->
            [ rect [ x "180", y "185", width "440", height "220", rx "12", fill "rgba(11, 13, 23, 0.94)", stroke "#f43f5e", strokeWidth "3" ] []
            , centeredText "245" "#f43f5e" "38" "GAME OVER"
            , centeredText "292" "#f8fafc" "20" ("FINAL SCORE: " ++ String.fromInt model.score)
            , centeredText "325" "#38bdf8" "16" ("HIGH SCORE: " ++ String.fromInt model.highScore)
            , g [ onClick StartGame, Svg.Attributes.cursor "pointer" ]
                [ rect [ x "275", y "348", width "250", height "38", rx "6", fill "#facc15" ] []
                , centeredText "373" "#0b0d17" "17" "PRESS SPACE TO RETRY"
                ]
            ]

        Playing ->
            []


centeredText : String -> String -> String -> String -> Svg Msg
centeredText ty col sz label =
    text_
        [ x "400"
        , y ty
        , textAnchor "middle"
        , fill col
        , fontSize sz
        , fontFamily "Courier New, monospace"
        , fontWeight "bold"
        ]
        [ text label ]
