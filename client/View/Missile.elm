module View.Missile exposing (..)

import Html exposing (Html)
import Html.Attributes as HA
import Point exposing (Point)
import Svg
    exposing
        ( Svg
        , defs
        , ellipse
        , feBlend
        , feColorMatrix
        , feComposite
        , feFlood
        , feGaussianBlur
        , feOffset
        , g
        , rect
        , text
        )
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

        rotate =
            "rotate("
                ++ String.fromFloat rotation
                ++ ")"
    in
    Svg.use
        [ xlinkHref "#robot_missile"
        , x <| String.fromFloat <| toFloat x_ - 0.5
        , y <| String.fromFloat <| toFloat y_ - 0.5
        , width "3"
        , height "3"
        , transform rotate
        , HA.style "animation" "0.5s linear zoom"
        , HA.style "transform-origin" centerPx
        , HA.style "transition" "x 1s, y 1s, transform 1s, transform-origin 1s"
        ]
        []


style : Html msg
style =
    Html.node "style"
        []
        [ text """
            @keyframes zoom {
              from { transform: scale(0); }
              to { transform: scale(1); }
            }
          """
        ]


def : Svg msg
def =
    Svg.svg
        [ viewBox "0 0 77 58", fill "none", stroke "none", id "robot_missile" ]
        [ g [ filter "url(#filter0_i)" ]
            [ Svg.path [ d "M15 18H18L24 26H15L15 18Z", fill "#F06262" ] []
            , Svg.path [ d "M15 39H18L24 31H15L15 39Z", fill "#F06262" ] []
            , ellipse [ cx "40.6701", cy "28.5001", rx "26.3299", ry "4.49987", fill "white" ] []
            , Svg.mask [ id "mask0", HA.attribute "mask-type" "alpha", maskUnits "userSpaceOnUse", x "54", y "23", width "13", height "11" ]
                [ rect [ x "54.3608", y "23", width "12.6383", height "10.9997", fill "#C4C4C4" ] []
                ]
            , g [ mask "url(#mask0)" ]
                [ ellipse [ cx "40.6701", cy "28.5001", rx "26.3299", ry "4.49987", fill "#F16262" ] []
                ]
            , Svg.mask [ id "mask1", HA.attribute "mask-type" "alpha", maskUnits "userSpaceOnUse", x "14", y "23", width "13", height "12" ]
                [ rect [ x "26.9788", y "34", width "12.6383", height "10.9997", transform "rotate(-180 26.9788 34)", fill "#C4C4C4" ] []
                ]
            , g [ mask "url(#mask1)" ]
                [ ellipse [ cx "40.6704", cy "28.5001", rx "26.3299", ry "4.49987", transform "rotate(-180 40.6704 28.5001)", fill "#F16262" ] []
                ]
            , Svg.mask [ id "mask2", HA.attribute "mask-type" "alpha", maskUnits "userSpaceOnUse", x "11", y "24", width "11", height "9" ]
                [ rect [ width "9.36174", height "7.11756", rx "3", transform "matrix(-1 0 0 1 21.3617 24.9413)", fill "#C4C4C4" ] []
                ]
            , g [ mask "url(#mask2)" ]
                [ rect [ x "14.3405", y "25.5884", width "8.19152", height "5.82346", fill "#F06262" ] []
                ]
            ]
        , defs []
            [ Svg.filter [ id "filter0_i", x "12", y "18", width "55", height "23", filterUnits "userSpaceOnUse", colorInterpolationFilters "sRGB" ]
                [ feFlood [ floodOpacity "0", result "BackgroundImageFix" ] []
                , feBlend [ mode "normal", in_ "SourceGraphic", in2 "BackgroundImageFix", result "shape" ] []
                , feColorMatrix [ in_ "SourceAlpha", type_ "matrix", values "0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 127 0", result "hardAlpha" ] []
                , feOffset [ dy "2" ] []
                , feGaussianBlur [ stdDeviation "1" ] []
                , feComposite [ in2 "hardAlpha", operator "arithmetic", k2 "-1", k3 "1" ] []
                , feColorMatrix [ type_ "matrix", values "0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0.25 0" ] []
                , feBlend [ mode "normal", in2 "shape", result "effect1_innerShadow" ] []
                ]
            ]
        ]
