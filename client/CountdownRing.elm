module CountdownRing exposing
    ( State
    , init
    , side
    , startFromTopLeft
    , subscription
    , update
    , view
    )

import Animation
import Svg exposing (Svg)
import Svg.Attributes as SA
import Svg.Grid exposing (gridSideSvg)
import Time


type alias State =
    { top : Animation.State
    , right : Animation.State
    , bottom : Animation.State
    , left : Animation.State
    }


side : Int
side =
    20


sideDurationSeconds : Int
sideDurationSeconds =
    1500


shapeProperties : Int -> Int -> Int -> Int -> List Animation.Property
shapeProperties x y width height =
    [ Animation.x (toFloat x)
    , Animation.y (toFloat y)
    , Animation.attr "width" (toFloat width) ""
    , Animation.attr "height" (toFloat height) ""
    ]


initSide : Int -> Int -> Int -> Int -> Animation.State
initSide x y width height =
    Animation.style (shapeProperties x y width height)


init : State
init =
    { top = initSide side 0 (gridSideSvg + side * 2) side
    , right = initSide (gridSideSvg + side) side side (gridSideSvg + side)
    , bottom = initSide 0 (gridSideSvg + side) (gridSideSvg + side) side
    , left = initSide 0 0 side (gridSideSvg + side)
    }


update : Animation.Msg -> State -> State
update time state =
    { top = Animation.update time state.top
    , right = Animation.update time state.right
    , bottom = Animation.update time state.bottom
    , left = Animation.update time state.left
    }


subscription : (Animation.Msg -> msg) -> State -> Sub msg
subscription msg state =
    Animation.subscription
        msg
        [ state.top
        , state.right
        , state.bottom
        , state.left
        ]


linearWithDuration : Int -> Animation.Interpolation
linearWithDuration duration =
    Animation.easing { duration = toFloat duration, ease = identity }


topSlideLeft : Animation.Step
topSlideLeft =
    Animation.toWith
        (linearWithDuration sideDurationSeconds)
        (shapeProperties (gridSideSvg + side * 2) 0 0 side)


rightSlideDown : Animation.Step
rightSlideDown =
    Animation.toWith
        (linearWithDuration sideDurationSeconds)
        (shapeProperties (gridSideSvg + side) (gridSideSvg + side * 2) side 0)


bottomSlideRight : Animation.Step
bottomSlideRight =
    Animation.toWith
        (linearWithDuration sideDurationSeconds)
        (shapeProperties 0 (gridSideSvg + side) 0 side)


leftSlideUp : Animation.Step
leftSlideUp =
    Animation.toWith
        (linearWithDuration sideDurationSeconds)
        (shapeProperties 0 0 side 0)


startFromTopLeft : State -> State
startFromTopLeft state =
    { top =
        Animation.interrupt [ topSlideLeft ] state.top
    , right =
        Animation.interrupt
            [ Animation.wait (Time.millisToPosix sideDurationSeconds)
            , rightSlideDown
            ]
            state.right
    , bottom =
        Animation.interrupt
            [ Animation.wait (Time.millisToPosix (sideDurationSeconds * 2))
            , bottomSlideRight
            ]
            state.bottom
    , left =
        Animation.interrupt
            [ Animation.wait (Time.millisToPosix (sideDurationSeconds * 3))
            , leftSlideUp
            ]
            state.left
    }



-- startFromTopRight
-- startFromBottomLeft
-- startFromBottomRight


viewSide : String -> Animation.State -> Svg msg
viewSide color state =
    Svg.rect ([ SA.fill color ] ++ Animation.render state) []


view : String -> State -> List (Svg msg)
view color state =
    [ viewSide color state.top
    , viewSide color state.right
    , viewSide color state.bottom
    , viewSide color state.left
    ]
