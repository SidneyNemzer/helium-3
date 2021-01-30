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
        , describe "generator"
            [ fuzz fuzzer "always generates some helium" <|
                \helium ->
                    HeliumGrid.total helium
                        |> Expect.atLeast 1
            ]
        , test "depositSmall" <|
            \_ ->
                HeliumGrid.depositSmall (Point.fromXY 5 5) HeliumGrid.empty
                    |> HeliumGrid.total
                    |> Expect.equal 3550
        , test "depositLarge" <|
            \_ ->
                HeliumGrid.depositLarge (Point.fromXY 5 5) HeliumGrid.empty
                    |> HeliumGrid.total
                    |> Expect.equal 12800
        , test "deposits stack" <|
            \_ ->
                HeliumGrid.depositSmall (Point.fromXY 5 5) HeliumGrid.empty
                    |> HeliumGrid.depositLarge (Point.fromXY 5 5)
                    |> HeliumGrid.total
                    |> Expect.equal (3550 + 12800)
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
            , fuzz fuzzer "amount mined is removed from the grid" <|
                \helium ->
                    let
                        ( grid, amount ) =
                            HeliumGrid.mine (Point.fromXY 5 5) helium
                    in
                    Expect.equal
                        (HeliumGrid.total helium - amount)
                        (HeliumGrid.total grid)
            ]
        , describe "total"
            [ test "empty HeliumGrids have no helium" <|
                \_ ->
                    HeliumGrid.empty
                        |> HeliumGrid.total
                        |> Expect.equal 0
            ]
        , describe "drop"
            [ test "drops all given helium" <|
                \_ ->
                    HeliumGrid.drop (Point.fromXY 5 5) 3550 HeliumGrid.empty
                        |> HeliumGrid.total
                        |> Expect.equal 3550
            ]
        ]
