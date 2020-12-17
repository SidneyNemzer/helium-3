module Page.Animation exposing (main)

import Array exposing (Array)
import Browser
import Color
import Dict exposing (Dict)
import HeliumGrid exposing (HeliumGrid)
import Html exposing (Html, button, text)
import Html.Attributes exposing (style)
import Html.Events exposing (onClick)
import List
import List.Extra
import Matrix
import Maybe.Extra
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


type alias Timeline =
    List Animation


type Animation
    = SetLocation Int Point
    | SetRotation Int Float
    | SetMinerActive Int
    | MineAt Int Point
    | SetState Int State



-- | Parallel (Dict Int Animation)
-- | SetTool Int (Maybe Robot.Tool)
-- | SetFiringLaser Int
-- | SetFiringMissile Int
-- | SetDestroyed Int
-- | SetScore PlayerId Int
-- | DropHelium Cell Int
-- | CreateExplotion Int
-- | DeleteExplotion Int


init : () -> ( Model, Cmd Msg )
init () =
    ( { robots =
            Dict.fromList
                [ ( 0, Robot.init 0 (Point.fromXY 2 2) )
                , ( 1, Robot.init 1 (Point.fromXY 4 4) )
                ]
      , timeline = []
      , selectedRobot = Nothing

      -- TODO seed
      , helium =
            Random.initialSeed 0
                |> Random.step HeliumGrid.generator
                |> Tuple.first
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
                            |> List.foldl (\robot timeline -> stateToAnimation model.robots robot ++ timeline) []
                }

        DeselectRobot ->
            ( { model | selectedRobot = Nothing }, Cmd.none )

        ClickRobot id ->
            -- TODO Show error/message when selecting an invalid move location?
            case model.selectedRobot of
                Nothing ->
                    ( { model | selectedRobot = Just ( ChoosingAction, id ) }, Cmd.none )

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



-- ANIMATION


stateToAnimation : Dict Int Robot -> Robot -> Timeline
stateToAnimation robots robot =
    case robot.state of
        MoveWithTool { target, pending } ->
            [ SetState robot.id (Idle pending) ]
                ++ rotateAnimation robot target
                ++ locationAnimation robot target

        Idle currentTool ->
            []

        Mine { target, tool } ->
            let
                move =
                    if robot.location /= target then
                        rotateAnimation robot target
                            ++ locationAnimation robot target

                    else
                        []
            in
            move
                ++ [ SetMinerActive robot.id
                   , MineAt robot.id target
                   , SetState robot.id (Idle Nothing)
                   ]

        SelfDestruct currentTool ->
            Debug.todo "SelfDestruct"

        FireMissile target _ ->
            let
                maybeTargetRobot =
                    -- TODO this will run logic on robots that are already destroyed
                    Dict.values robots
                        |> List.Extra.find (\r -> r.location == target)
                        |> Maybe.map Robot.impact

                targetRobotAnimation =
                    case maybeTargetRobot of
                        Just targetRobot ->
                            if targetRobot.state /= Destroyed then
                                -- Target has a shield equipped, `Robot.impact` has updated the state
                                [ SetState targetRobot.id targetRobot.state
                                , SetState targetRobot.id (Robot.removeShield targetRobot).state
                                ]

                            else
                                -- Target will be destroyed
                                [ SetState targetRobot.id Destroyed ]

                        Nothing ->
                            []
            in
            rotateAnimation robot target
                ++ [ SetState robot.id (FireMissile target True) ]
                ++ targetRobotAnimation
                ++ [ SetState robot.id (Idle Nothing) ]

        FireLaser _ _ ->
            Debug.todo "FireLaser"

        Destroyed ->
            Debug.todo "Destroyed"


rotateAnimation : Robot -> Point -> List Animation
rotateAnimation robot target =
    let
        angle =
            Point.angle robot.location target
    in
    if angle /= robot.rotation then
        [ SetRotation robot.id angle ]

    else
        []


locationAnimation : Robot -> Point -> List Animation
locationAnimation robot target =
    if target /= robot.location then
        [ SetLocation robot.id target ]

    else
        []


animate : Model -> ( Model, Cmd Msg )
animate model =
    case model.timeline of
        animation :: timeline ->
            let
                ( newModel, sleepSeconds ) =
                    applyAnimation animation { model | timeline = timeline }
            in
            if sleepSeconds == 0 then
                animate newModel

            else
                ( newModel
                , Process.sleep (sleepSeconds * 1000)
                    |> Task.perform (\() -> NextAnimation)
                )

        [] ->
            ( model, Cmd.none )


applyAnimation : Animation -> Model -> ( Model, Float )
applyAnimation animation model =
    case animation of
        SetLocation id point ->
            ( updateRobot id (Robot.setLocation point) model
            , 1
            )

        SetRotation id rotation ->
            ( updateRobot id (Robot.setRotation rotation) model
            , 1
            )

        SetState id state ->
            ( updateRobot id (Robot.setState state) model
            , if state == Idle Nothing then
                0

              else
                1
            )

        SetMinerActive id ->
            ( updateRobot id Robot.setMinerActive model
            , 1
            )

        MineAt id point ->
            let
                ( ground, mined ) =
                    HeliumGrid.mine point model.helium
            in
            ( { model | helium = groud }
                |> updateRobot id (\robot -> { robot | mined = robot.mined + mined })
            , 0
            )



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
        , button [ onClick StartTurn ] [ text "Next" ]
        , viewActionPicker model.robots model.selectedRobot
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
                Color.blue

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
            -- TODO highlight
            View.Shield.use robot.location robot.rotation

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



-- View.Miner.use robot.location robot.rotation


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
