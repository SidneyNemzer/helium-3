module Server exposing (..)

import Browser
import ClientAction exposing (ClientAction)
import Dict exposing (Dict)
import Effect exposing (Effect(..), Timeline)
import HeliumGrid exposing (HeliumGrid)
import Html exposing (Html, div)
import Json.Decode as Decode exposing (Error)
import Maybe.Extra
import Message exposing (ClientMessage)
import Platform
import Players exposing (Player, PlayerIndex(..), Players)
import Point exposing (Point)
import Ports
import Process
import Random
import Robot exposing (Robot, State(..), Tool(..))
import ServerAction exposing (ServerAction, obfuscate)
import Task


main : Program () Model Msg
main =
    Platform.worker
        { init = init
        , update = update
        , subscriptions = subscriptions
        }


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


init : () -> ( Model, Cmd Msg )
init () =
    ( { robots =
            Dict.fromList
                [ ( 1, Robot.init 1 (Point.fromXY 2 0) Player1 )
                , ( 2, Robot.init 2 (Point.fromXY 2 1) Player1 )
                , ( 3, Robot.init 3 (Point.fromXY 2 2) Player1 )
                , ( 4, Robot.init 4 (Point.fromXY 0 2) Player1 )
                , ( 5, Robot.init 5 (Point.fromXY 1 2) Player1 )
                , ( 6, Robot.init 6 (Point.fromXY 17 0) Player2 )
                , ( 7, Robot.init 7 (Point.fromXY 17 1) Player2 )
                , ( 8, Robot.init 8 (Point.fromXY 17 2) Player2 )
                , ( 9, Robot.init 9 (Point.fromXY 18 2) Player2 )
                , ( 10, Robot.init 10 (Point.fromXY 19 2) Player2 )
                , ( 11, Robot.init 11 (Point.fromXY 17 19) Player3 )
                , ( 12, Robot.init 12 (Point.fromXY 17 18) Player3 )
                , ( 13, Robot.init 13 (Point.fromXY 17 17) Player3 )
                , ( 14, Robot.init 14 (Point.fromXY 18 17) Player3 )
                , ( 15, Robot.init 15 (Point.fromXY 19 17) Player3 )
                , ( 16, Robot.init 16 (Point.fromXY 0 17) Player4 )
                , ( 17, Robot.init 17 (Point.fromXY 1 17) Player4 )
                , ( 18, Robot.init 18 (Point.fromXY 2 17) Player4 )
                , ( 19, Robot.init 19 (Point.fromXY 2 18) Player4 )
                , ( 20, Robot.init 20 (Point.fromXY 2 19) Player4 )
                ]

      -- TODO seed
      , helium =
            Random.initialSeed 0
                |> Random.step HeliumGrid.generator
                |> Tuple.first
      , players = Players.init
      , turn = Player1
      , timer = Countdown
      }
    , Cmd.batch
        [ Process.sleep 6000
            |> Task.perform (\() -> Timer)
        , Message.sendServerMessage [] <| Message.Countdown Player1
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

        SetTurn turn ->
            ( { model | turn = turn }, [], 0 )

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
