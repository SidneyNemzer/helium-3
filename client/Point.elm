module Point exposing
    ( Point
    , angle
    , around
    , cellSide
    , center
    , decoder
    , fromGridXY
    , offset
    , topLeft
    )

import Json.Decode as Decode exposing (Decoder)
import List.Extra
import Svg
import Svg.Attributes as SA


type Point
    = Point Int Int


cellSide : Int
cellSide =
    100


fromGridXY : Int -> Int -> Point
fromGridXY x y =
    Point (x * cellSide) (y * cellSide)


topLeft : Point -> ( Int, Int )
topLeft (Point x y) =
    ( x, y )


offset : Int -> Int -> Point -> ( Int, Int )
offset offsetX offsetY (Point x y) =
    ( x + offsetX, y + offsetY )


center : Point -> ( Int, Int )
center =
    offset (cellSide // 2) (cellSide // 2)


{-| Returns the angle starting at point 1 looking at point 2
-}
angle : Point -> Point -> Float
angle (Point x1 y1) (Point x2 y2) =
    atan2 (toFloat (y1 - y2)) (toFloat (x1 - x2)) * 180 / pi


around : Point -> Int -> List Point
around (Point x y) radiusCells =
    let
        radius =
            radiusCells * cellSide
    in
    List.Extra.lift2 fromGridXY
        (List.range (x - radius) (x + radius))
        (List.range (y - radius) (y + radius))


decoder : Decoder Point
decoder =
    Decode.map2 fromGridXY
        (Decode.field "x" Decode.int)
        (Decode.field "y" Decode.int)
