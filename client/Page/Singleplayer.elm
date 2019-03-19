module Page.Singleplayer exposing (main)

import Array exposing (Array)
import Browser exposing (Document)
import Color
import CountdownRing
import Game
import Game.Cell as Cell exposing (Cell, Direction)
import Game.Constants
import Game.Player as Player
import Game.Robot as Robot exposing (Robot)
import Html exposing (Html, button, div, li, span, text, ul)
import Html.Attributes exposing (class, style)
import Html.Events exposing (onClick)
import Missile
import Svg exposing (Svg)
import Svg.Attributes as SA
import Svg.Grid
import Svg.Outline
import Svg.Robot


main : Program () Model Msg
main =
    Browser.document
        { init = init
        , update = update
        , subscriptions = always Sub.none
        , view = view
        }


type Selection
    = Robot
    | ChoosingMissileTarget
    | ChoosingLaserTarget
    | ChoosingArmMissileLocation
    | ChoosingArmLaserLocation
    | ChoosingShieldLocation
    | ChoosingMineLocation
    | ChoosingMoveLocation


type alias Model =
    { game : Game.Model
    , selectedRobot : Maybe ( Selection, Int )
    }


type QueueAction
    = FireMissile
    | FireLaser
    | ArmMissile
    | ArmLaser
    | Shield
    | Mine
    | Kamikaze
    | Move


type QueueActionTarget
    = TargetFireMissile Cell
    | TargetFireLaser Direction
    | TargetArmMissile Cell
    | TargetArmLaser Cell
    | TargetShield Cell
    | TargetMine Cell
    | TargetMove Cell


type Msg
    = SelectRobot Int
    | QueueAction QueueAction Int
    | QueueActionTarget Int QueueActionTarget
    | PerformTurn


init : () -> ( Model, Cmd Msg )
init () =
    ( { game = Game.init ()
      , selectedRobot = Nothing
      }
    , Cmd.none
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        SelectRobot index ->
            ( { model | selectedRobot = Just ( Robot, index ) }, Cmd.none )

        QueueAction queueAction index ->
            ( case queueAction of
                FireMissile ->
                    { model | selectedRobot = Just ( ChoosingMissileTarget, index ) }

                FireLaser ->
                    { model | selectedRobot = Just ( ChoosingLaserTarget, index ) }

                ArmMissile ->
                    { model | selectedRobot = Just ( ChoosingArmMissileLocation, index ) }

                ArmLaser ->
                    { model | selectedRobot = Just ( ChoosingArmLaserLocation, index ) }

                Shield ->
                    { model | selectedRobot = Just ( ChoosingShieldLocation, index ) }

                Mine ->
                    { model | selectedRobot = Just ( ChoosingMineLocation, index ) }

                Kamikaze ->
                    { model
                        | game = Game.queueAction Robot.Kamikaze index model.game
                        , selectedRobot = Nothing
                    }

                Move ->
                    { model | selectedRobot = Just ( ChoosingMoveLocation, index ) }
            , Cmd.none
            )

        QueueActionTarget index actionTarget ->
            let
                action =
                    case actionTarget of
                        TargetFireMissile cell ->
                            Robot.FireMissile cell

                        TargetFireLaser direction ->
                            Robot.FireLaser direction

                        TargetArmMissile cell ->
                            Robot.ArmMissile cell

                        TargetArmLaser cell ->
                            Robot.ArmLaser cell

                        TargetShield cell ->
                            Robot.Shield cell

                        TargetMine cell ->
                            Robot.Mine cell

                        TargetMove cell ->
                            Robot.Move cell
            in
            ( { model
                | game = Game.queueAction action index model.game
                , selectedRobot = Nothing
              }
            , Cmd.none
            )

        PerformTurn ->
            ( { model | game = Game.performTurn model.game |> Tuple.first }
            , Cmd.none
            )


globalStyle : Html msg
globalStyle =
    Html.node "style"
        []
        [ text
            """html, body {
                height: 100%;
                margin: 0;
               }
               body {
                display: flex;
               }
               .hover--underline:hover {
                text-decoration: underline;
               }
            """
        ]


viewSelectedRobot : Array Robot -> Int -> Maybe (Svg msg)
viewSelectedRobot robots index =
    Array.get index robots |> Maybe.map Svg.Outline.view_


viewAction : String -> QueueAction -> Int -> Html Msg
viewAction label queueAction index =
    li
        [ class "hover--underline"
        , style "cursor" "pointer"
        , style "color" "blue"
        , onClick (QueueAction queueAction index)
        ]
        [ text label ]


viewActions : Int -> Html Msg
viewActions index =
    ul [ style "list-style" "none" ]
        [ viewAction "Fire Missile" FireMissile index
        , viewAction "Fire Laser" FireLaser index
        , viewAction "Arm Missile" ArmMissile index
        , viewAction "Arm Laser" ArmLaser index
        , viewAction "Shield" Shield index
        , viewAction "Mine" Mine index
        , viewAction "Kamikaze" Kamikaze index
        , viewAction "Move" Move index
        ]


viewSelection : Selection -> Robot -> Int -> Html Msg
viewSelection selection robot index =
    case selection of
        Robot ->
            Svg.Outline.view_ robot

        ChoosingMissileTarget ->
            Svg.Grid.overlay
                (TargetFireMissile >> QueueActionTarget index)
                robot.location
                Game.Constants.missileRange
                False

        ChoosingLaserTarget ->
            Svg.Grid.overlay
                (\target ->
                    TargetFireLaser (Cell.direction robot.location target)
                        |> QueueActionTarget index
                )
                robot.location
                1
                False

        ChoosingArmMissileLocation ->
            Svg.Grid.overlay
                (TargetArmMissile >> QueueActionTarget index)
                robot.location
                Game.Constants.moveAndArmWeaponRange
                True

        ChoosingArmLaserLocation ->
            Svg.Grid.overlay
                (TargetArmLaser >> QueueActionTarget index)
                robot.location
                Game.Constants.moveAndArmWeaponRange
                True

        ChoosingShieldLocation ->
            Svg.Grid.overlay
                (TargetShield >> QueueActionTarget index)
                robot.location
                Game.Constants.moveAndShieldRange
                True

        ChoosingMineLocation ->
            Svg.Grid.overlay
                (TargetMine >> QueueActionTarget index)
                robot.location
                Game.Constants.moveAndMineRange
                True

        ChoosingMoveLocation ->
            Svg.Grid.overlay
                (TargetMove >> QueueActionTarget index)
                robot.location
                Game.Constants.moveRange
                False


view : Model -> Document Msg
view model =
    let
        robots =
            Array.toList model.game.robots
                |> List.indexedMap
                    (\index robot ->
                        if robot.destroyed then
                            text ""

                        else
                            Svg.Robot.view robot (Just (SelectRobot index))
                    )

        selection =
            model.selectedRobot
                |> Maybe.andThen
                    (\( selected, index ) ->
                        Array.get index model.game.robots
                            |> Maybe.map (\robot -> ( selected, robot, index ))
                    )
                |> Maybe.map
                    (\( selected, robot, index ) ->
                        viewSelection selected robot index
                    )
                |> Maybe.withDefault (text "")

        svgSideTotal =
            String.fromInt (Svg.Grid.gridSideSvg + CountdownRing.side * 2)

        currentTurn =
            div []
                [ span [ style "color" (Color.fromPlayer model.game.turn) ]
                    [ text (Player.toString model.game.turn) ]
                , text " is moving next"
                ]

        endTurn =
            div []
                [ button [ onClick PerformTurn ] [ text "End turn" ]
                ]
    in
    { title = "Helium 3 Singleplayer"
    , body =
        [ globalStyle
        , div
            [ style "text-align" "center"
            , style "width" "calc((100vw - 100vh) / 2)"
            ]
            [ currentTurn
            , endTurn
            ]
        , Svg.svg
            [ SA.viewBox ("0 0 " ++ svgSideTotal ++ " " ++ svgSideTotal)
            , style "display" "block"
            , style "height" "100%"
            , style "flex-grow" "2"
            ]
            (CountdownRing.view Color.green CountdownRing.init
                ++ [ Svg.svg
                        [ SA.x (String.fromInt CountdownRing.side)
                        , SA.y (String.fromInt CountdownRing.side)
                        ]
                        (List.concat
                            [ [ Svg.defs []
                                    [ Svg.Robot.def
                                    , Missile.def
                                    ]
                              , Svg.Grid.grid
                              ]
                            , robots
                            , [ selection ]

                            -- , decorations
                            ]
                        )
                   ]
            )
        , div [ style "width" "calc((100vw - 100vh) / 2)" ]
            [ case model.selectedRobot of
                Just ( Robot, index ) ->
                    viewActions index

                _ ->
                    text ""
            ]
        ]
    }
