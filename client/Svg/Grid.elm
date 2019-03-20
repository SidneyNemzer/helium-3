module Svg.Grid exposing
    ( cellSide
    , dottedLine
    , fillCell
    , grid
    , gridSideSvg
    , overlay
    , overlayCell
    )

import Color
import Game.Cell as Cell exposing (Cell)
import Html exposing (Html)
import List.Extra
import Point exposing (Point)
import Svg exposing (Svg, defs, image, pattern, rect, svg)
import Svg.Attributes exposing (..)
import Svg.Events
import Svg.Keyed


{-| Distance between lines, aka "cell width". This does not factor in
line width, so it's really distance between line points.
-}
cellSide : Int
cellSide =
    100


{-| Width of a line. Should be even, the math here uses integer division so
there will be rounding errors if you use an odd width.
-}
lineWidth : Int
lineWidth =
    2


gridSide : Int
gridSide =
    20


{-| Length of a side in SVG units
-}
gridSideSvg : Int
gridSideSvg =
    cellSide * gridSide + lineWidth


line : Int -> Int -> Int -> Int -> Svg msg
line x1_ y1_ x2_ y2_ =
    Svg.line
        [ x1 (String.fromInt x1_)
        , y1 (String.fromInt y1_)
        , x2 (String.fromInt x2_)
        , y2 (String.fromInt y2_)
        , strokeWidth (String.fromInt lineWidth)
        ]
        []


grid : Svg msg
grid =
    let
        {- Width of the whole grid, including the line width of the first and
           last lines.
        -}
        totalWidth =
            gridSide * cellSide + lineWidth

        {- Offset lines by half their width, otherwise half of the first line is
           outside the viewbox.
        -}
        start =
            lineWidth // 2

        {- Offset the end for the same reason as `start` -}
        end =
            totalWidth + lineWidth // 2

        {- Indexes of the lines we want to render. We leave the first and last
           lines out.
        -}
        lineIndexes =
            List.range 1 (gridSide - 1)

        coordinateOf index =
            index * cellSide + lineWidth // 2

        horizontalLine index =
            line start (coordinateOf index) end (coordinateOf index)

        verticalLine index =
            line (coordinateOf index) start (coordinateOf index) end
    in
    svg [ stroke "black" ] <|
        List.concatMap
            (\index -> [ verticalLine index, horizontalLine index ])
            lineIndexes


overlayCell : Maybe msg -> Cell -> Svg msg
overlayCell onClick cell =
    let
        ( x_, y_ ) =
            Cell.toScreen cell cellSide
    in
    rect
        ([ x (String.fromInt (x_ + 4))
         , y (String.fromInt (y_ + 4))
         , height (String.fromInt (cellSide - 8))
         , width (String.fromInt (cellSide - 8))
         , stroke "#487CFF"
         , strokeWidth "6"
         , fill "transparent"
         , style "cursor: pointer;"
         ]
            ++ (case onClick of
                    Just msg ->
                        [ Svg.Events.onClick msg ]

                    Nothing ->
                        []
               )
        )
        []


overlay : (Cell -> msg) -> Cell -> Int -> Bool -> Svg msg
overlay onClick centerCell radius includeCenter =
    Cell.around centerCell radius includeCenter
        |> List.map (\point -> overlayCell (Just (onClick point)) point)
        |> Svg.g []


dottedLine : Cell -> Cell -> Svg msg
dottedLine start end =
    let
        halfSide =
            cellSide // 2

        ( startX, startY ) =
            Cell.toScreenOffset start cellSide halfSide

        ( endX, endY ) =
            Cell.toScreenOffset end cellSide halfSide
    in
    Svg.line
        [ x1 (String.fromInt startX)
        , y1 (String.fromInt startY)
        , x2 (String.fromInt endX)
        , y2 (String.fromInt endY)
        , strokeWidth (String.fromInt (lineWidth * 2))
        , strokeDasharray "30 10"
        , stroke Color.blue
        ]
        []


fillCell : Cell -> String -> Svg msg
fillCell cell color =
    let
        ( topX, topY ) =
            Cell.toScreen cell cellSide
                |> Tuple.mapBoth String.fromInt String.fromInt
    in
    rect
        [ x topX
        , y topY
        , width (String.fromInt cellSide)
        , height (String.fromInt cellSide)
        , fill color
        ]
        []
