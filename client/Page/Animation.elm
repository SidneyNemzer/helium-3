module Page.Animation exposing (main)

import Animation
import Array exposing (Array)
import Browser
import Color
import CountdownRing
import Helium3Grid
import Html exposing (Html, button, div, h1, li, span, text, ul)
import Html.Attributes exposing (style)
import Html.Events exposing (onClick)
import List.Extra
import Matrix
import Missile
import Player exposing (Player(..))
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


type alias Model =
    { robot : Robot }


init : () -> ( Model, Cmd Msg )
init () =
    ( { robot = Robot.init (Point.fromGridXY 10 10) 0 Player1 }, Cmd.none )



-- UPDATE


type Msg
    = Rotate
    | Animate Animation.Msg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Rotate ->
            ( { model | robot = Robot.moveTo (Point.fromGridXY 13 13) model.robot }, Cmd.none )

        Animate time ->
            ( { model | robot = Robot.updateAnimation time model.robot }, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Animation.subscription Animate [ model.robot.animation ]



-- VIEW


view : Model -> Browser.Document Msg
view model =
    { title = "Helium 3"
    , body =
        [ div
            [ style "text-align" "center"
            , style "width" "calc((100vw - 100vh) / 2)"
            , style "padding" "20px"
            ]
            [ button [ onClick Rotate ] [ text "Rotate" ] ]
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
            (CountdownRing.view Color.green CountdownRing.init
                ++ [ Svg.svg
                        [ SA.x (String.fromInt CountdownRing.side)
                        , SA.y (String.fromInt CountdownRing.side)
                        ]
                        (List.concat
                            [ [ defs []
                                    [ Svg.Robot.def
                                    , Svg.Robot.defMissile
                                    , Missile.def
                                    ]
                              , Svg.Grid.grid
                              ]
                            , [ Robot.view Nothing model.robot
                                    |> Tuple.first
                              ]
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
