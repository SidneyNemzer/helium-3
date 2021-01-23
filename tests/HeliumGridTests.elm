module HeliumGridTests exposing (suite)

import Codec
import Expect
import Fuzz exposing (Fuzzer)
import HeliumGrid exposing (HeliumGrid)
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
        ]
