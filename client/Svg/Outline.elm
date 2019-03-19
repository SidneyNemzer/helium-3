module Svg.Outline exposing (view, view_)

import Entity
import Game.Cell as Cell exposing (Cell)
import Point exposing (Point)
import Svg exposing (Svg, rect)
import Svg.Attributes as SA exposing (fill, stroke, strokeWidth)


width : Int
width =
    120


height : Int
height =
    90


view_ : { a | location : Cell } -> Svg msg
view_ { location } =
    let
        ( x, y ) =
            Cell.toXY location
    in
    view { location = Point.fromGridXY x y, rotation = 0 }


view : { a | location : Point, rotation : Float } -> Svg msg
view { location, rotation } =
    rect
        ([ SA.height (String.fromInt height)
         , SA.width (String.fromInt width)
         , stroke "#487CFF"
         , strokeWidth "6"
         , fill "transparent"
         ]
            ++ Entity.toAttributes
                { location = location
                , rotation = rotation
                , width = width
                , height = height
                }
        )
        []
