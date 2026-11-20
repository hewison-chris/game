module Levels exposing (getLevel, totalLevels)

import Types exposing (..)


totalLevels : Int
totalLevels =
    3


getLevel : Int -> Int -> LevelData
getLevel index loopCount =
    let
        speedMult =
            1.0 + toFloat loopCount * 0.18

        base =
            case modBy totalLevels index of
                0 ->
                    level1

                1 ->
                    level2

                _ ->
                    level3
    in
    { base
        | lifts =
            List.map (\l -> { l | speed = l.speed * speedMult }) base.lifts
        , enemies =
            List.map (\e -> { e | speed = e.speed * speedMult }) base.enemies
    }


level1 : LevelData
level1 =
    { name = "1. THE HENHOUSE SHAFTS"
    , spawnX = 60
    , spawnY = 508
    , platforms =
        [ -- Bottom left & right decks
          { x = 20, y = 540, width = 190, height = 16 }
        , { x = 590, y = 540, width = 190, height = 16 }
        , -- Mid left & right decks
          { x = 20, y = 370, width = 190, height = 16 }
        , { x = 590, y = 370, width = 190, height = 16 }
        , -- Center island (lift access only!)
          { x = 340, y = 390, width = 120, height = 16 }
        , -- Top left, center, right decks
          { x = 20, y = 210, width = 190, height = 16 }
        , { x = 335, y = 210, width = 130, height = 16 }
        , { x = 590, y = 210, width = 190, height = 16 }
        ]
    , ladders =
        [ { x = 60, topY = 370, bottomY = 540, width = 34 }
        , { x = 150, topY = 210, bottomY = 370, width = 34 }
        , { x = 706, topY = 370, bottomY = 540, width = 34 }
        , { x = 620, topY = 210, bottomY = 370, width = 34 }
        ]
    , lifts =
        [ { id = 1
          , x = 242
          , y = 480
          , width = 68
          , height = 14
          , axis = Vertical
          , minPos = 215
          , maxPos = 535
          , speed = 95
          , dir = -1
          , dx = 0
          , dy = 0
          }
        , { id = 2
          , x = 490
          , y = 240
          , width = 68
          , height = 14
          , axis = Vertical
          , minPos = 215
          , maxPos = 535
          , speed = 95
          , dir = 1
          , dx = 0
          , dy = 0
          }
        ]
    , hazards =
        [ { x = 210, y = 572, width = 380, height = 28 }
        ]
    , eggs =
        [ { id = 1, x = 115, y = 342, collected = False }
        , { id = 2, x = 55, y = 182, collected = False }
        , { id = 3, x = 368, y = 362, collected = False }
        , { id = 4, x = 432, y = 362, collected = False }
        , { id = 5, x = 400, y = 182, collected = False }
        , { id = 6, x = 730, y = 182, collected = False }
        , { id = 7, x = 680, y = 342, collected = False }
        , { id = 8, x = 660, y = 512, collected = False }
        ]
    , seeds =
        [ { id = 1, x = 180, y = 518, collected = False }
        , { id = 2, x = 185, y = 188, collected = False }
        , { id = 3, x = 615, y = 188, collected = False }
        , { id = 4, x = 740, y = 518, collected = False }
        ]
    , enemies =
        [ { id = 1
          , x = 90
          , y = 340
          , width = 26
          , height = 30
          , minX = 28
          , maxX = 182
          , speed = 68
          , dir = 1
          , animTimer = 0
          }
        , { id = 2
          , x = 650
          , y = 340
          , width = 26
          , height = 30
          , minX = 596
          , maxX = 750
          , speed = 75
          , dir = -1
          , animTimer = 0
          }
        ]
    }


level2 : LevelData
level2 =
    { name = "2. DOUBLE ELEVATOR"
    , spawnX = 50
    , spawnY = 508
    , platforms =
        [ -- Left tower decks
          { x = 20, y = 540, width = 145, height = 16 }
        , { x = 20, y = 385, width = 145, height = 16 }
        , { x = 20, y = 225, width = 145, height = 16 }
        , -- Center upper & lower islands
          { x = 465, y = 415, width = 100, height = 16 }
        , { x = 305, y = 225, width = 180, height = 16 }
        , -- Right tower decks
          { x = 665, y = 350, width = 115, height = 16 }
        , { x = 665, y = 195, width = 115, height = 16 }
        ]
    , ladders =
        [ { x = 55, topY = 385, bottomY = 540, width = 34 }
        , { x = 110, topY = 225, bottomY = 385, width = 34 }
        , { x = 710, topY = 195, bottomY = 350, width = 34 }
        ]
    , lifts =
        [ { id = 1
          , x = 192
          , y = 480
          , width = 68
          , height = 14
          , axis = Vertical
          , minPos = 220
          , maxPos = 535
          , speed = 110
          , dir = -1
          , dx = 0
          , dy = 0
          }
        , { id = 2
          , x = 290
          , y = 415
          , width = 76
          , height = 14
          , axis = Horizontal
          , minPos = 275
          , maxPos = 385
          , speed = 95
          , dir = 1
          , dx = 0
          , dy = 0
          }
        , { id = 3
          , x = 582
          , y = 240
          , width = 68
          , height = 14
          , axis = Vertical
          , minPos = 195
          , maxPos = 480
          , speed = 115
          , dir = 1
          , dx = 0
          , dy = 0
          }
        ]
    , hazards =
        [ { x = 165, y = 572, width = 635, height = 28 }
        ]
    , eggs =
        [ { id = 1, x = 85, y = 357, collected = False }
        , { id = 2, x = 55, y = 197, collected = False }
        , { id = 3, x = 345, y = 197, collected = False }
        , { id = 4, x = 445, y = 197, collected = False }
        , { id = 5, x = 515, y = 387, collected = False }
        , { id = 6, x = 720, y = 322, collected = False }
        , { id = 7, x = 720, y = 167, collected = False }
        , { id = 8, x = 395, y = 197, collected = False }
        ]
    , seeds =
        [ { id = 1, x = 135, y = 518, collected = False }
        , { id = 2, x = 140, y = 198, collected = False }
        , { id = 3, x = 685, y = 168, collected = False }
        ]
    , enemies =
        [ { id = 1
          , x = 320
          , y = 195
          , width = 26
          , height = 30
          , minX = 310
          , maxX = 455
          , speed = 82
          , dir = 1
          , animTimer = 0
          }
        , { id = 2
          , x = 60
          , y = 195
          , width = 26
          , height = 30
          , minX = 24
          , maxX = 135
          , speed = 64
          , dir = -1
          , animTimer = 0
          }
        ]
    }


level3 : LevelData
level3 =
    { name = "3. THE SKY COOP"
    , spawnX = 388
    , spawnY = 498
    , platforms =
        [ -- Center spawn island
          { x = 340, y = 530, width = 120, height = 16 }
        , -- Left platforms
          { x = 25, y = 410, width = 165, height = 16 }
        , { x = 25, y = 230, width = 165, height = 16 }
        , -- Right platforms
          { x = 610, y = 410, width = 165, height = 16 }
        , { x = 610, y = 230, width = 165, height = 16 }
        , -- Center mid-high coop
          { x = 335, y = 340, width = 130, height = 16 }
        ]
    , ladders =
        [ { x = 60, topY = 230, bottomY = 410, width = 34 }
        , { x = 706, topY = 230, bottomY = 410, width = 34 }
        ]
    , lifts =
        [ { id = 1
          , x = 225
          , y = 480
          , width = 68
          , height = 14
          , axis = Vertical
          , minPos = 225
          , maxPos = 525
          , speed = 122
          , dir = -1
          , dx = 0
          , dy = 0
          }
        , { id = 2
          , x = 507
          , y = 240
          , width = 68
          , height = 14
          , axis = Vertical
          , minPos = 225
          , maxPos = 525
          , speed = 122
          , dir = 1
          , dx = 0
          , dy = 0
          }
        , { id = 3
          , x = 300
          , y = 195
          , width = 76
          , height = 14
          , axis = Horizontal
          , minPos = 260
          , maxPos = 465
          , speed = 115
          , dir = 1
          , dx = 0
          , dy = 0
          }
        ]
    , hazards =
        [ { x = 0, y = 572, width = 340, height = 28 }
        , { x = 460, y = 572, width = 340, height = 28 }
        ]
    , eggs =
        [ { id = 1, x = 120, y = 382, collected = False }
        , { id = 2, x = 130, y = 202, collected = False }
        , { id = 3, x = 45, y = 202, collected = False }
        , { id = 4, x = 365, y = 312, collected = False }
        , { id = 5, x = 435, y = 312, collected = False }
        , { id = 6, x = 400, y = 155, collected = False }
        , { id = 7, x = 670, y = 202, collected = False }
        , { id = 8, x = 750, y = 202, collected = False }
        , { id = 9, x = 680, y = 382, collected = False }
        ]
    , seeds =
        [ { id = 1, x = 400, y = 508, collected = False }
        , { id = 2, x = 160, y = 388, collected = False }
        , { id = 3, x = 640, y = 388, collected = False }
        ]
    , enemies =
        [ { id = 1
          , x = 50
          , y = 380
          , width = 26
          , height = 30
          , minX = 30
          , maxX = 160
          , speed = 85
          , dir = 1
          , animTimer = 0
          }
        , { id = 2
          , x = 650
          , y = 380
          , width = 26
          , height = 30
          , minX = 615
          , maxX = 745
          , speed = 85
          , dir = -1
          , animTimer = 0
          }
        , { id = 3
          , x = 360
          , y = 310
          , width = 26
          , height = 30
          , minX = 340
          , maxX = 435
          , speed = 72
          , dir = 1
          , animTimer = 0
          }
        ]
    }
