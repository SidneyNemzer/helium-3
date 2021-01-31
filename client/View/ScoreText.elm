module View.ScoreText exposing (..)

import Html exposing (Html)
import Html.Attributes as HA
import Point exposing (Point)
import Svg exposing (Svg, text, text_)
import Svg.Attributes as SA exposing (..)


durationSeconds : Int
durationSeconds =
    2


view : Point -> Int -> Svg msg
view location amount =
    let
        ( x, y ) =
            Point.toScreenOffset location 2 1
    in
    text_
        [ SA.x <| String.fromFloat <| toFloat x
        , SA.y <| String.fromFloat <| toFloat y - 1.5
        , HA.style "font-size" "0.6px"
        , HA.style "animation" <| String.fromInt durationSeconds ++ "s linear slide"
        , fill "black"
        , textAnchor "middle"
        ]
        [ text "$", text <| String.fromInt amount ]


style : Html msg
style =
    Html.node "style"
        []
        [ text """
            @keyframes slide {
              from { transform: translateY(1.5px); }
              to { transform: translateY(0); }
            }
          """
        ]
