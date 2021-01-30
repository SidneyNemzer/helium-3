module HeliumGrid exposing
    ( HeliumGrid
    , codec
    , depositLarge
    , depositSmall
    , drop
    , empty
    , generator
    , mine
    , total
    )

import Array
import Codec exposing (Codec)
import Matrix exposing (Matrix)
import Point exposing (Point)
import Random


type alias HeliumGrid =
    Matrix Int


lowDensity : Int
lowDensity =
    350


mediumDensity : Int
mediumDensity =
    750


highDensity : Int
highDensity =
    1200


{-| Creates a randomized grid of helium. See docs/spec.md.
-}
generator : Random.Generator HeliumGrid
generator =
    Random.pair (Random.int 2 3) (Random.int 3 5)
        |> Random.andThen
            (\( largeDepositCount, smallCount ) ->
                Random.list
                    (largeDepositCount + smallCount)
                    validPointGenerator
                    |> Random.map
                        (\points ->
                            let
                                largDepositPoints =
                                    List.take largeDepositCount points

                                smallDepositPoints =
                                    List.drop largeDepositCount points
                            in
                            List.foldl depositLarge empty largDepositPoints
                                |> (\helium -> List.foldl depositSmall helium smallDepositPoints)
                        )
            )


{-| In order to avoid generating points too close to the spawns, this generator
discards points until it generates one sufficiently far from each spawn.
-}
validPointGenerator : Random.Generator Point
validPointGenerator =
    Point.generator
        |> Random.andThen
            (\point ->
                if List.member point invalidDepositPoints then
                    validPointGenerator

                else
                    Random.constant point
            )


{-| The center of a deposit shouldn't generate at any of these points.
-}
invalidDepositPoints : List Point
invalidDepositPoints =
    List.concat
        [ Point.area (Point.fromXY 0 0) 5 True
        , Point.area (Point.fromXY 0 19) 5 True
        , Point.area (Point.fromXY 19 0) 5 True
        , Point.area (Point.fromXY 19 19) 5 True
        ]


empty : HeliumGrid
empty =
    Matrix.repeat 20 20 0


set : Point -> Int -> HeliumGrid -> HeliumGrid
set point value =
    let
        ( x, y ) =
            Point.toXY point
    in
    Matrix.set x y value


get : Point -> HeliumGrid -> Int
get point matrix =
    let
        ( x, y ) =
            Point.toXY point
    in
    Matrix.get x y matrix |> Maybe.withDefault 0


add : Point -> Int -> HeliumGrid -> HeliumGrid
add point amount grid =
    get point grid |> (+) amount |> (\value -> set point value grid)


{-| Simulates mining at the given point, returns the updated grid and amount
mined.
-}
mine : Point -> HeliumGrid -> ( HeliumGrid, Int )
mine location matrix =
    Point.area location 1 False
        |> List.map (\point -> ( point, min 250 <| get point matrix ))
        |> (::) ( location, min 500 <| get location matrix )
        |> List.foldl
            (\( point, minedFromPoint ) ( matrix_, totalMined ) ->
                ( add point -minedFromPoint matrix_
                , totalMined + minedFromPoint
                )
            )
            ( matrix, 0 )


total : HeliumGrid -> Int
total =
    .data >> Array.foldl (+) 0


drop : Point -> Int -> HeliumGrid -> HeliumGrid
drop center amount =
    let
        -- These formulas are based on "Helium Distribution" in doc/specs.md
        inner =
            amount * 75 // 355

        outer =
            (amount - inner) // 8
    in
    add center inner
        >> addRing center 1 outer


depositSmall : Point -> HeliumGrid -> HeliumGrid
depositSmall center =
    add center mediumDensity
        >> addRing center 1 lowDensity


depositLarge : Point -> HeliumGrid -> HeliumGrid
depositLarge center =
    add center highDensity
        >> addRing center 1 mediumDensity
        >> addRing center 2 lowDensity


{-| Adds helium to each cell in a ring centered on the given point. Each cell
receives the specified amount, it is not split between them.
-}
addRing : Point -> Int -> Int -> HeliumGrid -> HeliumGrid
addRing center radius amount helium =
    Point.ring center radius
        |> List.foldl (\point -> add point amount) helium


codec : Codec HeliumGrid
codec =
    Matrix.codec Codec.int
