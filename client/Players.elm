module Players exposing (..)

import Color
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode exposing (Value)
import List.Extra


type alias Players =
    { player1 : Player
    , player2 : Player
    , player3 : Player
    , player4 : Player
    }


type alias Player =
    { id : PlayerIndex
    , score : Int

    -- A list of robots this player has queued to move, most recent first
    , queued : List Int
    }


type PlayerIndex
    = Player1
    | Player2
    | Player3
    | Player4


order : List PlayerIndex
order =
    [ Player1
    , Player2
    , Player3
    , Player4
    ]


init : Players
init =
    { player1 = { id = Player1, score = 0, queued = [] }
    , player2 = { id = Player2, score = 0, queued = [] }
    , player3 = { id = Player3, score = 0, queued = [] }
    , player4 = { id = Player4, score = 0, queued = [] }
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


fromNumber : Int -> PlayerIndex
fromNumber index =
    -- TODO propagate error instead of defaulting?
    List.Extra.getAt (index - 1) order |> Maybe.withDefault Player1


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


{-| Returns a list of players excluding the given ID
-}
others : PlayerIndex -> List PlayerIndex
others id =
    List.filter ((/=) id) order


queueFor : Int -> PlayerIndex -> Players -> Players
queueFor robotId playerId players =
    let
        player =
            get playerId players
    in
    set (queue robotId player) players


queue : Int -> Player -> Player
queue robotId player =
    { player | queued = robotId :: player.queued }



-- DECODERS


indexDecoder : Decoder PlayerIndex
indexDecoder =
    Decode.int |> Decode.map fromNumber



-- ENCODERS


indexEncoder : PlayerIndex -> Value
indexEncoder =
    toNumber >> Encode.int
