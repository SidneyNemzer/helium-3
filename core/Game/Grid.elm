module Game.Grid exposing (empty, generator)

import Game.Cell as Cell exposing (Cell)
import Game.Constants as Constants
import Matrix exposing (Matrix)
import Random


type Deposit
    = Large Cell
    | Small Int Cell


empty : Matrix Int
empty =
    Matrix.repeat Constants.gridSide Constants.gridSide 0


setMatrixCell : Cell -> a -> Matrix a -> Matrix a
setMatrixCell cell value matrix =
    let
        ( x, y ) =
            Cell.toXY cell
    in
    Matrix.set x y value matrix


distribute : Deposit -> Matrix Int -> Matrix Int
distribute deposit matrix =
    case deposit of
        Large center ->
            let
                amountCenter =
                    Constants.helium3InLargeDeposit
                        * Constants.helium3LargeDepositCenter
                        |> round

                amountInner =
                    Constants.helium3InLargeDeposit
                        * Constants.helium3InLargeDepositInnerRing
                        |> round

                ammountOuter =
                    Constants.helium3InLargeDeposit
                        * Constants.helium3InLargeDepositOuterRing
                        |> round
            in
            setMatrixCell center amountCenter matrix
                |> (\updatedMatrix ->
                        List.foldl
                            (\cell -> setMatrixCell cell amountInner)
                            updatedMatrix
                            (Cell.ring3 center)
                   )
                |> (\updatedMatrix ->
                        List.foldl
                            (\cell -> setMatrixCell cell ammountOuter)
                            updatedMatrix
                            (Cell.ring5 center)
                   )

        Small helium3 center ->
            let
                amountCenter =
                    toFloat helium3
                        * Constants.helium3SmallDepositCenter
                        |> round

                amountOuter =
                    toFloat helium3
                        * Constants.helium3SmallDepositOuterRing
                        |> round
            in
            setMatrixCell center amountCenter matrix
                |> (\updatedMatrix ->
                        List.foldl
                            (\cell -> setMatrixCell cell amountOuter)
                            updatedMatrix
                            (Cell.ring3 center)
                   )


generator : Random.Generator (Matrix Int)
generator =
    Random.pair (Random.int 2 3) (Random.int 3 5)
        |> Random.andThen
            (\( largeCount, smallCount ) ->
                let
                    helium3ForSmallDeposits =
                        Constants.startingHelium3
                            - (Constants.helium3InLargeDeposit * toFloat largeCount)

                    helium3PerSmallDeposit =
                        helium3ForSmallDeposits
                            / toFloat smallCount
                            |> round
                in
                Random.map2
                    List.append
                    (Random.list largeCount
                        (Cell.generator Constants.gridSide Constants.gridSide
                            |> Random.map Large
                        )
                    )
                    (Random.list smallCount
                        (Cell.generator Constants.gridSide Constants.gridSide
                            |> Random.map (Small helium3PerSmallDeposit)
                        )
                    )
            )
        |> Random.map (List.foldl distribute empty)
