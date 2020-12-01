module Point exposing
    ( Point
    , angle
    , around
    , fromTuple
    , fromXY
    , generator
    , toScreen
    , toScreenOffset
    , toScreenOffset2
    , toXY
    )

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


generator : Int -> Int -> Random.Generator Point
generator width height =
    Random.pair (Random.int 0 width) (Random.int 0 height)
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



{- The ring of points around the center with a diameter of three. Does not
   include the center.
-}
-- ring3 : Point -> List Point
-- ring3 (Point x y) =
--     [ fromXY (x - 1) (y - 1)
--     , fromXY x (y - 1)
--     , fromXY (x + 1) (y - 1)
--     , fromXY (x - 1) y
--     , fromXY (x + 1) y
--     , fromXY (x - 1) (y + 1)
--     , fromXY x (y + 1)
--     , fromXY (x + 1) (y + 1)
--     ]
{- The ring of cells around the center with a diameter of five. Does not
   include the inner cells, only the outside ring.
-}
-- ring5 : Point -> List Point
-- ring5 (Point x y) =
--     [ fromXY (x - 2) (y - 2)
--     , fromXY (x - 1) (y - 2)
--     , fromXY x (y - 2)
--     , fromXY (x + 1) (y - 2)
--     , fromXY (x + 2) (y - 2)
--     , fromXY (x - 2) (y - 1)
--     , fromXY (x + 2) (y - 1)
--     , fromXY (x - 2) y
--     , fromXY (x + 2) y
--     , fromXY (x - 2) (y + 1)
--     , fromXY (x + 2) (y + 1)
--     , fromXY (x - 2) (y + 2)
--     , fromXY (x - 1) (y + 2)
--     , fromXY x (y + 2)
--     , fromXY (x + 1) (y + 2)
--     , fromXY (x + 2) (y + 2)
--     ]


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
