module Game.Cell exposing
    ( Cell
    , Direction
    , angle
    , around
    , direction
    , directionFromTuple
    , directionToXY
    , encode
    , encodeDirection
    , fromTuple
    , fromXY
    , generator
    , move
    , onBoard
    , ring3
    , ring5
    , toScreen
    , toScreenOffset
    , toScreenOffset2
    , toXY
    )

import Game.Constants as Constants
import Json.Encode as Encode
import List.Extra
import Random


{-| Represents movement between two cells
-}
type Direction
    = Direction Int Int


type Cell
    = Cell Int Int


fromTuple : ( Int, Int ) -> Cell
fromTuple ( x, y ) =
    Cell x y


fromXY : Int -> Int -> Cell
fromXY x y =
    Cell x y


toXY : Cell -> ( Int, Int )
toXY (Cell x y) =
    ( x, y )


encode : Cell -> Encode.Value
encode (Cell x y) =
    Encode.object
        [ ( "x", Encode.int x )
        , ( "y", Encode.int y )
        ]


generator : Int -> Int -> Random.Generator Cell
generator width height =
    Random.pair (Random.int 0 width) (Random.int 0 height)
        |> Random.map fromTuple


around : Cell -> Int -> Bool -> List Cell
around ((Cell x y) as cell) radius includeCenter =
    let
        cells =
            List.Extra.lift2 fromXY
                (List.range (x - radius) (x + radius))
                (List.range (y - radius) (y + radius))
    in
    if includeCenter then
        cells

    else
        List.Extra.remove cell cells


{-| The ring of cells around the center with a diameter of three. Does not
include the center.
-}
ring3 : Cell -> List Cell
ring3 (Cell x y) =
    [ fromXY (x - 1) (y - 1)
    , fromXY x (y - 1)
    , fromXY (x + 1) (y - 1)
    , fromXY (x - 1) y
    , fromXY (x + 1) y
    , fromXY (x - 1) (y + 1)
    , fromXY x (y + 1)
    , fromXY (x + 1) (y + 1)
    ]


{-| The ring of cells around the center with a diameter of five. Does not
include the inner cells, only the outside ring.
-}
ring5 : Cell -> List Cell
ring5 (Cell x y) =
    [ fromXY (x - 2) (y - 2)
    , fromXY (x - 1) (y - 2)
    , fromXY x (y - 2)
    , fromXY (x + 1) (y - 2)
    , fromXY (x + 2) (y - 2)
    , fromXY (x - 2) (y - 1)
    , fromXY (x + 2) (y - 1)
    , fromXY (x - 2) y
    , fromXY (x + 2) y
    , fromXY (x - 2) (y + 1)
    , fromXY (x + 2) (y + 1)
    , fromXY (x - 2) (y + 2)
    , fromXY (x - 1) (y + 2)
    , fromXY x (y + 2)
    , fromXY (x + 1) (y + 2)
    , fromXY (x + 2) (y + 2)
    ]


{-| Is the given cell inside the board area?
-}
onBoard : Cell -> Bool
onBoard (Cell x y) =
    x >= 0 && x <= Constants.gridSide && y >= 0 && y <= Constants.gridSide


directionFromTuple : ( Int, Int ) -> Direction
directionFromTuple ( x, y ) =
    Direction x y


encodeDirection : Direction -> Encode.Value
encodeDirection (Direction x y) =
    Encode.object [ ( "vX", Encode.int x ), ( "vY", Encode.int y ) ]


direction : Cell -> Cell -> Direction
direction (Cell x1 y1) (Cell x2 y2) =
    Direction (x2 - x1) (y2 - y1)


directionToXY : Direction -> ( Int, Int )
directionToXY (Direction x y) =
    ( x, y )


move : Direction -> Cell -> Cell
move (Direction mX mY) (Cell x y) =
    Cell (x + mX) (y + mY)


toScreen : Cell -> Int -> ( Int, Int )
toScreen (Cell x y) scale =
    ( x * scale, y * scale )


toScreenOffset : Cell -> Int -> Int -> ( Int, Int )
toScreenOffset (Cell x y) scale offset =
    ( x * scale + offset, y * scale + offset )


toScreenOffset2 : Cell -> Int -> ( Int, Int ) -> ( Int, Int )
toScreenOffset2 (Cell x y) scale ( offsetX, offsetY ) =
    ( x * scale + offsetX, y * scale + offsetY )


{-| Returns the angle starting at cell 1 looking at cell 2
-}
angle : Cell -> Cell -> Float
angle (Cell x1 y1) (Cell x2 y2) =
    atan2 (toFloat (y1 - y2)) (toFloat (x1 - x2)) * 180 / pi
