module Game exposing (main)

import Animation
import Array exposing (Array)
import Browser
import Color
import CountdownRing
import Helium3Grid
import Html exposing (Html, div, h1, li, span, text, ul)
import Html.Attributes exposing (style)
import Html.Events
import List.Extra
import Matrix
import Model exposing (Model)
import Player exposing (Player(..), Players)
import Point
import Process
import Random
import Robot exposing (Robot)
import Svg exposing (Svg, defs, g)
import Svg.Attributes as SA
import Svg.Grid
import Svg.Outline
import Svg.Robot
import Task
import Time exposing (Posix)


main : Program () Model Msg
main =
    Browser.document
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        }


init : () -> ( Model, Cmd Msg )
init () =
    ( { turn = Player1
      , turnCountdown = Nothing
      , countdownRing = CountdownRing.init

      -- , countdownRing = CountdownRing.startFromTopLeft CountdownRing.init
      , scorePlayer1 = 0
      , scorePlayer2 = 0
      , scorePlayer3 = 0
      , scorePlayer4 = 0
      , robots =
            [ Robot.init (Point.fromGridXY 2 0) 0 Player1
            , Robot.init (Point.fromGridXY 2 1) 0 Player1
            , Robot.init (Point.fromGridXY 2 2) 45 Player1
            , Robot.init (Point.fromGridXY 0 2) 90 Player1
            , Robot.init (Point.fromGridXY 1 2) 90 Player1
            , Robot.init (Point.fromGridXY 17 0) 180 Player2
            , Robot.init (Point.fromGridXY 17 1) 180 Player2
            , Robot.init (Point.fromGridXY 17 2) 134 Player2
            , Robot.init (Point.fromGridXY 18 2) 90 Player2
            , Robot.init (Point.fromGridXY 19 2) 90 Player2
            , Robot.init (Point.fromGridXY 17 19) 180 Player3
            , Robot.init (Point.fromGridXY 17 18) 180 Player3
            , Robot.init (Point.fromGridXY 17 17) 225 Player3
            , Robot.init (Point.fromGridXY 18 17) 270 Player3
            , Robot.init (Point.fromGridXY 19 17) 270 Player3
            , Robot.init (Point.fromGridXY 0 17) 270 Player4
            , Robot.init (Point.fromGridXY 1 17) 270 Player4
            , Robot.init (Point.fromGridXY 2 17) 315 Player4
            , Robot.init (Point.fromGridXY 2 18) 0 Player4
            , Robot.init (Point.fromGridXY 2 19) 0 Player4
            ]
                |> Array.fromList
      , helium3 = Helium3Grid.random (Random.initialSeed 0)
      , selectedRobot = Just 0
      }
    , Cmd.none
    )



-- UPDATE


type Msg
    = Animate Animation.Msg
    | Select Int


arrayUpdate : (a -> a) -> Int -> Array a -> Array a
arrayUpdate fn index array =
    Array.get index array
        |> Maybe.map (fn >> (\a -> Array.set index a array))
        |> Maybe.withDefault array


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Animate time ->
            ( { model
                | robots = Array.map (Robot.updateAnimation time) model.robots
                , countdownRing = CountdownRing.update time model.countdownRing
              }
            , Cmd.none
            )

        Select index ->
            ( { model | selectedRobot = Just index }, Cmd.none )



-- Move ->
--     ( { model
--         | robots =
--             case model.selectedRobot of
--                 Just index ->
--                     arrayUpdate
--                         (Robot.moveTo (Point.fromGridXY 19 1))
--                         index
--                         model.robots
--
--                 Nothing ->
--                     model.robots
--         , selectedRobot = Nothing
--       }
--     , Cmd.none
--     )
--
-- type Msg
--     = QueueMove PlayerEnum RobotEnum Position.Cell
--     | RotateRobots
--     | MoveRobots
--     | SelectRobot PlayerEnum RobotEnum
--     | FireMissile PlayerEnum RobotEnum Position.Cell
--     | FireLaser PlayerEnum RobotEnum Position.Cell
--     | ArmMissile PlayerEnum RobotEnum Position.Cell
--     | ArmLaser PlayerEnum RobotEnum Position.Cell
--     | Shield PlayerEnum RobotEnum Position.Cell
--     | Mine PlayerEnum RobotEnum Position.Cell
--     | Move PlayerEnum RobotEnum Position.Cell
--     | Kamikaze PlayerEnum RobotEnum
-- transitionStateWhenTwoMoves : Model -> ( Model, Cmd Msg )
-- transitionStateWhenTwoMoves model =
--     case model.state of
--         Setup playerEnum ->
--             let
--                 moves =
--                     getPlayer model playerEnum
--                         |> Player.robots
--                         |> List.Extra.count (.action >> (/=) Nothing)
--             in
--             if moves > 1 then
--                 ( { model | state = Moving playerEnum }
--                 , Process.sleep 1000
--                     |> Task.perform (\() -> RotateRobots)
--                 )
--
--             else
--                 ( model, Cmd.none )
--
--         Moving playerEnum ->
--             ( model, Cmd.none )
--
--
-- update : Msg -> Model -> ( Model, Cmd Msg )
-- update msg model =
--     case msg of
--         QueueMove playerEnum robotEnum cell ->
--             if Setup playerEnum == model.state then
--                 { model | selected = Nothing }
--                     |> updatePlayerRobot
--                         (\robot -> { robot | action = Just (Move cell) })
--                         playerEnum
--                         robotEnum
--                     |> transitionStateWhenTwoMoves
--
--             else
--                 ( model, Cmd.none )
--
--         RotateRobots ->
--             case model.state of
--                 Setup _ ->
--                     ( model, Cmd.none )
--
--                 Moving playerEnum ->
--                     ( updatePlayer
--                         (Player.mapRobots Robot.faceTarget)
--                         playerEnum
--                         model
--                     , Process.sleep 1000 |> Task.perform (\() -> MoveRobots)
--                     )
--
--         MoveRobots ->
--             case model.state of
--                 Setup _ ->
--                     ( model, Cmd.none )
--
--                 Moving playerEnum ->
--                     ( { model | state = Setup (nextPlayer playerEnum) }
--                         |> updatePlayer
--                             (Player.mapRobots Robot.performAction)
--                             playerEnum
--                     , Cmd.none
--                     )
--
--         SelectRobot player robot ->
--             if Setup player == model.state then
--                 ( { model | selected = Just ( player, robot, Nothing ) }, Cmd.none )
--
--             else
--                 ( model, Cmd.none )
--
--         FireMissile player robot cell ->
--
--         FireLaser player robot cell ->
--
--         ArmMissile player robot cell ->
--
--         ArmLaser player robot cell ->
--
--         Shield player robot cell ->
--
--         Mine player robot cell ->
--
--         Move player robot cell ->
--
--         Kamikaze player robot ->
-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ model.robots
            |> Array.map .animation
            |> Array.toList
            |> Animation.subscription Animate
        , CountdownRing.subscription Animate model.countdownRing
        ]



-- VIEW
-- viewActions : Robot -> Html msg
-- viewActions robot =
--     div []
--         [ h1 [] [ text "Choose an action" ]
--         , ul [ style "list-style" "none", style "padding" "0" ] <|
--             List.map
--                 (\action ->
--                     li [ style "cursor" "pointer" ] [ text action ]
--                 )
--             <|
--                 Robot.actions robot
--         ]


viewRobotIndexed : Int -> Robot -> ( Svg Msg, Svg Msg )
viewRobotIndexed index robot =
    if robot.owner == Player1 then
        Robot.view (Just (Select index)) robot

    else
        Robot.view Nothing robot


viewFutureSeconds : { current : Posix, future : Posix } -> String
viewFutureSeconds { current, future } =
    let
        secondsUntilStart =
            (Time.posixToMillis future
                - Time.posixToMillis current
            )
                // 1000

        label =
            if secondsUntilStart == 1 then
                " second"

            else
                " seconds"
    in
    if secondsUntilStart > 0 then
        String.fromInt secondsUntilStart ++ label

    else
        "a moment"



-- viewGamePhase : Model -> Html msg
-- viewGamePhase model =
--     case model.countdown of
--         Just (Start start) ->
--             div []
--                 [ text "Game starts in "
--                 , text <|
--                     viewFutureSeconds { current = model.time, future = start }
--                 ]
--
--         Just (NextMove nextMove) ->
--             div []
--                 [ text "Turn ends in "
--                 , text <|
--                     viewFutureSeconds { current = model.time, future = nextMove }
--                 ]
--
--         Just (EndMove _) ->
--             text ""
--
--         Nothing ->
--             text ""


viewSelectedRobot : Array Robot -> Int -> Maybe (Svg msg)
viewSelectedRobot robots index =
    Array.get index robots |> Maybe.map Svg.Outline.view


view : Model -> Browser.Document Msg
view model =
    let
        ( robots, decorations ) =
            Array.indexedMap viewRobotIndexed model.robots
                |> Array.toList
                |> List.unzip

        gridSideSvg =
            String.fromInt Svg.Grid.gridSideSvg
    in
    { title = "Helium 3"
    , body =
        [ div
            [ style "text-align" "center"
            , style "width" "calc((100vw - 100vh) / 2)"
            ]
            [ --viewGamePhase model
              --,
              case model.selectedRobot of
                Just index ->
                    text "actions"

                --viewActions model.robots index
                Nothing ->
                    text ""

            -- , Html.button [ Html.Events.onClick Move ] [ text "Move" ]
            ]
        , Svg.svg
            [ SA.viewBox
                ("0 0 "
                    ++ String.fromInt (Svg.Grid.gridSideSvg + CountdownRing.side * 2)
                    ++ " "
                    ++ String.fromInt (Svg.Grid.gridSideSvg + CountdownRing.side * 2)
                )
            , style "display" "block"
            , style "height" "100%"
            , style "flex-grow" "2"
            ]
            (CountdownRing.view Color.green model.countdownRing
                ++ [ Svg.svg
                        [ SA.x (String.fromInt CountdownRing.side)
                        , SA.y (String.fromInt CountdownRing.side)
                        ]
                        (List.concat
                            [ [ defs [] [ Svg.Robot.def, Svg.Robot.defMissile ]
                              , Svg.Grid.grid
                              ]
                            , robots
                            , decorations
                            , model.selectedRobot
                                |> Maybe.andThen (viewSelectedRobot model.robots)
                                |> Maybe.map List.singleton
                                |> Maybe.withDefault []
                            ]
                        )
                   ]
            )
        , div [ style "width" "calc((100vw - 100vh) / 2)" ] []
        , Html.node "style"
            []
            [ text
                """html, body {
                        height: 100%;
                        margin: 0;
                       }
                       body {
                        display: flex;
                       }
                    """
            ]
        ]
    }



-- view : Model -> Browser.Document Msg
-- view model =
--     let
--         ( robots, decorations ) =
--             viewPlayers model
--     in
--     { title = "Helium 3"
--     , body =
--         [ div
--             [ style "text-align" "center"
--             , style "width" "calc((100vw - 100vh) / 2)"
--             ]
--             (List.concat
--                 [ [ viewState model.state ]
--                 , case model.selected of
--                     Just ( player, robot ) ->
--                         [ viewActions (getPlayerRobot model player robot) ]
--
--                     Nothing ->
--                         []
--                 ]
--             )
--         , Svg.Grid.grid
--         , Array.map Robot.view
--         , View.Grid.grid
--             20
--             [ style "display" "block"
--             , style "height" "100%"
--             , style "flex-grow" "2"
--             ]
--             (List.concat
--                 [ [ ( "defs", defs [] [ View.Robot.def ] ) ]
--                 , robots |> keyed "robot"
--                 , decorations |> keyed "decoration"
--                 , case model.selected of
--                     Just ( playerEnum, robotEnum, Just action ) ->
--                         let
--                             position =
--                                 (getPlayerRobot model playerEnum robotEnum).position
--                         in
--                         case action of
--                             Robot.FireMissile_ ->
--                                 View.Grid.selectedableGrid
--                                     (FireMissile playerEnum robotEnum)
--                                     position
--                                     Robot.missileRange
--
--                             Robot.FireLaser_ ->
--                                 View.Grid.selectedableGrid
--                                     (FireLaser playerEnum robotEnum)
--                                     position
--                                     1
--
--                             Robot.ArmMissile_ ->
--                                 View.Grid.selectedableGrid
--                                     (ArmMissile playerEnum robotEnum)
--                                     position
--                                     Robot.moveAndArmWeaponRange
--
--                             Robot.ArmLaser_ ->
--                                 View.Grid.selectedableGrid
--                                     (ArmLaser playerEnum robotEnum)
--                                     position
--                                     Robot.moveAndArmWeaponRange
--
--                             Robot.Shield_ ->
--                                 View.Grid.selectedableGrid
--                                     (Shield playerEnum robotEnum)
--                                     position
--                                     Robot.moveAndShieldRange
--
--                             Robot.Mine_ ->
--                                 View.Grid.selectedableGrid
--                                     (Mine playerEnum robotEnum)
--                                     position
--                                     Robot.moveAndMineRange
--
--                             Robot.Kamikaze_ ->
--                                 []
--
--                             Robot.Move_ ->
--                                 View.Grid.selectedableGrid
--                                     (Move playerEnum robotEnum)
--                                     position
--                                     1
--
--                     Nothing ->
--                         []
--                 ]
--             )
--         , div [ style "width" "calc((100vw - 100vh) / 2)" ] []
--         , Html.node "style"
--             []
--             [ text
--                 """html, body {
--                     height: 100%;
--                     margin: 0;
--                    }
--                    body {
--                     display: flex;
--                    }
--                 """
--             ]
--         ]
--     }
