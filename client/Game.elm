module Game exposing (Game, clearQueue, initRobots, queue)

import ClientAction exposing (ClientAction)
import Dict exposing (Dict)
import Players exposing (PlayerIndex(..), Players)
import Point
import Robot exposing (Robot)


type alias Game model =
    { model
        | robots : Dict Int Robot
        , players : Players
    }


initRobots : Dict Int Robot
initRobots =
    Dict.fromList
        [ ( 1, Robot.init 1 (Point.fromXY 2 0) Player1 0 )
        , ( 2, Robot.init 2 (Point.fromXY 2 1) Player1 0 )
        , ( 3, Robot.init 3 (Point.fromXY 2 2) Player1 45 )
        , ( 4, Robot.init 4 (Point.fromXY 0 2) Player1 90 )
        , ( 5, Robot.init 5 (Point.fromXY 1 2) Player1 90 )
        , ( 6, Robot.init 6 (Point.fromXY 17 0) Player2 180 )
        , ( 7, Robot.init 7 (Point.fromXY 17 1) Player2 180 )
        , ( 8, Robot.init 8 (Point.fromXY 17 2) Player2 135 )
        , ( 9, Robot.init 9 (Point.fromXY 18 2) Player2 90 )
        , ( 10, Robot.init 10 (Point.fromXY 19 2) Player2 90 )
        , ( 11, Robot.init 11 (Point.fromXY 17 19) Player3 180 )
        , ( 12, Robot.init 12 (Point.fromXY 17 18) Player3 180 )
        , ( 13, Robot.init 13 (Point.fromXY 17 17) Player3 225 )
        , ( 14, Robot.init 14 (Point.fromXY 18 17) Player3 270 )
        , ( 15, Robot.init 15 (Point.fromXY 19 17) Player3 270 )
        , ( 16, Robot.init 16 (Point.fromXY 0 17) Player4 270 )
        , ( 17, Robot.init 17 (Point.fromXY 1 17) Player4 270 )
        , ( 18, Robot.init 18 (Point.fromXY 2 17) Player4 315 )
        , ( 19, Robot.init 19 (Point.fromXY 2 18) Player4 0 )
        , ( 20, Robot.init 20 (Point.fromXY 2 19) Player4 0 )
        ]


clearQueue : PlayerIndex -> Game model -> Game model
clearQueue playerId game =
    { game | players = Players.clearQueueFor playerId game.players }


queue : ClientAction -> Game model -> Game model
queue action game =
    let
        robotId =
            ClientAction.id action

        players =
            case Dict.get robotId game.robots of
                Just { owner } ->
                    Players.queueFor robotId owner game.players

                Nothing ->
                    game.players
    in
    { game
        | robots =
            Dict.update robotId (Maybe.map (Robot.queue action)) game.robots
        , players = players
    }
        |> unqueueExtra


unqueueExtra : Game model -> Game model
unqueueExtra game =
    Players.order
        |> List.foldl unqueueExtraFor game


unqueueExtraFor : PlayerIndex -> Game model -> Game model
unqueueExtraFor playerId oldGame =
    let
        oldPlayer =
            Players.get playerId oldGame.players

        ( queued, extra ) =
            splitQueued oldPlayer.queued

        player =
            { oldPlayer | queued = queued }

        game =
            { oldGame | players = Players.set player oldGame.players }
    in
    List.foldl unqueue game extra


splitQueued : List Int -> ( List Int, List Int )
splitQueued robots =
    case robots of
        first :: second :: rest ->
            ( [ first, second ], rest )

        _ ->
            ( robots, [] )


unqueue : Int -> Game model -> Game model
unqueue robotId game =
    { game | robots = Dict.update robotId (Maybe.map Robot.unqueue) game.robots }
