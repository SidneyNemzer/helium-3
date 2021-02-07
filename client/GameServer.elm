module GameServer exposing (..)

import ClientAction exposing (ClientAction)
import Dict exposing (Dict)
import Effect exposing (Effect(..), Timeline)
import HeliumGrid exposing (HeliumGrid)
import Json.Decode as Decode exposing (Error)
import Maybe.Extra
import Message exposing (ClientMessage)
import Players exposing (PlayerIndex(..), Players)
import Ports
import Process
import Random
import Robot exposing (Robot, State(..), Tool(..))
import ServerAction exposing (ServerAction)
import Task


type alias Flags =
    { seed : Int }


type alias Model =
    { robots : Dict Int Robot
    , helium : HeliumGrid
    , players : Players
    , timer : Timer
    , turn : PlayerIndex
    }


type Timer
    = Countdown
    | Turn


init : Flags -> ( Model, Cmd Msg )
init { seed } =
    let
        helium =
            Random.initialSeed seed
                |> Random.step HeliumGrid.generator
                |> Tuple.first
    in
    ( { robots = Robot.initAll
      , helium = helium
      , players = Players.init
      , turn = Player1
      , timer = Countdown
      }
    , Cmd.batch
        [ Process.sleep 6000
            |> Task.perform (\() -> Timer)
        , Message.sendServerMessage [] <| Message.Countdown Player1

        -- Commands are processed in reverse order, so this message
        -- is sent first. Maybe this could be more explicit, like
        -- providing a "sequence" number
        -- TODO start time
        , Message.sendServerMessage [] <| Message.Start 0 helium
        ]
    )


type Msg
    = OnClientMessage ClientMessage
    | DecodeError Error
    | Timer


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        OnClientMessage message ->
            case message of
                Message.Queue action ->
                    onActionReceived action model

        DecodeError error ->
            ( model, Ports.log (Decode.errorToString error) )

        Timer ->
            case model.timer of
                Countdown ->
                    let
                        ( newModel, wait, actions ) =
                            Dict.values model.robots
                                |> List.filter (\robot -> robot.owner == model.turn)
                                |> List.foldl performTurn ( model, 0, [] )

                        messageForPlayer : PlayerIndex -> Cmd msg
                        messageForPlayer player =
                            obfuscateActions model.robots actions player
                                |> Message.Actions model.turn
                                |> Message.sendServerMessage [ player ]
                    in
                    ( { newModel | timer = Turn }
                    , Cmd.batch
                        [ Process.sleep (toFloat wait)
                            |> Task.perform (\() -> Timer)
                        , Players.order
                            |> List.map messageForPlayer
                            |> Cmd.batch
                        ]
                    )

                Turn ->
                    let
                        turn =
                            Players.next model.turn
                    in
                    ( { model | turn = turn, timer = Countdown }
                    , Cmd.batch
                        [ Process.sleep 6000
                            -- server waits an extra second
                            |> Task.perform (\() -> Timer)
                        , Message.sendServerMessage [] <| Message.Countdown turn
                        ]
                    )


onActionReceived : ClientAction -> Model -> ( Model, Cmd Msg )
onActionReceived action model =
    ( updateRobot (ClientAction.id action) (Robot.queueAction action) model
    , Cmd.none
    )


performTurn : Robot -> ( Model, Int, List ServerAction ) -> ( Model, Int, List ServerAction )
performTurn robot ( model, wait1, actions ) =
    let
        ( newModel, wait2 ) =
            animate (Effect.fromRobot robot) 0 model
    in
    ( newModel
    , max wait1 wait2
    , List.append actions <|
        Maybe.Extra.toList <|
            Robot.toServerAction model.robots robot
    )


obfuscateActions : Dict Int Robot -> List ServerAction -> PlayerIndex -> List ServerAction
obfuscateActions robots actions player =
    List.map (obfuscateAction robots player) actions


obfuscateAction : Dict Int Robot -> PlayerIndex -> ServerAction -> ServerAction
obfuscateAction robots player action =
    let
        isOwner =
            Dict.get (ServerAction.id action) robots
                |> Maybe.map (.owner >> (==) player)
                |> Maybe.withDefault False
    in
    if isOwner then
        action

    else
        ServerAction.obfuscate action


{-| Note that the server ignores all `Wait` effects
-}
animate : Timeline -> Int -> Model -> ( Model, Int )
animate timeline totalWait model =
    case timeline of
        [] ->
            ( model, totalWait )

        next :: rest ->
            let
                ( newModel, extraTimeline, wait ) =
                    animateHelp next model
            in
            animate (extraTimeline ++ rest) (wait + totalWait) newModel


animateHelp : Effect -> Model -> ( Model, Timeline, Int )
animateHelp effect model =
    case effect of
        SetLocation id point ->
            ( updateRobot id (Robot.setLocation point) model, [], 0 )

        SetRotation id rotation ->
            ( updateRobot id (Robot.setRotation rotation) model, [], 0 )

        SetMinerActive id ->
            ( updateRobot id Robot.setMinerActive model, [], 0 )

        MineAt id point ->
            let
                ( ground, mined ) =
                    HeliumGrid.mine point model.helium
            in
            ( { model
                | helium = ground
                , players =
                    Dict.get id model.robots
                        |> Maybe.map (\robot -> Players.addScore robot.owner mined model.players)
                        |> Maybe.withDefault model.players
              }
                |> updateRobot id (\robot -> { robot | mined = robot.mined + mined })
            , []
            , 0
            )

        SetState id state ->
            ( updateRobot id (Robot.setState state) model, [], 0 )

        Impact point forceShield ->
            case Robot.getRobotAt point model.robots of
                Just robot ->
                    let
                        impacted =
                            Robot.impact forceShield robot

                        animation =
                            if impacted.state /= Robot.Destroyed then
                                [ Wait 1000
                                , SetState robot.id (Robot.removeShield impacted).state
                                ]

                            else
                                []
                    in
                    ( updateRobot robot.id (\_ -> impacted) model, animation, 0 )

                Nothing ->
                    ( model, [], 0 )

        Wait ms ->
            ( model, [], ms )


updateRobot : Int -> (Robot -> Robot) -> Model -> Model
updateRobot id fn model =
    { model | robots = Dict.update id (Maybe.map fn) model.robots }



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Message.receiveClientMessage OnClientMessage DecodeError
        ]
