module Svg.Outline exposing (view)

import Entity
import Point exposing (Point)
import Svg exposing (Svg, rect)
import Svg.Attributes as SA exposing (fill, stroke, strokeWidth)


width : Int
width =
    120


height : Int
height =
    90


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
