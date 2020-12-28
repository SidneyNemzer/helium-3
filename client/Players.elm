module Players exposing (..)

import Color


type alias Players =
    { player1 : Player
    , player2 : Player
    , player3 : Player
    , player4 : Player
    }


type alias Player =
    { id : PlayerIndex
    , score : Int
    }


type PlayerIndex
    = Player1
    | Player2
    | Player3
    | Player4


init : Players
init =
    { player1 = { id = Player1, score = 0 }
    , player2 = { id = Player2, score = 0 }
    , player3 = { id = Player3, score = 0 }
    , player4 = { id = Player4, score = 0 }
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


toNumber : PlayerIndex -> Int
toNumber index =
    case index of
        Player1 ->
            1

        Player2 ->
            2

        Player3 ->
            3

        Player4 ->
            4


get : PlayerIndex -> Players -> Player
get id players =
    case id of
        Player1 ->
            players.player1

        Player2 ->
            players.player2

        Player3 ->
            players.player3

        Player4 ->
            players.player4


set : Player -> Players -> Players
set player players =
    case player.id of
        Player1 ->
            { players | player1 = player }

        Player2 ->
            { players | player2 = player }

        Player3 ->
            { players | player3 = player }

        Player4 ->
            { players | player4 = player }


addScore : PlayerIndex -> Int -> Players -> Players
addScore id score players =
    let
        player =
            get id players
    in
    set { player | score = player.score + score } players


next : PlayerIndex -> PlayerIndex
next id =
    case id of
        Player1 ->
            Player2

        Player2 ->
            Player3

        Player3 ->
            Player4

        Player4 ->
            Player1
