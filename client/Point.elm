module Point exposing (Point, angle, around, decoder, mapBoth, point)

import Json.Decode as Decode exposing (Decoder)
import List.Extra


type alias Point =
    { x : Int, y : Int }


mapBoth : (Int -> Int) -> Point -> Point
mapBoth fn { x, y } =
    { x = fn x, y = fn y }


point : Int -> Int -> Point
point x y =
    { x = x, y = y }


{-| Returns the angle starting at point 1 looking at point 2
-}
angle : Point -> Point -> Float
angle point1 point2 =
    atan2 (toFloat (point2.y - point1.y)) (toFloat (point2.x - point1.x)) * 180 / pi


around : Point -> Int -> List Point
around center radius =
    List.Extra.lift2 point
        (List.range (center.x - radius) (center.x + radius))
        (List.range (center.x - radius) (center.x + radius))


decoder : Decoder Point
decoder =
    Decode.map2 point
        (Decode.field "x" Decode.int)
        (Decode.field "y" Decode.int)
