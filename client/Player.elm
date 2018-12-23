module Player exposing
    ( Player(..)
    , Players
    , color
    , nextTurn
    )

import Color
import Maybe.Extra
import Svg exposing (Svg)


type Player
    = Player1
    | Player2
    | Player3
    | Player4


type alias Players =
    { player1 : Int
    , player2 : Int
    , player3 : Int
    , player4 : Int
    }


color : Player -> String
color player =
    case player of
        Player1 ->
            Color.green

        Player2 ->
            Color.purple

        Player3 ->
            Color.cyan

        Player4 ->
            Color.red


nextTurn : Player -> Player
nextTurn player =
    case player of
        Player1 ->
            Player2

        Player2 ->
            Player3

        Player3 ->
            Player4

        Player4 ->
            Player1
