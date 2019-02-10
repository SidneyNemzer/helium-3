module Entity exposing
    ( Entity
    , toAnimationProperties
    , toAnimationStyle
    , toAttributes
    )

import Animation as A
import Html.Attributes as HA
import Point exposing (Point)
import Svg exposing (Attribute, Svg)
import Svg.Attributes as SA


type alias Entity =
    { location : Point
    , rotation : Float
    , width : Int
    , height : Int
    }


type alias Properties =
    { x : A.Property
    , y : A.Property
    , rotate : A.Property
    , transformOrigin : A.Property
    }


toAnimationStyle : Entity -> A.State
toAnimationStyle entity =
    let
        { x, y, rotate, transformOrigin } =
            toAnimationProperties entity
    in
    A.style [ x, y, rotate, transformOrigin ]


toAnimationProperties : Entity -> Properties
toAnimationProperties entity =
    let
        -- Calculate the x,y that will center the entity in the cell
        ( x, y ) =
            Point.offset
                ((Point.cellSide - entity.width) // 2)
                ((Point.cellSide - entity.height) // 2)
                entity.location

        ( cX, cY ) =
            Point.center entity.location
    in
    { x = A.x (toFloat x)
    , y = A.y (toFloat y)
    , rotate = A.rotate (A.deg entity.rotation)
    , transformOrigin =
        A.transformOrigin
            (A.px (toFloat cX))
            (A.px (toFloat cY))
            (A.px 0)
    }


toAttributes : Entity -> List (Attribute msg)
toAttributes entity =
    let
        -- Calculate the x,y that will center the entity in the cell
        ( x, y ) =
            Point.offset
                ((Point.cellSide - entity.width) // 2)
                ((Point.cellSide - entity.height) // 2)
                entity.location

        ( cX, cY ) =
            Point.center entity.location
    in
    [ SA.x (String.fromInt x)
    , SA.y (String.fromInt y)
    , SA.transform <|
        "rotate("
            ++ String.fromFloat entity.rotation
            ++ " "
            ++ String.fromInt cX
            ++ " "
            ++ String.fromInt cY
            ++ ")"
    ]



-- render :
--     Entity
--     -> Maybe msg
--     -> (List (Svg.Attribute msg) -> List (Svg msg) -> Svg msg)
--     -> List (Svg.Attribute msg)
--     -> List (Svg msg)
--     -> Svg msg
-- render entity maybeOnClick element attributes children =
--     let
--         topLeft =
--             entity.location
--                 |> Point.mapBoth (\a -> a - entity.width // 2)
--     in
--     element
--         [ SA.x (String.fromInt topLeft.x)
--         , SA.y (String.fromInt topLeft.y)
--         , SA.width (String.fromInt entity.width)
--         , SA.height (String.fromInt entity.height)
--         ]
--         []
