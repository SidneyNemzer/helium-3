module Matrix exposing
    ( Matrix
    , concatHorizontal
    , concatVertical
    , decoder
    , empty
    , filter
    , fromList
    , get
    , getColumn
    , getRow
    , height
    , indexedMap
    , map
    , repeat
    , set
    , toIndexedArray
    , update
    , width
    )

{-| A matrix implemention for Elm. Internally it uses a single, flat array,
instead of a 2D array, for speed.

This module is based on eeue56/elm-flat-matrix, which has not been updated for
0.19.

<https://github.com/eeue56/elm-flat-matrix/blob/4.0.0/src/Matrix.elm>

-}

import Array exposing (Array)
import Json.Decode as Decode exposing (Decoder)


{-| Matrix a has a given size, and data contained within
-}
type alias Matrix a =
    { size : ( Int, Int )
    , data : Array a
    }


{-| Create an empty matrix
-}
empty : Matrix a
empty =
    { size = ( 0, 0 ), data = Array.empty }


{-| Width of a given matrix
-}
width : Matrix a -> Int
width matrix =
    Tuple.first matrix.size


{-| Height of a given matrix
-}
height : Matrix a -> Int
height matrix =
    Tuple.second matrix.size


{-| Create a matrix of a given size `x y` with a default value of `v`
-}
repeat : Int -> Int -> a -> Matrix a
repeat x y v =
    { size = ( x, y )
    , data = Array.repeat (x * y) v
    }


{-| Decodes nested JSON arrays into a matrix
-}
decoder : Decoder a -> Decoder (Matrix a)
decoder valueDecoder =
    Decode.list (Decode.list valueDecoder)
        |> Decode.andThen
            (\list2d ->
                case fromList list2d of
                    Just matrix ->
                        Decode.succeed matrix

                    Nothing ->
                        Decode.fail "Failed to decode matrix because arrays are not consistently sized"
            )


{-| Create a matrix from a list of lists.
If the lists within the list are not consistently sized, return `Nothing`
Otherwise return a matrix with the size as the size of the outer and nested lists.
The outer list represents the y axis and inner lists represent the x axis.
Eg:

    [ [ { x = 0, y = 0 }, { x = 1, y = 0 }, { x = 2, y = 0 } ]
    , [ { x = 0, y = 1 }, { x = 1, y = 1 }, { x = 2, y = 1 } ]
    , [ { x = 0, y = 2 }, { x = 1, y = 2 }, { x = 2, y = 2 } ]
    ]

-}
fromList : List (List a) -> Maybe (Matrix a)
fromList list =
    let
        -- the number of elements in the top level list is taken as height
        height_ =
            List.length list

        -- the number of elements in the first element is taken as the width
        width_ =
            List.length <|
                case List.head list of
                    Just x ->
                        x

                    Nothing ->
                        []

        -- ensure that all "rows" are the same size
        allSame =
            List.isEmpty <| List.filter (\x -> List.length x /= width_) list
    in
    if not allSame then
        Nothing

    else
        Just { size = ( width_, height_ ), data = Array.fromList <| List.concat list }


{-| Get a value from a given `x y` and return `Just v` if it exists
Otherwise `Nothing`
-}
get : Int -> Int -> Matrix a -> Maybe a
get i j matrix =
    let
        pos =
            (j * width matrix) + i
    in
    if (i < width matrix && i > -1) && (j < height matrix && j > -1) then
        Array.get pos matrix.data

    else
        Nothing


{-| Get a row at a given j
-}
getRow : Int -> Matrix a -> Maybe (Array a)
getRow j matrix =
    let
        start =
            j * width matrix

        end =
            start + width matrix
    in
    if end > (width matrix * height matrix) then
        Nothing

    else
        Just <| Array.slice start end matrix.data


{-| Get a column at a given i
-}
getColumn : Int -> Matrix a -> Maybe (Array a)
getColumn i matrix =
    let
        width_ =
            Tuple.first matrix.size

        height_ =
            Tuple.second matrix.size

        indices =
            List.map (\x -> x * width_ + i) (List.range 0 (height_ - 1))
    in
    if i >= width_ then
        Nothing

    else
        Just <|
            Array.fromList <|
                List.foldl
                    (\index ls ->
                        case Array.get index matrix.data of
                            Just v ->
                                ls ++ [ v ]

                            Nothing ->
                                ls
                    )
                    []
                    indices


{-| Append a matrix to another matrix horizontally and return the result. Return Nothing if the heights don't match
-}
concatHorizontal : Matrix a -> Matrix a -> Maybe (Matrix a)
concatHorizontal a b =
    let
        finalWidth =
            Tuple.first a.size + Tuple.first b.size

        insert i xs array =
            Array.append
                (Array.append (Array.slice 0 i array) xs)
                (Array.slice i (Array.length array) array)
    in
    if Tuple.second a.size /= Tuple.second b.size then
        Nothing

    else
        Just <|
            { a
                | size = ( finalWidth, Tuple.second a.size )
                , data =
                    List.foldl
                        (\( i, xs ) acc -> insert (i * finalWidth) xs acc)
                        b.data
                    <|
                        List.foldl
                            (\i ls ->
                                case getRow i a of
                                    Just v ->
                                        ls ++ [ ( i, v ) ]

                                    Nothing ->
                                        ls
                            )
                            []
                            (List.range 0 (Tuple.second a.size - 1))
            }


{-| Append a matrix to another matrix vertically and return the result. Return Nothing if the widths don't match
-}
concatVertical : Matrix a -> Matrix a -> Maybe (Matrix a)
concatVertical a b =
    if Tuple.first a.size /= Tuple.first b.size then
        Nothing

    else
        Just <| { a | size = ( Tuple.first a.size, Tuple.second a.size + Tuple.second b.size ), data = Array.append a.data b.data }


{-| Set a value at a given `i, j` in the matrix and return the new matrix
If the `i, j` is out of bounds then return the unmodified matrix
-}
set : Int -> Int -> a -> Matrix a -> Matrix a
set i j v matrix =
    let
        pos =
            (j * Tuple.first matrix.size) + i
    in
    if (i < width matrix && i > -1) && (j < height matrix && j > -1) then
        { matrix | data = Array.set pos v matrix.data }

    else
        matrix


{-| Update an element at `x, y` with the given update function
If out of bounds, return the matrix unchanged
-}
update : Int -> Int -> (a -> a) -> Matrix a -> Matrix a
update x y f matrix =
    case get x y matrix of
        Nothing ->
            matrix

        Just v ->
            set x y (f v) matrix


{-| Apply a function of every element in the matrix
-}
map : (a -> b) -> Matrix a -> Matrix b
map f matrix =
    { size = matrix.size, data = Array.map f matrix.data }


{-| Apply a function, taking the `x, y` of every element in the matrix
-}
indexedMap : (Int -> Int -> a -> b) -> Matrix a -> Matrix b
indexedMap f matrix =
    let
        f_ i v =
            let
                x =
                    remainderBy (width matrix) i

                y =
                    i // width matrix
            in
            f x y v
    in
    { size = matrix.size
    , data = Array.fromList <| List.indexedMap f_ <| Array.toList matrix.data
    }


{-| Keep only elements that return `True` when passed to the given function f
-}
filter : (a -> Bool) -> Matrix a -> Array a
filter f matrix =
    Array.filter f matrix.data


{-| Convert a matrix to an indexed array
-}
toIndexedArray : Matrix a -> Array ( ( Int, Int ), a )
toIndexedArray matrix =
    (indexedMap (\x y v -> ( ( x, y ), v )) matrix).data