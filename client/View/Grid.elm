module View.Grid exposing
    ( cellCorner
    , cellWidth
    , dottedLine
    , grid
    , selectedable
    , selectedableGrid
    )

import Html exposing (Html)
import List.Extra
import Position
import Svg exposing (Svg, defs, image, pattern, rect, svg)
import Svg.Attributes exposing (..)
import Svg.Events
import Svg.Keyed


line : Int -> Int -> Int -> Int -> Int -> Svg msg
line x1_ y1_ x2_ y2_ width_ =
    Svg.line
        [ x1 (String.fromInt x1_)
        , y1 (String.fromInt y1_)
        , x2 (String.fromInt x2_)
        , y2 (String.fromInt y2_)
        , strokeWidth (String.fromInt width_)
        ]
        []


{-| Distance between lines, aka "cell width". This does not factor in
line width, so it's really distance between line points.
-}
cellWidth : Int
cellWidth =
    100


{-| Width of a line. Should be even, the math here uses integer division so
there will be rounding errors if you use an odd width.
-}
lineWidth : Int
lineWidth =
    2


{-| Returns position of the top left corner of the given cell. Useful for
positioning inside the grid.
-}
cellCorner : Position.Cell -> Position.Svg
cellCorner =
    Position.toSvg { x = (*) cellWidth, y = (*) cellWidth }


{-| Returns position of the center of the given cell
-}
cellCenter : Position.Cell -> Position.Svg
cellCenter =
    Position.toSvg
        { x = (*) cellWidth >> (+) (cellWidth // 2)
        , y = (*) cellWidth >> (+) (cellWidth // 2)
        }


keyed : String -> List (Svg msg) -> List ( String, Svg msg )
keyed id =
    List.indexedMap Tuple.pair
        >> List.map (Tuple.mapFirst (String.fromInt >> (++) id))


grid : Int -> List (Html.Attribute msg) -> List ( String, Svg msg ) -> Html msg
grid widthCells attrs children =
    let
        {- Width of the whole grid, including the line width of the first and
           last lines.
        -}
        totalWidth =
            widthCells * cellWidth + lineWidth

        {- Position of the start of each line. It's not just `0` because then
           half of the line's width would be outside the view box.
        -}
        start =
            lineWidth // 2

        {- Position of the end of each line. It's not just `totalWidth` because
           then half of the line's width would be outside the view box.
        -}
        end =
            totalWidth + lineWidth // 2

        point index =
            index * cellWidth + lineWidth // 2

        {- A list of points where lines should go. This can be changed to
           remove lines from the start or end.
        -}
        lineIndexes =
            List.range 1 (widthCells - 1)
    in
    Svg.Keyed.node "svg"
        ([ stroke "black"
         , viewBox <|
            "0 0 "
                ++ String.fromInt totalWidth
                ++ " "
                ++ String.fromInt totalWidth
         ]
            ++ attrs
        )
        (List.concat
            [ List.map
                (\index -> line start (point index) end (point index) lineWidth)
                lineIndexes
                |> keyed "linesHorizontal"
            , List.map
                (\index -> line (point index) start (point index) end lineWidth)
                lineIndexes
                |> keyed "linesVertical"
            , children
            ]
        )


selectedableGrid : (Position.Cell -> msg) -> Position.Cell -> Int -> List (Svg msg)
selectedableGrid onClick centerPosition range =
    let
        center =
            Position.xyCell centerPosition

        xPositions =
            List.range (center.x - range) (center.x + range)

        yPositions =
            List.range (center.y - range) (center.y + range)
    in
    List.Extra.lift2
        (\x y ->
            let
                position =
                    Position.cell { x = x, y = y }
            in
            selectedable (onClick position) position
        )
        xPositions
        yPositions


selectedable : msg -> Position.Cell -> Svg msg
selectedable onClick cellPosition =
    let
        svgPosition =
            cellCorner cellPosition |> Position.xySvg
    in
    rect
        [ x (String.fromInt (svgPosition.x + 4))
        , y (String.fromInt (svgPosition.y + 4))
        , height (String.fromInt (cellWidth - 8))
        , width (String.fromInt (cellWidth - 8))
        , stroke "#487CFF"
        , strokeWidth "6"
        , fill "transparent"
        , style "cursor: pointer;"
        , Svg.Events.onClick onClick
        ]
        []


dottedLine : Position.Cell -> Position.Cell -> Svg msg
dottedLine cell1 cell2 =
    let
        svg1 =
            cellCenter cell1 |> Position.xySvg

        svg2 =
            cellCenter cell2 |> Position.xySvg
    in
    Svg.line
        [ x1 (String.fromInt svg1.x)
        , y1 (String.fromInt svg1.y)
        , x2 (String.fromInt svg2.x)
        , y2 (String.fromInt svg2.y)
        , strokeWidth (String.fromInt (lineWidth * 2))
        , strokeDasharray "30 10"
        , stroke "#487CFF"
        ]
        []
