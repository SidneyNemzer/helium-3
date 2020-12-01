module Page.Animation exposing (main)

import Array exposing (Array)
import Browser
import Color
import Dict exposing (Dict)
import Html exposing (Html, button, text)
import Html.Attributes exposing (style)
import Html.Events exposing (onClick)
import List
import List.Extra
import Maybe.Extra
import Point exposing (Point)
import Process
import Robot exposing (Robot, State(..), Tool(..))
import Svg exposing (Svg, defs, g, rect, svg)
import Svg.Attributes exposing (color, fill, height, stroke, viewBox, width, x, y)
import Task
import View.Grid
import View.Missile
import View.Robot
import View.RobotActions


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
    , order : TimelineOrder
    , selectedRobot : Maybe ( Selection, Int )
    }


type Selection
    = ChoosingAction
    | ChoosingMoveLocation
    | ChoosingArmMissileLocation
    | ChoosingFireMissileLocation



-- | ChoosingMissileTarget
-- | ChoosingLaserTarget
-- | ChoosingArmLaserLocation
-- | ChoosingShieldLocation
-- | ChoosingMineLocation
-- | Robot


type alias Timeline =
    List Animation


type Animation
    = SetLocation Int Point
    | SetRotation Int Float
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


type TimelineOrder
    = Sequential (List Int)
    | Parallel


init : () -> ( Model, Cmd Msg )
init () =
    ( { robots =
            Dict.fromList
                [ ( 0, Robot.init 0 (Point.fromXY 2 2) )
                , ( 1, Robot.init 1 (Point.fromXY 4 4) )
                ]
      , timeline = []
      , order = Parallel
      , selectedRobot = Nothing
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

                Just ( ChoosingArmMissileLocation, _ ) ->
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
                    ( { model
                        | robots = Dict.update id (Maybe.map (Robot.move Nothing point)) model.robots
                        , selectedRobot = Nothing
                      }
                    , Cmd.none
                    )

                Just ( ChoosingArmMissileLocation, id ) ->
                    ( { model
                        | robots = Dict.update id (Maybe.map (Robot.move (Just ToolMissile) point)) model.robots
                        , selectedRobot = Nothing
                      }
                    , Cmd.none
                    )

                Just ( ChoosingFireMissileLocation, id ) ->
                    ( { model
                        | robots =
                            Dict.update id (Maybe.map (Robot.setState (FireMissile point False))) model.robots
                        , selectedRobot = Nothing
                      }
                    , Cmd.none
                    )

                Just ( ChoosingAction, id ) ->
                    ( model, Cmd.none )

                Nothing ->
                    ( model, Cmd.none )



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

        Mine _ ->
            Debug.todo "Mine"

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
                                , SetState targetRobot.id (Robot.removeShield robot).state
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
            ( { model
                | robots =
                    Dict.update id (Maybe.map (Robot.setLocation point)) model.robots
              }
            , 1
            )

        SetRotation id rotation ->
            ( { model
                | robots =
                    Dict.update id (Maybe.map (Robot.setRotation rotation)) model.robots
              }
            , 1
            )

        SetState id state ->
            ( { model
                | robots =
                    Dict.update id (Maybe.map (Robot.setState state)) model.robots
              }
            , if state == Idle Nothing then
                0

              else
                1
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
            ([ defs [] [ View.Robot.def, View.Missile.def ]
             , View.Grid.grid
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
    case selection of
        ChoosingAction ->
            -- Rendered outside of the SVG by `viewActionPicker`
            text ""

        ChoosingMoveLocation ->
            let
                { highlight, hover } =
                    View.Grid.highlightAround robot.location 4 ClickPoint False
            in
            g [] [ highlight, hover ]

        ChoosingArmMissileLocation ->
            let
                { highlight, hover } =
                    View.Grid.highlightAround robot.location 4 ClickPoint False
            in
            g [] [ highlight, hover ]

        ChoosingFireMissileLocation ->
            let
                { highlight, hover } =
                    View.Grid.highlightAround robot.location 3 ClickPoint False
            in
            g [] [ highlight, hover ]


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

        missileSvg =
            Robot.getTool robot
                |> Maybe.map (viewTool robot)
                |> Maybe.Extra.toList
    in
    if robot.state == Destroyed then
        text ""

    else
        g []
            [ g [] targetSvg
            , g
                [ onClick (ClickRobot robot.id)
                ]
                ([ robotSvg ] ++ missileSvg)
            ]


viewTool : Robot -> Robot.Tool -> Svg msg
viewTool robot tool =
    case tool of
        ToolShield highlight ->
            -- TODO
            text ""

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
