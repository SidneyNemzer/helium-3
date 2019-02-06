module Model exposing (Model)

import Array exposing (Array)
import Matrix exposing (Matrix)
import Player exposing (Player)
import Robot exposing (Robot)


type alias Model =
    { turn : Player
    , turnCountdown : Maybe Float
    , scorePlayer1 : Int
    , scorePlayer2 : Int
    , scorePlayer3 : Int
    , scorePlayer4 : Int
    , robots : Array Robot
    , helium3 : Matrix Int
    , selectedRobot : Maybe Int
    }
