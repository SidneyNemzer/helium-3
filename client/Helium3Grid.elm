module Helium3Grid exposing (decoder, random)

import Json.Decode as Decode exposing (Decoder)
import Matrix exposing (Matrix)
import Point
import Random exposing (Generator)


decoder : Decoder (Matrix Int)
decoder =
    Decode.list
        (Decode.map2 Tuple.pair
            (Decode.index 0 Point.decoder)
            (Decode.index 1 Decode.int)
        )
        |> Decode.map
            (List.foldl
                (\( point, amount ) grid ->
                    Debug.todo "Must be updated; maybe we should transmit a 3 tuple instead of an object"
                 -- Matrix.set point.x point.y amount grid
                )
                Matrix.empty
            )


generator : Generator (Matrix Int)
generator =
    Random.list 20 (Random.list 20 (Random.int 0 2000))
        |> Random.map
            (Matrix.fromList >> Maybe.withDefault Matrix.empty)


random : Random.Seed -> Matrix Int
random seed =
    Random.step generator seed |> Tuple.first
