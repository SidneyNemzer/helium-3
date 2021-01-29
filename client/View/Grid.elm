module View.Grid exposing (..)

import Color
import Html exposing (Html)
import Html.Attributes as HA
import Html.Events exposing (onClick)
import Point exposing (Point)
import Svg exposing (Svg, g, rect, svg, text, text_)
import Svg.Attributes exposing (..)


lineStrokeWidth : Float
lineStrokeWidth =
    0.1


{-| Number of cells on each side of the grid
-}
gridSideCells : Int
gridSideCells =
    20


{-| The corners of the grid in SVG coordinates, formatted as an SVG viewBox string
-}
viewBox : String
viewBox =
    [ -lineStrokeWidth / 2
    , -lineStrokeWidth / 2
    , toFloat gridSideCells * 2 + lineStrokeWidth
    , toFloat gridSideCells * 2 + lineStrokeWidth
    ]
        |> List.map String.fromFloat
        |> String.join " "


line : Float -> Float -> Float -> Float -> Svg msg
line x1_ y1_ x2_ y2_ =
    Svg.line
        [ x1 (String.fromFloat x1_)
        , y1 (String.fromFloat y1_)
        , x2 (String.fromFloat x2_)
        , y2 (String.fromFloat y2_)
        ]
        []


grid : Svg msg
grid =
    let
        start =
            0 - lineStrokeWidth / 2

        end =
            toFloat gridSideCells * 2 + lineStrokeWidth / 2

        {- Indexes of the lines we want to render -}
        lineIndexes : List Float
        lineIndexes =
            List.range 0 gridSideCells |> List.map toFloat

        horizontalLine index =
            line start (index * 2) end (index * 2)

        verticalLine index =
            line (index * 2) start (index * 2) end
    in
    g
        [ stroke "#797979"
        , strokeWidth (String.fromFloat lineStrokeWidth)
        ]
    <|
        List.concatMap
            (\index -> [ verticalLine index, horizontalLine index ])
            lineIndexes



-- DECORATIONS


style : Html msg
style =
    Html.node "style"
        []
        [ text """
            .show-on-hover {
                opacity: 0;
            }
            .show-on-hover:hover {
                opacity: 1;
            }
          """
        ]


{-| Changes a square on top of a grid cell to show it is clickable

The return value is split into two parts. The `hover` must be rendered
after any other highlights so that all the hovers are on top of the
highlights. This is required to allow hover effects to work because
SVG does not respect z-index.

-}
highlightClickable : (Point -> msg) -> Point -> { highlight : Svg msg, hover : Svg msg }
highlightClickable onClickMsg point =
    let
        ( x_, y_ ) =
            Point.toXY point

        baseAttrs =
            [ x <| String.fromFloat <| toFloat x_ * 2
            , y <| String.fromFloat <| toFloat y_ * 2
            , width "2"
            , height "2"
            , strokeWidth <| String.fromFloat lineStrokeWidth
            , fill "transparent"
            , HA.style "cursor" "pointer"
            ]
    in
    { highlight =
        rect ([ stroke "#487CFF" ] ++ baseAttrs) []
    , hover =
        rect
            ([ stroke "black"
             , class "show-on-hover"
             , onClick <| onClickMsg point
             ]
                ++ baseAttrs
            )
            []
    }


highlight : Point -> Svg msg
highlight point =
    let
        ( x_, y_ ) =
            Point.toXY point
    in
    rect
        [ stroke "#487CFF"
        , x <| String.fromFloat <| toFloat x_ * 2
        , y <| String.fromFloat <| toFloat y_ * 2
        , width "2"
        , height "2"
        , strokeWidth <| String.fromFloat lineStrokeWidth
        , fill "transparent"
        ]
        []


highlightAround :
    Point
    -> Int
    -> (Point -> msg)
    -> Bool
    -> { highlight : Svg msg, hover : Svg msg }
highlightAround point radius onClickMsg includeCenter =
    let
        ( highlights, hovers ) =
            Point.area point radius includeCenter
                |> List.map
                    (highlightClickable onClickMsg
                        >> (\svg -> ( svg.highlight, svg.hover ))
                    )
                |> List.unzip
    in
    { highlight = g [] highlights
    , hover = g [] hovers
    }


{-| Creates a line between two squares on the grid. The line starts and ends at
the border of the squares.
-}
dottedLine : Point -> Point -> Svg msg
dottedLine start end =
    let
        ( startX, startY ) =
            Point.toXY start

        ( endX, endY ) =
            Point.toXY end

        square x_ y_ w color =
            rect
                [ x <| String.fromInt <| x_ * 2
                , y <| String.fromInt <| y_ * 2
                , width w
                , height w
                , fill color
                ]
                []

        idString =
            [ startX, startY, endX, endY ]
                |> List.map String.fromInt
                |> String.join "-"
    in
    g []
        [ Svg.mask [ id idString ]
            [ square 0 0 (String.fromInt <| gridSideCells * 2) "white"
            , square startX startY "2" "black"
            , square endX endY "2" "black"
            ]
        , Svg.line
            -- Offset x and y to avoid vertical/horizontal lines
            -- https://stackoverflow.com/q/39475396/7486612
            [ x1 <| String.fromFloat <| toFloat startX * 2 + 1 + 0.01
            , y1 <| String.fromFloat <| toFloat startY * 2 + 1 + 0.01
            , x2 <| String.fromInt <| endX * 2 + 1
            , y2 <| String.fromInt <| endY * 2 + 1
            , strokeWidth <| String.fromFloat lineStrokeWidth
            , strokeDasharray "1 0.3"
            , stroke "#487CFF"
            , mask <| "url(#" ++ idString ++ ")"
            ]
            []
        ]


fillCell : Point -> Int -> Svg msg
fillCell point amount =
    let
        lightness =
            100 - round (toFloat amount * 0.033)

        ( topX, topY ) =
            Point.toScreen point 2
    in
    rect
        [ x <| String.fromFloat <| toFloat topX + lineStrokeWidth / 2
        , y <| String.fromFloat <| toFloat topY + lineStrokeWidth / 2
        , width <| String.fromFloat <| 2 - lineStrokeWidth
        , height <| String.fromFloat <| 2 - lineStrokeWidth
        , fill <| Color.blueShade lightness
        ]
        []


{-| Creates a square similar to `fillCell`, but places text at the top left
with the amount and lightness values
-}
fillCellDebug : Point -> Int -> Svg msg
fillCellDebug point amount =
    let
        lightness =
            100 - round (toFloat amount * 0.033)

        -- 100 - Basics.min 50 (round (toFloat amount * 0.033))
        ( topX, topY ) =
            Point.toScreen point 2
    in
    g []
        [ rect
            [ x <| String.fromFloat <| toFloat topX + lineStrokeWidth / 2
            , y <| String.fromFloat <| toFloat topY + lineStrokeWidth / 2
            , width <| String.fromFloat <| 2 - lineStrokeWidth
            , height <| String.fromFloat <| 2 - lineStrokeWidth
            , fill <| Color.blueShade lightness
            ]
            []
        , text_
            [ x <| String.fromFloat <| toFloat topX + lineStrokeWidth / 2
            , y <| String.fromFloat <| toFloat topY + lineStrokeWidth / 2 + 0.35
            , HA.style "font-size" "0.35px"
            , fill "white"
            ]
            [ text <| String.fromInt amount, text ",", text <| String.fromInt lightness ]
        ]
