module Model exposing (Model)

import Array exposing (Array)
import CountdownRing
import Matrix exposing (Matrix)
import Player exposing (Player)
import Robot exposing (Robot)


type alias Model =
    { turn : Player
    , turnCountdown : Maybe Float
    , countdownRing : CountdownRing.State
    , scorePlayer1 : Int
    , scorePlayer2 : Int
    , scorePlayer3 : Int
    , scorePlayer4 : Int
    , robots : Array Robot
    , helium3 : Matrix Int
    , selectedRobot : Maybe Int
    }
