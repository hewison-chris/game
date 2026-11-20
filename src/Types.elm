module Types exposing (..)


type GameStatus
    = TitleScreen
    | Playing
    | Paused
    | Dying Float
    | LevelClear Float
    | GameOver


type Facing
    = Left
    | Right


type alias Keys =
    { left : Bool
    , right : Bool
    , up : Bool
    , down : Bool
    , jump : Bool
    }


type alias Player =
    { x : Float
    , y : Float
    , vx : Float
    , vy : Float
    , width : Float
    , height : Float
    , onGround : Bool
    , onLadder : Bool
    , onLiftId : Maybe Int
    , facing : Facing
    , coyoteTimer : Float
    , jumpBufferTimer : Float
    , ladderCooldown : Float
    , walkFrame : Float
    }


type alias Platform =
    { x : Float
    , y : Float
    , width : Float
    , height : Float
    }


type alias Ladder =
    { x : Float
    , topY : Float
    , bottomY : Float
    , width : Float
    }


type LiftAxis
    = Vertical
    | Horizontal


type alias Lift =
    { id : Int
    , x : Float
    , y : Float
    , width : Float
    , height : Float
    , axis : LiftAxis
    , minPos : Float
    , maxPos : Float
    , speed : Float
    , dir : Float
    , dx : Float
    , dy : Float
    }


type alias Hazard =
    { x : Float
    , y : Float
    , width : Float
    , height : Float
    }


type alias Egg =
    { id : Int
    , x : Float
    , y : Float
    , collected : Bool
    }


type alias Seed =
    { id : Int
    , x : Float
    , y : Float
    , collected : Bool
    }


type alias Enemy =
    { id : Int
    , x : Float
    , y : Float
    , width : Float
    , height : Float
    , minX : Float
    , maxX : Float
    , speed : Float
    , dir : Float
    , animTimer : Float
    }


type alias LevelData =
    { name : String
    , spawnX : Float
    , spawnY : Float
    , platforms : List Platform
    , ladders : List Ladder
    , lifts : List Lift
    , hazards : List Hazard
    , eggs : List Egg
    , seeds : List Seed
    , enemies : List Enemy
    }


type alias Particle =
    { x : Float
    , y : Float
    , vx : Float
    , vy : Float
    , life : Float
    , maxLife : Float
    , size : Float
    , color : String
    }


type alias ScorePopup =
    { x : Float
    , y : Float
    , text : String
    , color : String
    , life : Float
    , maxLife : Float
    }


type alias Model =
    { status : GameStatus
    , levelIndex : Int
    , loopCount : Int
    , score : Int
    , highScore : Int
    , lives : Int
    , bonusTimer : Float
    , player : Player
    , level : LevelData
    , keys : Keys
    , deathReason : String
    , animClock : Float
    , particles : List Particle
    , popups : List ScorePopup
    }


type Msg
    = Tick Float
    | KeyDown String
    | KeyUp String
    | StartGame
