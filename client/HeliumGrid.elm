module HeliumGrid exposing (HeliumGrid, generator, mine)

import Matrix exposing (Matrix)
import Point exposing (Point)
import Random


type alias HeliumGrid =
    Matrix Int


{-| Amount of Helium 3 to distribute on a new grid.
-}
startingHelium : Float
startingHelium =
    40000


{-| Amount of Helium 3 in a large deposit
-}
largeDeposit : Float
largeDeposit =
    startingHelium * 0.2


type Deposit
    = Large Point
    | Small Int Point


{-| Creates a randomized helium 3 grid.

1.  Randomizes number of large and small deposits
2.  Randomizes location of each deposit
3.  Amount of helium in large deposits is constant. The remaining helium is
    distributed to the small deposits.

TODO maybe H3 should be distributed randomly without a "starting helium",
value and

-}
generator : Random.Generator HeliumGrid
generator =
    Random.pair (Random.int 2 3) (Random.int 3 5)
        |> Random.andThen
            (\( largeDepositCount, smallCount ) ->
                let
                    heliumPerSmallDeposit =
                        (startingHelium
                            - (largeDeposit * toFloat largeDepositCount)
                        )
                            / toFloat smallCount
                            |> round
                in
                Random.map2
                    List.append
                    (Random.list largeDepositCount
                        (Point.generator |> Random.map Large)
                    )
                    (Random.list smallCount
                        (Point.generator |> Random.map (Small heliumPerSmallDeposit))
                    )
            )
        |> Random.map (List.foldl distribute empty)


distribute : Deposit -> HeliumGrid -> HeliumGrid
distribute deposit matrix =
    case deposit of
        Large center ->
            let
                amountCenter =
                    largeDeposit * 0.8 |> round

                amountInner =
                    largeDeposit * 0.0575 |> round

                ammountOuter =
                    largeDeposit * 0.02875 |> round
            in
            set center amountCenter matrix
                |> (\updatedMatrix ->
                        List.foldl
                            (\point -> set point amountInner)
                            updatedMatrix
                            (Point.around center 1 False)
                   )
                |> (\updatedMatrix ->
                        List.foldl
                            (\point -> set point ammountOuter)
                            updatedMatrix
                            -- TODO
                            (Point.around center 2 False)
                    -- (Cell.ring5 center)
                   )

        Small helium3 center ->
            let
                amountCenter =
                    toFloat helium3 * 0.15 |> round

                amountOuter =
                    toFloat helium3 * 0.10625 |> round
            in
            set center amountCenter matrix
                |> (\updatedMatrix ->
                        List.foldl
                            (\point -> set point amountOuter)
                            updatedMatrix
                            (Point.around center 1 False)
                   )


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


{-| Simulates mining at the given point, returns the updated grid and amount
mined.
-}
mine : Point -> HeliumGrid -> ( HeliumGrid, Int )
mine location matrix =
    Point.around location 1 True
        |> List.map (\point -> ( point, get point matrix ))
        |> List.foldl
            (\( point, amount ) ( matrix_, total ) ->
                let
                    mined =
                        min 100 amount
                in
                ( set point (amount - mined) matrix_
                , total + mined
                )
            )
            ( matrix, 0 )
