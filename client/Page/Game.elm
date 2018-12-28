module Game exposing (main)

import Array exposing (Array)
import Browser
import Color
import Helium3Grid exposing (Helium3Grid)
import Html exposing (Html, div, h1, li, span, text, ul)
import Html.Attributes exposing (style)
import Html.Events
import List.Extra
import Model exposing (Model)
import Player exposing (Player(..), Players)
import Point
import Process
import Robot exposing (Robot)
import Svg exposing (Svg, defs, g)
import Svg.Attributes as SA
import Svg.Grid
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
      , countdown = Nothing
      , players =
            { player1 = 0
            , player2 = 0
            , player3 = 0
            , player4 = 0
            }
      , robots = Array.empty -- FIXME
      , helium3 = Helium3Grid
      , selectedRobot = Nothing
      }
    , Cmd.none
    )



-- UPDATE


type Msg
    = Temp



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
    Sub.none



-- VIEW


viewActions : Robot -> Html msg
viewActions robot =
    div []
        [ h1 [] [ text "Choose an action" ]
        , ul [ style "list-style" "none", style "padding" "0" ] <|
            List.map
                (\action ->
                    li [ style "cursor" "pointer" ] [ text action ]
                )
            <|
                Robot.actions robot
        ]


viewRobotIndexed : Int -> Robot -> ( Svg Msg, Svg Msg )
viewRobotIndexed index robot =
    Robot.view (RobotClicked index) robot

viewGamePhase : Model -> Html msg
viewGamePhase model =
    case model.countdown of
        Just (Start posix) ->
            div []
                [ text "Game starts in "
                , text "time"
                ]

        Just (NextMove posix) ->

        Just (EndMove posix) ->

        Nothing ->



viewSelectedRobot : Array Robot -> Int -> Svg msg
viewSelectedRobot robots index =
    Array.get index robots
        |> Maybe.map (.location >> Svg.Grid.overlayCell Nothing)

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
            [ viewGamePhase model
            , case model.selectedRobot of
                Just index ->
                    viewActions model.robots index

                Nothing ->
                    text ""
            ]
        , Svg.svg
            [ SA.stroke "black"
            , SA.viewBox ("0 0 " ++ gridSideSvg ++ " " ++ gridSideSvg)
            , style "display" "block"
            , style "height" "100%"
            , style "flex-grow" "2"
            ]
            (List.concat
                [ [ Svg.Grid.grid ]
                , robots
                , decorations
                , case model.selectedRobot of
                    Just index ->
                        [ viewSelectedRobot model.robots index ]


                    Nothing ->
                        []
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
