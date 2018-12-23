module Helium3Grid exposing (Helium3Grid, decoder)

import Json.Decode as Decode exposing (Decoder)
import Matrix exposing (Matrix)
import Point


type Helium3Grid
    = Helium3Grid (Matrix Int)


decoder : Decoder Helium3Grid
decoder =
    Decode.list
        (Decode.map2 Tuple.pair
            (Decode.index 0 Point.decoder)
            (Decode.index 1 Decode.int)
        )
        |> Decode.map
            (List.foldl
                (\( point, amount ) grid ->
                    Matrix.set point.x point.y amount grid
                )
                Matrix.empty
            )
        |> Decode.map Helium3Grid
