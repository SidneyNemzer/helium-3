module Game exposing (Game, clearQueue, queue)

import ClientAction exposing (ClientAction)
import Dict exposing (Dict)
import Players exposing (PlayerIndex, Players)
import Robot exposing (Robot)


type alias Game model =
    { model
        | robots : Dict Int Robot
        , players : Players
    }


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
            Dict.update robotId (Maybe.map (Robot.queueAction action)) game.robots
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
    { game | robots = Dict.update robotId (Maybe.map Robot.unqueueAction) game.robots }
