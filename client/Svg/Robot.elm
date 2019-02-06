module Svg.Robot exposing (def, outline, use)

import Html.Attributes
import Point exposing (Point)
import Svg exposing (Svg, defs, g, linearGradient, radialGradient, rect, stop)
import Svg.Attributes exposing (..)
import Svg.Events
import Svg.Grid


outline : { a | location : Point, rotation : Float } -> Svg msg
outline robot =
    let
        ( x_, y_ ) =
            Point.topLeft robot.location

        ( cX, cY ) =
            Point.center robot.location
    in
    rect
        [ x (String.fromInt (x_ - 20))
        , y (String.fromInt (y_ - 10))
        , height (String.fromInt (Svg.Grid.cellSide + 20))
        , width (String.fromInt (Svg.Grid.cellSide + 40))
        , stroke "#487CFF"
        , strokeWidth "6"
        , fill "transparent"
        , Html.Attributes.style
            "transform-origin"
            (String.fromInt cX ++ "px " ++ String.fromInt cY ++ "px")
        , Html.Attributes.style
            "transform"
            ("rotate(" ++ String.fromFloat robot.rotation ++ "deg)")
        ]
        []


{-| Renders a robot

_make sure the robot has been defined first with `def`_

-}
use : List (Svg.Attribute msg) -> String -> msg -> Svg msg
use attributes colorArg onClick =
    Svg.use
        ([ width (String.fromInt (Svg.Grid.cellSide + 40))
         , height (String.fromInt (Svg.Grid.cellSide + 40))
         , xlinkHref "#robot"
         , color colorArg
         , Svg.Events.onClick onClick
         ]
            ++ attributes
        )
        []


{-| Use this value to define the robot in a `def` element, then place it any
number of times with `use`
-}
def : Svg msg
def =
    Svg.svg
        [ viewBox "0 0 77 58", fill "none", stroke "none", id "robot" ]
        [ rect [ width "77", height "58", rx "3", transform "matrix(-1 0 0 1 77 0)", fill "url(#paint0_radial)" ] []
        , Svg.path [ d "M8 13C8 10.7909 9.79086 9 12 9H63C66.3137 9 69 11.6863 69 15V43C69 46.3137 66.3137 49 63 49H12C9.79086 49 8 47.2091 8 45V13Z", fill "currentColor" ] []
        , Svg.path [ d "M8 13C8 10.7909 9.79086 9 12 9H63C66.3137 9 69 11.6863 69 15V43C69 46.3137 66.3137 49 63 49H12C9.79086 49 8 47.2091 8 45V13Z", fill "url(#paint1_linear)" ] []
        , Svg.path [ d "M8 13C8 10.7909 9.79086 9 12 9H63C66.3137 9 69 11.6863 69 15V43C69 46.3137 66.3137 49 63 49H12C9.79086 49 8 47.2091 8 45V13Z", fill "url(#paint2_linear)" ] []
        , rect [ x "65", y "14", width "4", height "9", fill "#E1EF38" ] []
        , rect [ x "65", y "33", width "4", height "9", fill "#E1EF38" ] []
        , rect [ x "15", y "5", width "12", height "4", fill "#595959" ] []
        , rect [ x "15", y "5", width "12", height "4", fill "url(#paint3_linear)" ] []
        , rect [ x "32", y "5", width "12", height "4", fill "#595959" ] []
        , rect [ x "32", y "5", width "12", height "4", fill "url(#paint4_linear)" ] []
        , rect [ x "49", y "5", width "12", height "4", fill "#595959" ] []
        , rect [ x "49", y "5", width "12", height "4", fill "url(#paint5_linear)" ] []
        , rect [ x "15", y "49", width "12", height "4", fill "#595959" ] []
        , rect [ x "15", y "49", width "12", height "4", fill "url(#paint6_linear)" ] []
        , rect [ x "32", y "49", width "12", height "4", fill "#595959" ] []
        , rect [ x "32", y "49", width "12", height "4", fill "url(#paint7_linear)" ] []
        , rect [ x "49", y "49", width "12", height "4", fill "#595959" ] []
        , rect [ x "49", y "49", width "12", height "4", fill "url(#paint8_linear)" ] []
        , defs []
            [ radialGradient [ id "paint0_radial", cx "0", cy "0", r "1", gradientUnits "userSpaceOnUse", gradientTransform "translate(38.5 29) rotate(90.9878) scale(29.0043 38.5057)" ]
                [ stop [ offset "0.486188" ] []
                , stop [ offset "1", stopOpacity "0" ] []
                ]
            , linearGradient [ id "paint1_linear", x1 "8", y1 "29", x2 "69", y2 "29", gradientUnits "userSpaceOnUse" ]
                [ stop [ stopOpacity "0.43" ] []
                , stop [ offset "0.0782796", stopColor "#454545", stopOpacity "0" ] []
                , stop [ offset "0.879548", stopColor "#C4C4C4", stopOpacity "0" ] []
                , stop [ offset "1", stopColor "#FFE55A", stopOpacity "0.9" ] []
                ]
            , linearGradient [ id "paint2_linear", x1 "38.5", y1 "9", x2 "38.5", y2 "49", gradientUnits "userSpaceOnUse" ]
                [ stop [ stopOpacity "0.48" ] []
                , stop [ offset "0.0530775", stopOpacity "0" ] []
                , stop [ offset "0.946731", stopOpacity "0" ] []
                , stop [ offset "1", stopOpacity "0.46" ] []
                ]
            , linearGradient [ id "paint3_linear", x1 "27", y1 "7", x2 "15", y2 "7", gradientUnits "userSpaceOnUse" ]
                [ stop [ offset "0.0225949" ] []
                , stop [ offset "0.46844", stopColor "#595959" ] []
                , stop [ offset "0.937507" ] []
                ]
            , linearGradient [ id "paint4_linear", x1 "44", y1 "7", x2 "32", y2 "7", gradientUnits "userSpaceOnUse" ]
                [ stop [ offset "0.0225949" ] []
                , stop [ offset "0.46844", stopColor "#595959" ] []
                , stop [ offset "0.937507" ] []
                ]
            , linearGradient [ id "paint5_linear", x1 "61", y1 "7", x2 "49", y2 "7", gradientUnits "userSpaceOnUse" ]
                [ stop [ offset "0.0225949" ] []
                , stop [ offset "0.46844", stopColor "#595959" ] []
                , stop [ offset "0.937507" ] []
                ]
            , linearGradient [ id "paint6_linear", x1 "27", y1 "51", x2 "15", y2 "51", gradientUnits "userSpaceOnUse" ]
                [ stop [ offset "0.0225949" ] []
                , stop [ offset "0.46844", stopColor "#595959" ] []
                , stop [ offset "0.937507" ] []
                ]
            , linearGradient [ id "paint7_linear", x1 "44", y1 "51", x2 "32", y2 "51", gradientUnits "userSpaceOnUse" ]
                [ stop [ offset "0.0225949" ] []
                , stop [ offset "0.46844", stopColor "#595959" ] []
                , stop [ offset "0.937507" ] []
                ]
            , linearGradient [ id "paint8_linear", x1 "61", y1 "51", x2 "49", y2 "51", gradientUnits "userSpaceOnUse" ]
                [ stop [ offset "0.0225949" ] []
                , stop [ offset "0.46844", stopColor "#595959" ] []
                , stop [ offset "0.937507" ] []
                ]
            ]
        ]
