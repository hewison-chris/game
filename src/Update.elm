module Update exposing (init, update)

import Levels exposing (getLevel)
import Types exposing (..)


arenaWidth : Float
arenaWidth =
    800


arenaHeight : Float
arenaHeight =
    600


gravity : Float
gravity =
    1150


maxFallSpeed : Float
maxFallSpeed =
    640


jumpVelocity : Float
jumpVelocity =
    -445


moveSpeed : Float
moveSpeed =
    210


climbSpeed : Float
climbSpeed =
    150


emptyKeys : Keys
emptyKeys =
    { left = False
    , right = False
    , up = False
    , down = False
    , jump = False
    }


makePlayer : Float -> Float -> Player
makePlayer sx sy =
    { x = sx
    , y = sy
    , vx = 0
    , vy = 0
    , width = 24
    , height = 32
    , onGround = False
    , onLadder = False
    , onLiftId = Nothing
    , facing = Right
    , coyoteTimer = 0
    , jumpBufferTimer = 0
    , ladderCooldown = 0
    , walkFrame = 0
    }


init : () -> ( Model, Cmd Msg )
init _ =
    let
        lvl =
            getLevel 0 0
    in
    ( { status = TitleScreen
      , levelIndex = 0
      , loopCount = 0
      , score = 0
      , highScore = 0
      , lives = 3
      , bonusTimer = 100
      , player = makePlayer lvl.spawnX lvl.spawnY
      , level = lvl
      , keys = emptyKeys
      , deathReason = ""
      , animClock = 0
      , particles = []
      , popups = []
      }
    , Cmd.none
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        StartGame ->
            ( startNewGame model, Cmd.none )

        KeyDown key ->
            ( handleKeyDown key model, Cmd.none )

        KeyUp key ->
            ( handleKeyUp key model, Cmd.none )

        Tick dtMs ->
            let
                dt =
                    min 0.033 (dtMs / 1000)
            in
            ( stepGame dt model, Cmd.none )


startNewGame : Model -> Model
startNewGame model =
    let
        lvl =
            getLevel 0 0
    in
    { model
        | status = Playing
        , levelIndex = 0
        , loopCount = 0
        , score = 0
        , lives = 3
        , bonusTimer = 100
        , player = makePlayer lvl.spawnX lvl.spawnY
        , level = lvl
        , keys = emptyKeys
        , deathReason = ""
        , particles = []
        , popups = []
    }


handleKeyDown : String -> Model -> Model
handleKeyDown rawKey model =
    let
        key =
            String.toLower rawKey

        keys =
            model.keys
    in
    case model.status of
        TitleScreen ->
            if key == " " || key == "enter" then
                startNewGame model

            else
                model

        GameOver ->
            if key == " " || key == "enter" then
                startNewGame model

            else
                model

        Paused ->
            if key == "p" || key == "escape" then
                { model | status = Playing }

            else if key == "r" then
                startNewGame model

            else
                model

        Playing ->
            if key == "p" || key == "escape" then
                { model | status = Paused }

            else if key == "r" then
                startNewGame model

            else
                let
                    newKeys =
                        updateKeyState key True keys

                    p =
                        model.player

                    newPlayer =
                        if key == " " || key == "z" then
                            { p | jumpBufferTimer = 0.12 }

                        else
                            p
                in
                { model | keys = newKeys, player = newPlayer }

        _ ->
            { model | keys = updateKeyState key True keys }


handleKeyUp : String -> Model -> Model
handleKeyUp rawKey model =
    let
        key =
            String.toLower rawKey
    in
    { model | keys = updateKeyState key False model.keys }


updateKeyState : String -> Bool -> Keys -> Keys
updateKeyState key isDown keys =
    case key of
        "arrowleft" ->
            { keys | left = isDown }

        "a" ->
            { keys | left = isDown }

        "arrowright" ->
            { keys | right = isDown }

        "d" ->
            { keys | right = isDown }

        "arrowup" ->
            { keys | up = isDown }

        "w" ->
            { keys | up = isDown }

        "arrowdown" ->
            { keys | down = isDown }

        "s" ->
            { keys | down = isDown }

        " " ->
            { keys | jump = isDown }

        "z" ->
            { keys | jump = isDown }

        _ ->
            keys


stepGame : Float -> Model -> Model
stepGame dt model =
    let
        clocked =
            { model
                | animClock = model.animClock + dt
                , particles = stepParticles dt model.particles
                , popups = stepPopups dt model.popups
            }
    in
    case clocked.status of
        TitleScreen ->
            -- Animate lifts on title screen for visual flair
            let
                lvl =
                    clocked.level

                newLifts =
                    List.map (stepLift dt) lvl.lifts
            in
            { clocked | level = { lvl | lifts = newLifts } }

        Paused ->
            clocked

        GameOver ->
            clocked

        Dying timer ->
            let
                remaining =
                    timer - dt
            in
            if remaining <= 0 then
                if clocked.lives <= 0 then
                    { clocked | status = GameOver }

                else
                    respawnPlayer clocked

            else
                { clocked | status = Dying remaining }

        LevelClear timer ->
            let
                remaining =
                    timer - dt
            in
            if remaining <= 0 then
                advanceLevel clocked

            else
                { clocked | status = LevelClear remaining }

        Playing ->
            stepPlaying dt clocked


respawnPlayer : Model -> Model
respawnPlayer model =
    let
        freshLevel =
            getLevel model.levelIndex model.loopCount

        oldLevel =
            model.level

        -- Keep collected eggs & seeds, reset enemies & lifts
        mergedEggs =
            List.map
                (\e ->
                    case List.filter (\oe -> oe.id == e.id) oldLevel.eggs of
                        oe :: _ ->
                            { e | collected = oe.collected }

                        [] ->
                            e
                )
                freshLevel.eggs

        mergedSeeds =
            List.map
                (\s ->
                    case List.filter (\os -> os.id == s.id) oldLevel.seeds of
                        os :: _ ->
                            { s | collected = os.collected }

                        [] ->
                            s
                )
                freshLevel.seeds

        restoredLevel =
            { freshLevel | eggs = mergedEggs, seeds = mergedSeeds }
    in
    { model
        | status = Playing
        , bonusTimer = 100
        , player = makePlayer restoredLevel.spawnX restoredLevel.spawnY
        , level = restoredLevel
        , deathReason = ""
    }


advanceLevel : Model -> Model
advanceLevel model =
    let
        nextRaw =
            model.levelIndex + 1

        nextIdx =
            modBy Levels.totalLevels nextRaw

        nextLoop =
            if nextIdx == 0 then
                model.loopCount + 1

            else
                model.loopCount

        lvl =
            getLevel nextIdx nextLoop
    in
    { model
        | status = Playing
        , levelIndex = nextIdx
        , loopCount = nextLoop
        , bonusTimer = 100
        , player = makePlayer lvl.spawnX lvl.spawnY
        , level = lvl
        , deathReason = ""
    }


stepPlaying : Float -> Model -> Model
stepPlaying dt model =
    let
        lvl =
            model.level

        newLifts =
            List.map (stepLift dt) lvl.lifts

        newEnemies =
            List.map (stepEnemy dt) lvl.enemies

        newBonus =
            max 0 (model.bonusTimer - dt * 1.8)

        updatedPlayer =
            stepPlayer dt model.keys newLifts lvl.platforms lvl.ladders model.player

        ( collectedEggs, eggPoints, eggHits ) =
            collectEggs updatedPlayer lvl.eggs

        ( collectedSeeds, seedPoints, seedHits ) =
            collectSeeds updatedPlayer lvl.seeds

        jumpParticles =
            if model.player.onGround && not updatedPlayer.onGround && updatedPlayer.vy < -100 then
                spawnDust (updatedPlayer.x + updatedPlayer.width / 2) (updatedPlayer.y + updatedPlayer.height)

            else if not model.player.onGround && updatedPlayer.onGround then
                spawnDust (updatedPlayer.x + updatedPlayer.width / 2) (updatedPlayer.y + updatedPlayer.height)

            else
                []

        eggParticles =
            List.concatMap (\pos -> spawnBurst pos.x pos.y "#fde047" "#fef08a" 10) eggHits

        seedParticles =
            List.concatMap (\pos -> spawnBurst pos.x pos.y "#4ade80" "#bbf7d0" 7) seedHits

        eggPopups =
            List.map (\pos -> { x = pos.x, y = pos.y - 10, text = "+100", color = "#fde047", life = 0.85, maxLife = 0.85 }) eggHits

        seedPopups =
            List.map (\pos -> { x = pos.x, y = pos.y - 10, text = "+50", color = "#4ade80", life = 0.75, maxLife = 0.75 }) seedHits

        newParticles =
            model.particles ++ jumpParticles ++ eggParticles ++ seedParticles

        newPopups =
            model.popups ++ eggPopups ++ seedPopups

        newScore =
            model.score + eggPoints + seedPoints

        newHigh =
            max model.highScore newScore

        newLevel =
            { lvl
                | lifts = newLifts
                , enemies = newEnemies
                , eggs = collectedEggs
                , seeds = collectedSeeds
            }

        allEggsCollected =
            List.all .collected collectedEggs
    in
    if newBonus <= 0 then
        triggerDeath "TIME'S UP!" { model | level = newLevel, score = newScore, highScore = newHigh, bonusTimer = 0, particles = newParticles, popups = newPopups }

    else if hitHazard updatedPlayer lvl.hazards then
        triggerDeath "FELL INTO THE HAZARD PIT!" { model | level = newLevel, player = updatedPlayer, score = newScore, highScore = newHigh, bonusTimer = newBonus, particles = newParticles, popups = newPopups }

    else if updatedPlayer.y > arenaHeight + 10 then
        triggerDeath "MISSED THE LIFT!" { model | level = newLevel, player = updatedPlayer, score = newScore, highScore = newHigh, bonusTimer = newBonus, particles = newParticles, popups = newPopups }

    else if hitEnemy updatedPlayer newEnemies then
        triggerDeath "CAUGHT BY A HEN!" { model | level = newLevel, player = updatedPlayer, score = newScore, highScore = newHigh, bonusTimer = newBonus, particles = newParticles, popups = newPopups }

    else if allEggsCollected then
        let
            timeBonus =
                round newBonus * 10

            finalScore =
                newScore + timeBonus
        in
        { model
            | status = LevelClear 1.8
            , level = newLevel
            , player = updatedPlayer
            , score = finalScore
            , highScore = max newHigh finalScore
            , bonusTimer = newBonus
            , particles = newParticles ++ spawnBurst (updatedPlayer.x + 12) (updatedPlayer.y + 16) "#2dd4bf" "#fde047" 18
            , popups = newPopups
        }

    else
        { model
            | level = newLevel
            , player = updatedPlayer
            , score = newScore
            , highScore = newHigh
            , bonusTimer = newBonus
            , particles = newParticles
            , popups = newPopups
        }


triggerDeath : String -> Model -> Model
triggerDeath reason model =
    let
        px =
            model.player.x + model.player.width / 2

        py =
            model.player.y + model.player.height / 2
    in
    { model
        | status = Dying 1.25
        , lives = model.lives - 1
        , deathReason = reason
        , particles = model.particles ++ spawnBurst px py "#f43f5e" "#facc15" 16
    }


stepLift : Float -> Lift -> Lift
stepLift dt lift =
    case lift.axis of
        Vertical ->
            let
                rawY =
                    lift.y + lift.dir * lift.speed * dt

                ( clampedY, newDir ) =
                    if rawY <= lift.minPos then
                        ( lift.minPos, 1 )

                    else if rawY >= lift.maxPos then
                        ( lift.maxPos, -1 )

                    else
                        ( rawY, lift.dir )
            in
            { lift
                | y = clampedY
                , dir = newDir
                , dx = 0
                , dy = clampedY - lift.y
            }

        Horizontal ->
            let
                rawX =
                    lift.x + lift.dir * lift.speed * dt

                ( clampedX, newDir ) =
                    if rawX <= lift.minPos then
                        ( lift.minPos, 1 )

                    else if rawX >= lift.maxPos then
                        ( lift.maxPos, -1 )

                    else
                        ( rawX, lift.dir )
            in
            { lift
                | x = clampedX
                , dir = newDir
                , dx = clampedX - lift.x
                , dy = 0
            }


stepEnemy : Float -> Enemy -> Enemy
stepEnemy dt enemy =
    let
        rawX =
            enemy.x + enemy.dir * enemy.speed * dt

        ( clampedX, newDir ) =
            if rawX <= enemy.minX then
                ( enemy.minX, 1 )

            else if rawX >= enemy.maxX then
                ( enemy.maxX, -1 )

            else
                ( rawX, enemy.dir )
    in
    { enemy
        | x = clampedX
        , dir = newDir
        , animTimer = enemy.animTimer + dt * 8
    }


stepPlayer : Float -> Keys -> List Lift -> List Platform -> List Ladder -> Player -> Player
stepPlayer dt keys lifts platforms ladders player =
    let
        -- 1. Apply lift carry if standing on a lift
        carriedPlayer =
            case player.onLiftId of
                Just lid ->
                    case List.filter (\l -> l.id == lid) lifts of
                        lift :: _ ->
                            { player
                                | x = clamp 0 (arenaWidth - player.width) (player.x + lift.dx)
                                , y = player.y + lift.dy
                            }

                        [] ->
                            { player | onLiftId = Nothing }

                Nothing ->
                    player

        -- 2. Decrement timers
        coyote =
            if carriedPlayer.onGround then
                0.09

            else
                max 0 (carriedPlayer.coyoteTimer - dt)

        jumpBuf =
            max 0 (carriedPlayer.jumpBufferTimer - dt)

        ladCool =
            max 0 (carriedPlayer.ladderCooldown - dt)

        pTimed =
            { carriedPlayer
                | coyoteTimer = coyote
                , jumpBufferTimer = jumpBuf
                , ladderCooldown = ladCool
            }

        -- 3. Check ladder overlap
        pCenterX =
            pTimed.x + pTimed.width / 2

        pBottom =
            pTimed.y + pTimed.height

        maybeLadder =
            ladders
                |> List.filter
                    (\lad ->
                        let
                            ladCenterX =
                                lad.x + lad.width / 2
                        in
                        abs (pCenterX - ladCenterX) < 17
                            && pBottom >= lad.topY - 2
                            && pTimed.y <= lad.bottomY + 2
                    )
                |> List.head

        wantsJump =
            pTimed.jumpBufferTimer > 0 && (pTimed.onGround || pTimed.coyoteTimer > 0 || pTimed.onLadder)

        canGrabLadder =
            pTimed.ladderCooldown <= 0 && pTimed.vy >= 0 && not keys.jump

        wantsLadder =
            if wantsJump then
                False

            else
                case maybeLadder of
                    Just lad ->
                        if pTimed.onLadder then
                            True

                        else if canGrabLadder && keys.up && pBottom > lad.topY + 4 then
                            True

                        else if canGrabLadder && keys.down && pBottom <= lad.bottomY - 2 then
                            True

                        else
                            False

                    Nothing ->
                        False
    in
    if wantsJump then
        stepFreeMove dt
            keys
            lifts
            platforms
            { pTimed
                | onLadder = False
                , coyoteTimer = max 0.09 pTimed.coyoteTimer
                , ladderCooldown = 0.28
            }

    else if wantsLadder then
        case maybeLadder of
            Just lad ->
                stepOnLadder dt keys lad pTimed

            Nothing ->
                stepFreeMove dt keys lifts platforms { pTimed | onLadder = False }

    else
        stepFreeMove dt keys lifts platforms { pTimed | onLadder = False }


stepOnLadder : Float -> Keys -> Ladder -> Player -> Player
stepOnLadder dt keys lad player =
    if player.jumpBufferTimer > 0 then
        { player
            | onLadder = False
            , onGround = False
            , onLiftId = Nothing
            , vy = jumpVelocity
            , jumpBufferTimer = 0
            , coyoteTimer = 0
        }

    else
        let
            ladCenterX =
                lad.x + lad.width / 2

            targetX =
                ladCenterX - player.width / 2

            -- Gently snap toward ladder center, or allow slight horizontal exit
            horizInput =
                (if keys.left then
                    -1

                 else
                    0
                )
                    + (if keys.right then
                        1

                       else
                        0
                      )

            newX =
                if horizInput /= 0 then
                    clamp 0 (arenaWidth - player.width) (player.x + toFloat horizInput * 110 * dt)

                else
                    player.x + (targetX - player.x) * min 1 (dt * 12)

            vertInput =
                (if keys.up then
                    -1

                 else
                    0
                )
                    + (if keys.down then
                        1

                       else
                        0
                      )

            newY =
                player.y + toFloat vertInput * climbSpeed * dt

            clampedY =
                if newY + player.height > lad.bottomY then
                    lad.bottomY - player.height

                else
                    newY

            stillOnLadder =
                (clampedY + player.height) >= lad.topY

            finalY =
                if not stillOnLadder && vertInput < 0 then
                    lad.topY - player.height

                else
                    clampedY

            newFacing =
                if horizInput < 0 then
                    Left

                else if horizInput > 0 then
                    Right

                else
                    player.facing
        in
        { player
            | x = newX
            , y = finalY
            , vx = 0
            , vy = 0
            , onLadder = stillOnLadder
            , onGround = not stillOnLadder
            , onLiftId = Nothing
            , facing = newFacing
            , walkFrame =
                if vertInput /= 0 then
                    player.walkFrame + dt * 10

                else
                    player.walkFrame
        }


stepFreeMove : Float -> Keys -> List Lift -> List Platform -> Player -> Player
stepFreeMove dt keys lifts platforms player =
    let
        horiz =
            (if keys.left then
                -1

             else
                0
            )
                + (if keys.right then
                    1

                   else
                    0
                  )

        newVx =
            toFloat horiz * moveSpeed

        newFacing =
            if horiz < 0 then
                Left

            else if horiz > 0 then
                Right

            else
                player.facing

        ( jumpedVy, usedJump ) =
            if player.jumpBufferTimer > 0 && player.coyoteTimer > 0 then
                ( jumpVelocity, True )

            else
                ( min maxFallSpeed (player.vy + gravity * dt), False )

        newX =
            clamp 0 (arenaWidth - player.width) (player.x + newVx * dt)

        oldBottom =
            player.y + player.height

        rawNewY =
            player.y + jumpedVy * dt

        newBottom =
            rawNewY + player.height

        -- Check landing on lifts first, then static platforms
        landedLift =
            if jumpedVy >= 0 then
                lifts
                    |> List.filter
                        (\l ->
                            (newX + player.width > l.x + 3)
                                && (newX < l.x + l.width - 3)
                                && (oldBottom <= l.y + 10 + max 0 l.dy)
                                && (newBottom >= l.y)
                        )
                    |> List.head

            else
                Nothing

        landedPlatform =
            if jumpedVy >= 0 && landedLift == Nothing then
                platforms
                    |> List.filter
                        (\p ->
                            (newX + player.width > p.x + 3)
                                && (newX < p.x + p.width - 3)
                                && (oldBottom <= p.y + 8)
                                && (newBottom >= p.y)
                        )
                    |> List.head

            else
                Nothing

        landing =
            case landedLift of
                Just l ->
                    { y = l.y - player.height, vy = 0, grounded = True, liftId = Just l.id }

                Nothing ->
                    case landedPlatform of
                        Just p ->
                            { y = p.y - player.height, vy = 0, grounded = True, liftId = Nothing }

                        Nothing ->
                            { y = rawNewY, vy = jumpedVy, grounded = False, liftId = Nothing }

        newWalkFrame =
            if landing.grounded && horiz /= 0 then
                player.walkFrame + dt * 12

            else
                player.walkFrame
    in
    { player
        | x = newX
        , y = landing.y
        , vx = newVx
        , vy = landing.vy
        , onGround = landing.grounded
        , onLadder = False
        , onLiftId = landing.liftId
        , facing = newFacing
        , coyoteTimer =
            if usedJump then
                0

            else
                player.coyoteTimer
        , jumpBufferTimer =
            if usedJump then
                0

            else
                player.jumpBufferTimer
        , walkFrame = newWalkFrame
    }


collectEggs : Player -> List Egg -> ( List Egg, Int, List { x : Float, y : Float } )
collectEggs player eggs =
    List.foldr
        (\egg ( acc, pts, hits ) ->
            if not egg.collected && overlapsCircle player egg.x egg.y 16 then
                ( { egg | collected = True } :: acc, pts + 100, { x = egg.x, y = egg.y } :: hits )

            else
                ( egg :: acc, pts, hits )
        )
        ( [], 0, [] )
        eggs


collectSeeds : Player -> List Seed -> ( List Seed, Int, List { x : Float, y : Float } )
collectSeeds player seeds =
    List.foldr
        (\seed ( acc, pts, hits ) ->
            if not seed.collected && overlapsCircle player seed.x seed.y 14 then
                ( { seed | collected = True } :: acc, pts + 50, { x = seed.x, y = seed.y } :: hits )

            else
                ( seed :: acc, pts, hits )
        )
        ( [], 0, [] )
        seeds


stepParticles : Float -> List Particle -> List Particle
stepParticles dt particles =
    particles
        |> List.filterMap
            (\p ->
                let
                    newLife =
                        p.life - dt
                in
                if newLife <= 0 then
                    Nothing

                else
                    Just
                        { p
                            | x = p.x + p.vx * dt
                            , y = p.y + p.vy * dt
                            , vy = p.vy + 260 * dt
                            , life = newLife
                        }
            )


stepPopups : Float -> List ScorePopup -> List ScorePopup
stepPopups dt popups =
    popups
        |> List.filterMap
            (\pop ->
                let
                    newLife =
                        pop.life - dt
                in
                if newLife <= 0 then
                    Nothing

                else
                    Just
                        { pop
                            | y = pop.y - 38 * dt
                            , life = newLife
                        }
            )


spawnDust : Float -> Float -> List Particle
spawnDust x y =
    [ { x = x - 6, y = y - 2, vx = -48, vy = -40, life = 0.28, maxLife = 0.28, size = 3.2, color = "#94a3b8" }
    , { x = x, y = y - 1, vx = 0, vy = -28, life = 0.24, maxLife = 0.24, size = 2.6, color = "#cbd5e1" }
    , { x = x + 6, y = y - 2, vx = 48, vy = -40, life = 0.28, maxLife = 0.28, size = 3.2, color = "#94a3b8" }
    ]


spawnBurst : Float -> Float -> String -> String -> Int -> List Particle
spawnBurst x y colA colB count =
    List.range 0 (count - 1)
        |> List.map
            (\i ->
                let
                    angle =
                        (toFloat i / toFloat count) * 2 * pi

                    speed =
                        if modBy 2 i == 0 then
                            115

                        else
                            75

                    col =
                        if modBy 2 i == 0 then
                            colA

                        else
                            colB
                in
                { x = x
                , y = y
                , vx = cos angle * speed
                , vy = sin angle * speed - 45
                , life = 0.55
                , maxLife = 0.55
                , size =
                    if modBy 2 i == 0 then
                        3.5

                    else
                        2.5
                , color = col
                }
            )


overlapsCircle : Player -> Float -> Float -> Float -> Bool
overlapsCircle player cx cy radius =
    let
        px =
            player.x + player.width / 2

        py =
            player.y + player.height / 2

        dx =
            px - cx

        dy =
            py - cy
    in
    (dx * dx + dy * dy) <= ((radius + 12) * (radius + 12))


hitHazard : Player -> List Hazard -> Bool
hitHazard player hazards =
    List.any
        (\h ->
            rectsOverlap
                (player.x + 4)
                (player.y + 4)
                (player.width - 8)
                (player.height - 4)
                h.x
                h.y
                h.width
                h.height
        )
        hazards


hitEnemy : Player -> List Enemy -> Bool
hitEnemy player enemies =
    List.any
        (\e ->
            rectsOverlap
                (player.x + 5)
                (player.y + 4)
                (player.width - 10)
                (player.height - 8)
                (e.x + 4)
                (e.y + 4)
                (e.width - 8)
                (e.height - 6)
        )
        enemies


rectsOverlap : Float -> Float -> Float -> Float -> Float -> Float -> Float -> Float -> Bool
rectsOverlap x1 y1 w1 h1 x2 y2 w2 h2 =
    x1 < (x2 + w2) && (x1 + w1) > x2 && y1 < (y2 + h2) && (y1 + h1) > y2
