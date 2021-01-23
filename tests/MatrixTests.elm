module MatrixTests exposing (suite)

import Codec
import Expect
import Matrix
import Test exposing (..)


suite : Test
suite =
    describe "Matrix"
        [ describe "Matrix.empty"
            [ test "is 0 x 0" <|
                \_ ->
                    let
                        empty =
                            Matrix.empty
                    in
                    Expect.all
                        [ Expect.equal (Matrix.width empty)
                        , Expect.equal (Matrix.height empty)
                        ]
                        0
            ]
        , describe "Matrix.codec"
            [ test "works on empty matricies" <|
                \_ ->
                    Codec.encodeToValue (Matrix.codec Codec.int) Matrix.empty
                        |> Codec.decodeValue (Matrix.codec Codec.int)
                        |> Expect.equal (Ok Matrix.empty)
            , test "works on filled matricies" <|
                \_ ->
                    let
                        maybeMatrix =
                            Matrix.fromList <|
                                [ [ 1, 2, 3 ]
                                , [ 4, 5, 6 ]
                                ]
                    in
                    case maybeMatrix of
                        Just matrix ->
                            Codec.encodeToValue (Matrix.codec Codec.int) matrix
                                |> Codec.decodeValue (Matrix.codec Codec.int)
                                |> Expect.equal (Ok matrix)

                        Nothing ->
                            Expect.fail "matrix should have been created"
            ]
        ]
