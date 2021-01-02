module Server exposing (..)

import Browser
import ClientAction exposing (ClientAction)
import Dict exposing (Dict)
import Effect exposing (Effect(..), Timeline)
import HeliumGrid exposing (HeliumGrid)
import Html exposing (Html, div)
import Json.Decode as Decode exposing (Error)
import Maybe.Extra as Maybe
import Platform
import Players exposing (Player, PlayerIndex(..), Players)
import Point exposing (Point)
import Ports
import Random
import Robot exposing (Robot, State(..), Tool(..))
import ServerAction exposing (ServerAction)


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
    , turn : PlayerIndex
    }


init : () -> ( Model, Cmd Msg )
init () =
    ( { robots =
            Dict.fromList
                [ ( 0, Robot.init 0 (Point.fromXY 2 2) Player1 )
                , ( 1, Robot.init 1 (Point.fromXY 4 4) Player2 )
                ]

      -- TODO seed
      , helium =
            Random.initialSeed 0
                |> Random.step HeliumGrid.generator
                |> Tuple.first
      , players = Players.init
      , turn = Player1
      }
    , Cmd.none
    )


type Msg
    = ActionReceived (Result Error ClientAction)
    | EndTurn


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ActionReceived result ->
            onMessage onActionReceived result model

        EndTurn ->
            let
                ( newModel, actions ) =
                    Dict.values model.robots
                        |> List.filter (\robot -> robot.owner == model.turn)
                        |> List.foldl performTurn ( model, [] )
            in
            ( { newModel | turn = Players.next newModel.turn }
            , ServerAction.send actions
            )


onMessage : (a -> Model -> ( Model, Cmd Msg )) -> Result Error a -> Model -> ( Model, Cmd Msg )
onMessage handler result model =
    case result of
        Ok a ->
            handler a model

        Err x ->
            ( model, Ports.log (Decode.errorToString x) )


onActionReceived : ClientAction -> Model -> ( Model, Cmd Msg )
onActionReceived action model =
    ( updateRobot (ClientAction.id action) (Robot.queueAction action) model
    , Cmd.none
    )


performTurn : Robot -> ( Model, List ServerAction.Recipient ) -> ( Model, List ServerAction.Recipient )
performTurn robot ( model, actions ) =
    let
        moreActions =
            Robot.toServerAction model.robots robot
    in
    ( animate (Effect.fromRobot robot) model
    , List.append actions moreActions
    )


{-| Note that the server ignores all `Wait` effects
-}
animate : Timeline -> Model -> Model
animate timeline model =
    case timeline of
        [] ->
            model

        next :: rest ->
            let
                ( newModel, extraTimeline ) =
                    animateHelp next model
            in
            animate (extraTimeline ++ rest) newModel


animateHelp : Effect -> Model -> ( Model, Timeline )
animateHelp effect model =
    case effect of
        SetLocation id point ->
            ( updateRobot id (Robot.setLocation point) model, [] )

        SetRotation id rotation ->
            ( updateRobot id (Robot.setRotation rotation) model, [] )

        SetMinerActive id ->
            ( updateRobot id Robot.setMinerActive model, [] )

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
            )

        SetState id state ->
            ( updateRobot id (Robot.setState state) model, [] )

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
                    ( updateRobot robot.id (\_ -> impacted) model, animation )

                Nothing ->
                    ( model, [] )

        ChangeTurn ->
            ( { model | turn = Players.next model.turn }, [] )

        Wait ms ->
            ( model, [] )


updateRobot : Int -> (Robot -> Robot) -> Model -> Model
updateRobot id fn model =
    { model | robots = Dict.update id (Maybe.map fn) model.robots }



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ ClientAction.receive ActionReceived
        , Ports.onEndTurn EndTurn
        ]
