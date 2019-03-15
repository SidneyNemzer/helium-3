module Game.Cell exposing
    ( Cell
    , encode
    , fromTuple
    , fromXY
    , generator
    , ring3
    , ring5
    , toXY
    )

import Json.Encode as Encode
import Random


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
