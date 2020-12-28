module View.Shield exposing (..)

import Html exposing (Html, text)
import Html.Attributes as HA
import Point exposing (Point)
import Svg exposing (Svg, rect, svg)
import Svg.Attributes exposing (..)


shield : Point -> Float -> Svg msg
shield point rotation =
    let
        ( x_, y_ ) =
            Point.toXY point

        center =
            (toFloat x_ * 2 + 1 |> String.fromFloat)
                ++ " "
                ++ (toFloat y_ * 2 + 1 |> String.fromFloat)

        rotate =
            "rotate("
                ++ String.fromFloat rotation
                ++ " "
                ++ center
                ++ ")"
    in
    svg
        [ x <| String.fromFloat <| toFloat x_ * 2 - 0.5
        , y <| String.fromFloat <| toFloat y_ * 2 - 0.5
        , transform rotate
        , HA.style "transition" "x 1s, y 1s, transform 1s"
        , width "3"
        , viewBox "0 0 81 62"
        , fill "none"
        ]
        [ rect [ y "62", width "62", height "81", rx "25", transform "rotate(-90 0 62)", fill "#5384CD", fillOpacity "0.33" ] []
        , rect [ x "0.125", y "61.875", width "61.75", height "80.75", rx "24.875", transform "rotate(-90 0.125 61.875)", stroke "#959595", strokeOpacity "0.42", strokeWidth "0.25" ] []
        ]


style : Html msg
style =
    Html.node "style"
        []
        [ text """
            @keyframes fade {
              from { opacity: 1; }
              to { opacity: 0; }
            }
          """
        ]


use : Point -> Float -> Bool -> Svg msg
use point rotation highlight =
    let
        ( x_, y_ ) =
            Point.toXY point

        center =
            (toFloat x_ * 2 + 1 |> String.fromFloat)
                ++ " "
                ++ (toFloat y_ * 2 + 1 |> String.fromFloat)

        rotate =
            "rotate("
                ++ String.fromFloat rotation
                ++ " "
                ++ center
                ++ ")"

        highlightAttr =
            if highlight then
                -- TODO shield should become bright, but the fill does not work here
                [ fill "#ffffff"
                , HA.style "animation" "1s linear fade"
                ]

            else
                []
    in
    Svg.use
        ([ xlinkHref "#robot_shield"
         , x <| String.fromFloat <| toFloat x_ * 2 - 0.5
         , y <| String.fromFloat <| toFloat y_ * 2 - 0.5
         , transform rotate
         , HA.style "transition" "x 1s, y 1s, transform 1s"
         , width "3"
         , height "3"
         ]
            ++ highlightAttr
        )
        []


def : Svg msg
def =
    svg [ viewBox "0 0 81 62", fill "none", id "robot_shield" ]
        [ rect [ y "62", width "62", height "81", rx "25", transform "rotate(-90 0 62)", fill "#5384CD", fillOpacity "0.33" ] []
        , rect [ x "0.125", y "61.875", width "61.75", height "80.75", rx "24.875", transform "rotate(-90 0.125 61.875)", stroke "#959595", strokeOpacity "0.42", strokeWidth "0.25" ] []
        ]
