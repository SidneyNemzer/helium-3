module Page.Client exposing (main)

import Array exposing (Array)
import Browser
import Color
import Dict exposing (Dict)
import Effect exposing (Effect(..), Timeline)
import HeliumGrid exposing (HeliumGrid)
import Html exposing (Html, button, div, span, text)
import Html.Attributes exposing (style)
import Html.Events exposing (onClick)
import List
import List.Extra
import Matrix
import Maybe.Extra
import Players exposing (Player, PlayerIndex(..), Players)
import Point exposing (Point)
import Process
import Random
import Robot exposing (Robot, State(..), Tool(..))
import Svg exposing (Svg, defs, g, rect, svg)
import Svg.Attributes exposing (color, fill, height, stroke, viewBox, width, x, y)
import Task
import View.Grid
import View.Miner
import View.Missile
import View.Robot
import View.RobotActions
import View.Shield


main : Program () Model Msg
main =
    Browser.document
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        }


type alias Model =
    { robots : Dict Int Robot
    , timeline : Timeline
    , selectedRobot : Maybe ( Selection, Int )
    , helium : HeliumGrid
    , players : Players
    , player : PlayerIndex
    , turn : PlayerIndex
    }


type Selection
    = ChoosingAction
    | ChoosingMoveLocation
    | ChoosingArmMissileLocation
    | ChoosingFireMissileLocation
    | ChoosingShieldLocation
    | ChoosingMineLocation



-- | ChoosingLaserTarget
-- | ChoosingArmLaserLocation


init : () -> ( Model, Cmd Msg )
init () =
    ( { robots =
            Dict.fromList
                [ ( 0, Robot.init 0 (Point.fromXY 2 2) Player1 )
                , ( 1, Robot.init 1 (Point.fromXY 4 4) Player2 )
                ]
      , timeline = []
      , selectedRobot = Nothing

      -- TODO seed
      , helium =
            Random.initialSeed 0
                |> Random.step HeliumGrid.generator
                |> Tuple.first
      , players = Players.init
      , player = Player2
      , turn = Player1
      }
    , Cmd.none
    )


type Msg
    = NextAnimation
    | StartTurn
    | DeselectRobot
    | ClickRobot Int
    | ChooseAction Selection
    | ClickPoint Point


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NextAnimation ->
            animate model

        StartTurn ->
            animate
                { model
                    | timeline =
                        Dict.values model.robots
                            |> List.filter (\robot -> robot.owner == model.turn)
                            |> List.foldl
                                (\robot timeline ->
                                    Effect.fromRobot robot ++ timeline
                                )
                                [ ChangeTurn ]
                }

        DeselectRobot ->
            ( { model | selectedRobot = Nothing }, Cmd.none )

        ClickRobot id ->
            -- TODO Show error/message when selecting an invalid move location?
            case model.selectedRobot of
                Nothing ->
                    let
                        isOwner =
                            Dict.get id model.robots
                                |> Maybe.map (.owner >> (==) model.player)
                                |> Maybe.withDefault False
                    in
                    if isOwner then
                        ( { model | selectedRobot = Just ( ChoosingAction, id ) }, Cmd.none )

                    else
                        ( model, Cmd.none )

                Just ( ChoosingAction, _ ) ->
                    ( model, Cmd.none )

                Just ( ChoosingMoveLocation, _ ) ->
                    ( model, Cmd.none )

                Just ( ChoosingArmMissileLocation, otherId ) ->
                    if otherId == id then
                        ( { model | selectedRobot = Nothing }
                            |> updateRobot id (\robot -> Robot.move (Just ToolMissile) robot.location robot)
                        , Cmd.none
                        )

                    else
                        ( model, Cmd.none )

                Just ( ChoosingShieldLocation, otherId ) ->
                    if otherId == id then
                        ( { model | selectedRobot = Nothing }
                            |> updateRobot id (\robot -> Robot.move (Just (ToolShield False)) robot.location robot)
                        , Cmd.none
                        )

                    else
                        ( model, Cmd.none )

                Just ( ChoosingFireMissileLocation, selectedId ) ->
                    let
                        maybePoint =
                            Dict.get id model.robots
                                |> Maybe.map .location
                    in
                    ( { model
                        | robots =
                            Dict.update selectedId
                                (Maybe.map2
                                    (\point ->
                                        Robot.setState (FireMissile point False)
                                    )
                                    maybePoint
                                )
                                model.robots
                        , selectedRobot = Nothing
                      }
                    , Cmd.none
                    )

                Just ( ChoosingMineLocation, otherId ) ->
                    if otherId == id then
                        ( { model | selectedRobot = Nothing }
                            |> updateRobot id (\robot -> Robot.queueMine robot.location robot)
                        , Cmd.none
                        )

                    else
                        ( model, Cmd.none )

        ChooseAction selection ->
            ( { model
                | selectedRobot =
                    model.selectedRobot
                        |> Maybe.map (Tuple.mapFirst (\_ -> selection))
              }
            , Cmd.none
            )

        ClickPoint point ->
            case model.selectedRobot of
                Just ( ChoosingMoveLocation, id ) ->
                    ( { model | selectedRobot = Nothing }
                        |> updateRobot id (Robot.move Nothing point)
                    , Cmd.none
                    )

                Just ( ChoosingArmMissileLocation, id ) ->
                    ( { model | selectedRobot = Nothing }
                        |> updateRobot id (Robot.move (Just ToolMissile) point)
                    , Cmd.none
                    )

                Just ( ChoosingFireMissileLocation, id ) ->
                    ( { model | selectedRobot = Nothing }
                        |> updateRobot id (Robot.setState (FireMissile point False))
                    , Cmd.none
                    )

                Just ( ChoosingShieldLocation, id ) ->
                    ( { model | selectedRobot = Nothing }
                        |> updateRobot id (Robot.move (Just (ToolShield False)) point)
                    , Cmd.none
                    )

                Just ( ChoosingMineLocation, id ) ->
                    ( { model | selectedRobot = Nothing }
                        |> updateRobot id (Robot.queueMine point)
                    , Cmd.none
                    )

                Just ( ChoosingAction, id ) ->
                    ( model, Cmd.none )

                Nothing ->
                    ( model, Cmd.none )


updateRobot : Int -> (Robot -> Robot) -> Model -> Model
updateRobot id fn model =
    { model | robots = Dict.update id (Maybe.map fn) model.robots }


getRobotAt : Point -> Dict Int Robot -> Maybe Robot
getRobotAt point =
    Dict.filter (\id robot -> robot.location == point)
        >> Dict.toList
        >> List.head
        >> Maybe.map Tuple.second



-- ANIMATION


animate : Model -> ( Model, Cmd Msg )
animate model =
    case model.timeline of
        [] ->
            ( model, Cmd.none )

        next :: rest ->
            let
                ( newModel, sleepMs ) =
                    animateHelp next { model | timeline = rest }
            in
            if sleepMs == 0 then
                animate newModel

            else
                ( newModel
                , Process.sleep (toFloat sleepMs) |> Task.perform (\() -> NextAnimation)
                )


animateHelp : Effect -> Model -> ( Model, Int )
animateHelp effect model =
    case effect of
        SetLocation id point ->
            ( updateRobot id (Robot.setLocation point) model, 0 )

        SetRotation id rotation ->
            ( updateRobot id (Robot.setRotation rotation) model, 0 )

        SetMinerActive id ->
            ( updateRobot id Robot.setMinerActive model, 0 )

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
            , 0
            )

        SetState id state ->
            ( updateRobot id (Robot.setState state) model, 0 )

        Impact point ->
            case getRobotAt point model.robots of
                Just robot ->
                    let
                        impacted =
                            Robot.impact robot

                        animation =
                            if impacted.state /= Destroyed then
                                [ Wait 1000
                                , SetState robot.id (Robot.removeShield impacted).state
                                ]

                            else
                                []
                    in
                    ( { model | timeline = animation ++ model.timeline }
                        |> updateRobot robot.id (\_ -> impacted)
                    , 0
                    )

                Nothing ->
                    ( model, 0 )

        ChangeTurn ->
            ( { model | turn = Players.next model.turn }, 0 )

        Wait ms ->
            ( model, ms )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- VIEW


view : Model -> Browser.Document Msg
view model =
    let
        robots =
            Dict.values model.robots |> List.map viewRobot
    in
    { title = "Helium 3"
    , body =
        [ View.Missile.style
        , View.Grid.style
        , View.Shield.style
        , viewActionPicker model.robots model.selectedRobot
        , div
            [ style "display" "flex"
            ]
            [ div [ style "flex-shrink" "0", style "padding" "20px" ]
                [ viewPlayers model.players model.player
                , div []
                    [ text "Current Turn: "
                    , span [ style "color" (Players.color model.turn) ]
                        [ text "Player "
                        , text <| String.fromInt <| Players.toNumber model.turn
                        ]
                    ]
                , button [ onClick StartTurn ] [ text "End Turn" ]
                ]
            , svg
                [ style "max-height" "100vh"
                , style "max-width" "100vw"
                , style "width" "100%"
                , style "height" "100%"
                , viewBox View.Grid.viewBox
                ]
                ([ defs []
                    [ View.Robot.def
                    , View.Missile.def
                    , View.Shield.def
                    , View.Miner.def
                    ]
                 , View.Grid.grid
                 , viewHeliumGrid model.helium
                 , viewSelection model
                 ]
                    ++ robots
                )
            ]
        ]
    }


viewActionPicker : Dict Int Robot -> Maybe ( Selection, Int ) -> Html Msg
viewActionPicker robots maybeSelection =
    case maybeSelection of
        Just ( ChoosingAction, id ) ->
            case Dict.get id robots of
                Just robot ->
                    viewActionPickerHelp robot

                Nothing ->
                    text ""

        _ ->
            text ""


viewActionPickerHelp : Robot -> Html Msg
viewActionPickerHelp robot =
    View.RobotActions.view
        { cancel = DeselectRobot
        , move = ChooseAction ChoosingMoveLocation
        , armMissile = ChooseAction ChoosingArmMissileLocation
        , fireMissile =
            if Robot.getTool robot == Just ToolMissile then
                Just (ChooseAction ChoosingFireMissileLocation)

            else
                Nothing
        , shield = ChooseAction ChoosingShieldLocation
        , mine = ChooseAction ChoosingMineLocation
        }


viewPlayers : Players -> PlayerIndex -> Html Msg
viewPlayers players self =
    div []
        [ viewPlayer players.player1 (Player1 == self)
        , viewPlayer players.player2 (Player2 == self)
        , viewPlayer players.player3 (Player3 == self)
        , viewPlayer players.player4 (Player4 == self)
        ]


viewPlayer : Player -> Bool -> Html Msg
viewPlayer player isSelf =
    div [ style "padding-bottom" "10px" ]
        [ div []
            [ span [ style "color" (Players.color player.id) ]
                [ text "Player "
                , text <| String.fromInt <| Players.toNumber player.id
                ]
            , if isSelf then
                text " (you)"

              else
                text ""
            ]
        , div [] [ text (String.fromInt player.score) ]
        ]


viewSelection : Model -> Svg Msg
viewSelection model =
    model.selectedRobot
        |> Maybe.andThen
            (\( selection, id ) ->
                Dict.get id model.robots |> Maybe.map (Tuple.pair selection)
            )
        |> Maybe.map viewSelectionHelp
        |> Maybe.withDefault (text "")


viewSelectionHelp : ( Selection, Robot ) -> Svg Msg
viewSelectionHelp ( selection, robot ) =
    let
        maybeSize =
            case selection of
                ChoosingAction ->
                    -- Rendered outside of the SVG by `viewActionPicker`
                    Nothing

                ChoosingMoveLocation ->
                    Just ( 4, False )

                ChoosingArmMissileLocation ->
                    Just ( 4, True )

                ChoosingFireMissileLocation ->
                    Just ( 3, True )

                ChoosingShieldLocation ->
                    Just ( 4, True )

                ChoosingMineLocation ->
                    Just ( 3, True )
    in
    case maybeSize of
        Just ( size, center ) ->
            let
                { highlight, hover } =
                    View.Grid.highlightAround robot.location size ClickPoint center
            in
            g [] [ highlight, hover ]

        Nothing ->
            text ""


viewRobot : Robot -> Svg Msg
viewRobot robot =
    let
        robotSvg =
            View.Robot.use
                robot.location
                robot.rotation
                (Players.color robot.owner)

        targetSvg =
            case Robot.getTarget robot of
                Just target ->
                    [ View.Grid.highlight target
                    , View.Grid.dottedLine robot.location target
                    ]

                Nothing ->
                    []

        toolSvg =
            Robot.getTool robot
                |> Maybe.map (viewTool robot)
                |> Maybe.Extra.toList
    in
    if robot.state == Destroyed then
        text ""

    else
        g []
            [ g [] targetSvg
            , g [ onClick (ClickRobot robot.id) ]
                ([ robotSvg ] ++ toolSvg ++ [ viewMiner robot ])
            ]


viewTool : Robot -> Robot.Tool -> Svg msg
viewTool robot tool =
    case tool of
        ToolShield highlight ->
            View.Shield.use robot.location robot.rotation highlight

        ToolLaser ->
            -- TODO
            text ""

        ToolMissile ->
            let
                location =
                    case robot.state of
                        FireMissile target True ->
                            target

                        _ ->
                            robot.location
            in
            View.Missile.use location robot.rotation


viewMiner : Robot -> Svg msg
viewMiner robot =
    case robot.state of
        Mine { active } ->
            if active then
                View.Miner.use robot.location robot.rotation

            else
                text ""

        _ ->
            text ""


viewHeliumGrid : HeliumGrid -> Svg msg
viewHeliumGrid helium =
    Matrix.toIndexedArray helium
        |> Array.filter (\( _, amount ) -> amount > 0)
        |> Array.map (Tuple.mapFirst Point.fromTuple >> viewHelium)
        |> Array.toList
        |> g []


viewHelium : ( Point, Int ) -> Svg msg
viewHelium ( point, amount ) =
    View.Grid.fillCell point amount
