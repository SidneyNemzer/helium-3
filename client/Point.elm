module Point exposing
    ( Point
    , angle
    , area
    , decoder
    , encoder
    , fromTuple
    , fromXY
    , generator
    , ring
    , toScreen
    , toScreenOffset
    , toScreenOffset2
    , toSvgOffset
    , toXY
    )

import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Extra as Decode
import Json.Encode as Encode exposing (Value)
import List.Extra
import Random
import Svg
import Svg.Attributes


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


{-| Given a center point and a radius, returns the points that are inside
the area. Only returns points that fall on the board.
-}
area : Point -> Int -> Bool -> List Point
area ((Point x y) as point) radius includeCenter =
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


{-| Similar to `area`, but only returns points on the outer edge of
the area.
-}
ring : Point -> Int -> List Point
ring (Point cX cY) radius =
    List.Extra.lift2 Tuple.pair
        (List.range (cX - radius) (cX + radius))
        (List.range (cY - radius) (cY + radius))
        |> List.filter
            (\( x, y ) ->
                (x > cX + radius - 1 || x < cX - radius + 1)
                    || (y > cY + radius - 1 || y < cY - radius + 1)
            )
        |> List.map fromTuple


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


encoder : Point -> Value
encoder (Point x y) =
    Encode.object [ ( "x", Encode.int x ), ( "y", Encode.int y ) ]


toSvgOffset : Point -> Float -> Float -> List (Svg.Attribute msg)
toSvgOffset (Point x y) scale offset =
    [ Svg.Attributes.x <| String.fromFloat <| toFloat x * scale + offset
    , Svg.Attributes.y <| String.fromFloat <| toFloat y * scale + offset
    ]
