module Game.Cell exposing
    ( Cell
    , Direction
    , around
    , direction
    , directionFromTuple
    , encode
    , encodeDirection
    , fromTuple
    , fromXY
    , generator
    , move
    , onBoard
    , ring3
    , ring5
    , toXY
    )

import Game.Constants as Constants
import Json.Encode as Encode
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


around : Cell -> Int -> List Cell
around (Cell x y) radius =
    List.map2 fromXY
        (List.range (x - radius) (x + radius))
        (List.range (y - radius) (y + radius))


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


move : Direction -> Cell -> Cell
move (Direction mX mY) (Cell x y) =
    Cell (x + mX) (y + mY)
