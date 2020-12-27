module Players exposing (..)

import Color


type alias Players =
    { player1 : Player
    , player2 : Player
    , player3 : Player
    , player4 : Player
    }


type alias Player =
    { score : Int
    }


type PlayerIndex
    = Player1
    | Player2
    | Player3
    | Player4


init : Players
init =
    { player1 = { score = 0 }
    , player2 = { score = 0 }
    , player3 = { score = 0 }
    , player4 = { score = 0 }
    }


color : PlayerIndex -> String
color player =
    case player of
        Player1 ->
            Color.cyan

        Player2 ->
            Color.blue

        Player3 ->
            Color.green

        Player4 ->
            Color.red
