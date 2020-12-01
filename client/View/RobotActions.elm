module View.RobotActions exposing (..)

import Html exposing (Html, div, text)
import Html.Attributes exposing (disabled, style)
import Html.Events


type alias OnClick msg =
    { cancel : msg
    , move : msg
    , armMissile : msg
    , fireMissile : Maybe msg
    }


view : OnClick msg -> Html msg
view onClick =
    div
        [ style "position" "absolute"
        , style "top" "0"
        , style "bottom" "0"
        , style "right" "0"
        , style "left" "0"
        , style "display" "flex"
        , style "align-items" "center"
        , style "justify-content" "center"

        -- TODO eats events from buttons
        -- , Html.Events.onClick onClick.cancel
        ]
        [ div
            [ style "background" "gray"
            , style "border-radius" "3px"
            , style "padding" "10px"
            ]
            [ button "Move" (Just onClick.move)
            , button "Arm Missile" (Just onClick.armMissile)
            , button "Fire Missile" onClick.fireMissile
            , button "Cancel" (Just onClick.cancel)
            ]
        ]


button : String -> Maybe msg -> Html msg
button label onClick =
    let
        attributes =
            case onClick of
                Just msg ->
                    [ Html.Events.onClick msg ]

                Nothing ->
                    [ disabled True ]
    in
    div []
        [ Html.button attributes
            [ text label
            ]
        ]
