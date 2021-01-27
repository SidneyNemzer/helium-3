module HeliumGridTests exposing (suite)

import Codec
import Expect
import Fuzz exposing (Fuzzer)
import HeliumGrid exposing (HeliumGrid)
import Point
import Shrink
import Test exposing (..)


fuzzer : Fuzzer HeliumGrid
fuzzer =
    -- Shrinking a helium grid in a meaningful way is not easy
    -- For now, we just use fuzzers for the randomness
    Fuzz.custom HeliumGrid.generator Shrink.noShrink


suite : Test
suite =
    describe "HeliumGrid"
        [ describe "codec"
            [ fuzz fuzzer "doesn't modify the values" <|
                \helium ->
                    Codec.encodeToValue HeliumGrid.codec helium
                        |> Codec.decodeValue HeliumGrid.codec
                        |> Expect.equal (Ok helium)
            ]
        , describe "mine"
            [ describe "empty" <|
                let
                    ( grid, amount ) =
                        HeliumGrid.empty
                            |> HeliumGrid.mine (Point.fromXY 5 5)
                in
                [ test "mines nothing on empty grids" <|
                    \_ ->
                        Expect.equal 0 amount
                , test "doesn't change empty grids" <|
                    \_ -> Expect.equal HeliumGrid.empty grid
                ]
            , fuzz fuzzer "mines up to 2500" <|
                \helium ->
                    HeliumGrid.mine (Point.fromXY 5 5) helium
                        |> Tuple.second
                        |> Expect.all [ Expect.atMost 2500, Expect.atLeast 0 ]
            ]
        ]
