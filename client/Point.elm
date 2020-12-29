module Point exposing
    ( Point
    , angle
    , around
    , decoder
    , fromTuple
    , fromXY
    , generator
    , toScreen
    , toScreenOffset
    , toScreenOffset2
    , toXY
    )

import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Extra as Decode
import List.Extra
import Random


type Point
    = Point Int Int


fromTuple : ( Int, Int ) -> Point
fromTuple ( x, y ) =
    Point x y


fromXY : Int -> Int -> Point
fromXY x y =
    Point x y


toXY : Point -> ( Int, Int )
toXY (Point x y) =
    ( x, y )


{-| Generates a random point somewhere in the grid
-}
generator : Random.Generator Point
generator =
    Random.pair (Random.int 0 20) (Random.int 0 20)
        |> Random.map fromTuple


around : Point -> Int -> Bool -> List Point
around ((Point x y) as point) radius includeCenter =
    let
        points =
            List.Extra.lift2 fromXY
                (List.range (x - radius) (x + radius))
                (List.range (y - radius) (y + radius))
    in
    if includeCenter then
        points

    else
        List.Extra.remove point points
            |> List.filter isInsideGrid


toScreen : Point -> Int -> ( Int, Int )
toScreen (Point x y) scale =
    ( x * scale, y * scale )


toScreenOffset : Point -> Int -> Int -> ( Int, Int )
toScreenOffset (Point x y) scale offset =
    ( x * scale + offset, y * scale + offset )


toScreenOffset2 : Point -> Int -> ( Int, Int ) -> ( Int, Int )
toScreenOffset2 (Point x y) scale ( offsetX, offsetY ) =
    ( x * scale + offsetX, y * scale + offsetY )


{-| Returns the angle starting at cell 1 looking at cell 2
-}
angle : Point -> Point -> Float
angle (Point x1 y1) (Point x2 y2) =
    atan2 (toFloat (y2 - y1)) (toFloat (x2 - x1)) * 180 / pi


isInsideGrid : Point -> Bool
isInsideGrid (Point x y) =
    x >= 0 && x < 20 && y >= 0 && y < 20


decoder : Decoder Point
decoder =
    Decode.succeed fromXY
        |> Decode.andMap (Decode.field "x" Decode.int)
        |> Decode.andMap (Decode.field "y" Decode.int)
