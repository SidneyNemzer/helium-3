module PointTests exposing (suite)

import Expect
import Fuzz exposing (Fuzzer)
import Point exposing (Point)
import Random
import Shrink
import Test exposing (..)


{-| Fuzzes points between the given points (passed as tuples for simplicity).
-}
fuzzer : ( Int, Int ) -> ( Int, Int ) -> Fuzzer Point
fuzzer ( x1, y1 ) ( x2, y2 ) =
    Fuzz.custom
        (Random.map2 Point.fromXY (Random.int x1 x2) (Random.int y1 y2))
        (\point ->
            let
                ( x, y ) =
                    Point.toXY point
            in
            Shrink.map Point.fromXY (Shrink.atLeastInt x1 x)
                |> Shrink.andMap (Shrink.atLeastInt y1 y)
        )


{-| Fuzzes points on the board
-}
boardFuzzer : Fuzzer Point
boardFuzzer =
    fuzzer ( 0, 0 ) ( 19, 19 )


suite : Test
suite =
    describe "Point"
        [ describe "ring"
            [ test "radius 1" <|
                \_ ->
                    Point.ring (Point.fromXY 5 5) 1
                        |> Expect.equalLists [ Point.fromXY 4 4, Point.fromXY 4 5, Point.fromXY 4 6, Point.fromXY 5 4, Point.fromXY 5 6, Point.fromXY 6 4, Point.fromXY 6 5, Point.fromXY 6 6 ]
            , fuzz2 (fuzzer ( 3, 3 ) ( 16, 16 )) (Fuzz.intRange 1 3) "returns the correct number of elements" <|
                \point radius ->
                    let
                        outerArea =
                            power2 (radius * 2 + 1)

                        innerArea =
                            power2 ((radius - 1) * 2 + 1)
                    in
                    Point.ring point radius
                        |> List.length
                        |> Expect.equal (outerArea - innerArea)
            ]
        , describe "area"
            [ test "radius 1" <|
                \_ ->
                    Point.area (Point.fromXY 5 5) 1 True
                        |> Expect.equalLists [ Point.fromXY 4 4, Point.fromXY 4 5, Point.fromXY 4 6, Point.fromXY 5 4, Point.fromXY 5 5, Point.fromXY 5 6, Point.fromXY 6 4, Point.fromXY 6 5, Point.fromXY 6 6 ]
            , fuzz2 (fuzzer ( 3, 3 ) ( 16, 16 )) (Fuzz.intRange 1 3) "returns the correct number of elements" <|
                \point radius ->
                    let
                        area =
                            power2 (radius * 2 + 1)
                    in
                    Point.area point radius True
                        |> List.length
                        |> Expect.equal area
            ]
        , describe "distance"
            [ fuzz2 boardFuzzer boardFuzzer "cannot be negative" <|
                \p1 p2 ->
                    Point.distance p1 p2
                        |> Expect.atLeast 0
            , test "static" <|
                \_ ->
                    Point.distance (Point.fromXY 3 4) (Point.fromXY 10 12)
                        |> Expect.equal 8
            ]
        ]


power2 : number -> number
power2 a =
    a * a
