module Svg.Robot exposing (def, defMissile, use, view)

import Color
import Game.Cell as Cell
import Game.Robot as Robot exposing (Robot)
import Html.Attributes
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
        , linearGradient
        , radialGradient
        , rect
        , stop
        , text
        , text_
        )
import Svg.Attributes exposing (..)
import Svg.Events
import Svg.Grid


view : Robot -> Maybe msg -> Svg msg
view robot maybeOnClick =
    let
        transformCoord coord =
            String.fromInt (coord - 20)

        ( screenX, screenY ) =
            Cell.toScreen robot.location Svg.Grid.cellSide
                |> Tuple.mapBoth transformCoord transformCoord

        robotSvg =
            use
                [ x screenX, y screenY ]
                (Color.fromPlayer robot.owner)
                maybeOnClick

        targetSvg =
            Robot.moveTarget robot
                |> Maybe.map (Svg.Grid.dottedLine robot.location)
                |> Maybe.withDefault (text "")

        toolSvg =
            case robot.tool of
                Just Robot.ToolShield ->
                    text_ [ x screenX, y screenY ] [ text "Shield" ]

                Just Robot.ToolLaser ->
                    text_ [ x screenX, y screenY ] [ text "Laser" ]

                Just Robot.ToolMissile ->
                    text_ [ x screenX, y screenY ] [ text "Missile" ]

                Nothing ->
                    text ""
    in
    g [] [ robotSvg, targetSvg, toolSvg ]


{-| Renders a robot

_make sure the robot has been defined first with `def`_

-}
use : List (Svg.Attribute msg) -> String -> Maybe msg -> Svg msg
use attributes colorArg maybeOnClick =
    let
        onClick =
            case maybeOnClick of
                Just msg ->
                    [ Svg.Events.onClick msg
                    , Html.Attributes.style "cursor" "pointer"
                    ]

                Nothing ->
                    []
    in
    Svg.use
        ([ width (String.fromInt (Svg.Grid.cellSide + 40))
         , height (String.fromInt (Svg.Grid.cellSide + 40))
         , xlinkHref "#robot"
         , color colorArg
         ]
            ++ onClick
            ++ attributes
        )
        []


defMissile : Svg msg
defMissile =
    Svg.svg
        [ viewBox "0 0 77 58", fill "none", stroke "none", id "robot_missile" ]
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
        , g [ filter "url(#filter0_i)" ]
            [ Svg.path [ d "M15 18H18L24 26H15L15 18Z", fill "#F06262" ] []
            , Svg.path [ d "M15 39H18L24 31H15L15 39Z", fill "#F06262" ] []
            , ellipse [ cx "40.6701", cy "28.5001", rx "26.3299", ry "4.49987", fill "white" ] []
            , Svg.mask [ id "mask0", Html.Attributes.attribute "mask-type" "alpha", maskUnits "userSpaceOnUse", x "54", y "23", width "13", height "11" ]
                [ rect [ x "54.3608", y "23", width "12.6383", height "10.9997", fill "#C4C4C4" ] []
                ]
            , g [ mask "url(#mask0)" ]
                [ ellipse [ cx "40.6701", cy "28.5001", rx "26.3299", ry "4.49987", fill "#F16262" ] []
                ]
            , Svg.mask [ id "mask1", Html.Attributes.attribute "mask-type" "alpha", maskUnits "userSpaceOnUse", x "14", y "23", width "13", height "12" ]
                [ rect [ x "26.9788", y "34", width "12.6383", height "10.9997", transform "rotate(-180 26.9788 34)", fill "#C4C4C4" ] []
                ]
            , g [ mask "url(#mask1)" ]
                [ ellipse [ cx "40.6704", cy "28.5001", rx "26.3299", ry "4.49987", transform "rotate(-180 40.6704 28.5001)", fill "#F16262" ] []
                ]
            , Svg.mask [ id "mask2", Html.Attributes.attribute "mask-type" "alpha", maskUnits "userSpaceOnUse", x "11", y "24", width "11", height "9" ]
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
            , radialGradient [ id "paint0_radial", cx "0", cy "0", r "1", gradientUnits "userSpaceOnUse", gradientTransform "translate(38.5 29) rotate(90.9878) scale(29.0043 38.5057)" ]
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
