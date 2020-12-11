module View.Miner exposing (def, use)

import Html exposing (Html)
import Html.Attributes as HA
import Html.Events exposing (onClick)
import Point exposing (Point)
import Svg exposing (Svg, defs, feBlend, feColorMatrix, feComposite, feFlood, feGaussianBlur, feOffset, g, rect, svg)
import Svg.Attributes exposing (..)


use : Point -> Float -> Svg msg
use point rotation =
    let
        ( x_, y_ ) =
            Point.toScreen point 2

        centerPx =
            (toFloat x_ + 1 |> String.fromFloat)
                ++ "px "
                ++ (toFloat y_ + 1 |> String.fromFloat)
                ++ "px"

        center =
            (toFloat x_ + 1 |> String.fromFloat)
                ++ " "
                ++ (toFloat y_ + 1 |> String.fromFloat)

        rotate =
            "rotate("
                ++ String.fromFloat rotation
                ++ ")"
    in
    Svg.use
        [ xlinkHref "#miner"
        , x <| String.fromFloat <| toFloat x_ + 2
        , y <| String.fromFloat <| toFloat y_ + 0.25
        , width "0.5"
        , height "1.5"
        , transform rotate
        , HA.style "transform-origin" centerPx
        , HA.style "transition" "x 1s, y 1s, transform 1s, transform-origin 1s"
        ]
        []


def : Svg msg
def =
    svg [ viewBox "0 0 12 35", fill "none", id "miner" ]
        [ g [ filter "url(#filter0_i11111)" ]
            [ rect [ width "12", height "35", fill "#9C9C9C" ] [] ]
        , defs []
            [ Svg.filter [ id "filter0_i11111", x "-2", y "0", width "14", height "35", filterUnits "userSpaceOnUse", colorInterpolationFilters "sRGB" ]
                [ feFlood [ floodOpacity "0", result "BackgroundImageFix" ] []
                , feBlend [ mode "normal", in_ "SourceGraphic", in2 "BackgroundImageFix", result "shape" ] []
                , feColorMatrix [ in_ "SourceAlpha", type_ "matrix", values "0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 127 0", result "hardAlpha" ] []
                , feOffset [ dx "-2" ] []
                , feGaussianBlur [ stdDeviation "2" ] []
                , feComposite [ in2 "hardAlpha", operator "arithmetic", k2 "-1", k3 "1" ] []
                , feColorMatrix [ type_ "matrix", values "0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0.25 0" ] []
                , feBlend [ mode "normal", in2 "shape", result "effect1_innerShadow" ] []
                ]
            ]
        ]
