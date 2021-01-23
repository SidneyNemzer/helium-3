module Matrix exposing
    ( Matrix
    , codec
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
    , toList
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
import Codec exposing (Codec)


{-| Matrix a has a given size, and data contained within
-}
type alias Matrix a =
    { width : Int
    , height : Int
    , data : Array a
    }


{-| Create an empty matrix
-}
empty : Matrix a
empty =
    { width = 0, height = 0, data = Array.empty }


{-| Width of a given matrix
-}
width : Matrix a -> Int
width =
    .width


{-| Height of a given matrix
-}
height : Matrix a -> Int
height =
    .height


{-| Create a matrix of a given size `w h` with a default value of `v`
-}
repeat : Int -> Int -> a -> Matrix a
repeat w h v =
    { width = w
    , height = h
    , data = Array.repeat (w * h) v
    }


codec : Codec a -> Codec (Matrix a)
codec inner =
    Codec.object Matrix
        |> Codec.field "width" .width Codec.int
        |> Codec.field "height" .height Codec.int
        |> Codec.field "data" .data (Codec.array inner)
        |> Codec.buildObject


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
        Just { width = width_, height = height_, data = Array.fromList <| List.concat list }


{-| Converts a matrix to a 2D list. Opposite of `fromList`.
The default value is used in place of empty cells.
-}
toList : a -> Matrix a -> List (List a)
toList default matrix =
    List.range 0 matrix.height
        |> List.map
            (\y ->
                List.range 0 matrix.width
                    |> List.map
                        (\x ->
                            get x y matrix |> Maybe.withDefault default
                        )
            )


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
            width matrix

        height_ =
            height matrix

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


{-| Set a value at a given `i, j` in the matrix and return the new matrix
If the `i, j` is out of bounds then return the unmodified matrix
-}
set : Int -> Int -> a -> Matrix a -> Matrix a
set i j v matrix =
    let
        pos =
            (j * width matrix) + i
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
    { width = matrix.width, height = matrix.height, data = Array.map f matrix.data }


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
    { width = matrix.width
    , height = matrix.height
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
