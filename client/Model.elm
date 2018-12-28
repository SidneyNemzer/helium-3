module Model exposing (Countdown, Model)

import Array exposing (Array)
import Helium3Grid exposing (Helium3Grid)
import Player exposing (Player, Players)
import Robot exposing (Robot)
import Time exposing (Posix)


type Countdown
    = Start Posix
    | NextMove Posix
    | EndMove Posix


type alias Model =
    { turn : Player
    , countdown : Maybe Countdown
    , players : Players
    , robots : Array Robot
    , helium3 : Helium3Grid
    , selectedRobot : Maybe Int
    }
