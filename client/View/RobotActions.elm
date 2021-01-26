module View.RobotActions exposing (..)

import Html exposing (Html, div, text)
import Html.Attributes exposing (style)
import Html.Events
import Json.Decode as Decode


type alias OnClick msg =
    { noop : msg
    , cancel : msg
    , move : msg
    , shield : msg
    , mine : msg
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
        , Html.Events.onClick onClick.cancel
        ]
        [ div
            [ -- Prevent clicking the dialog box from triggering the `cancel`
              stopPropagationOn "click" onClick.noop
            , style "background" "#3A3A3A"
            , style "border-radius" "5px"
            , style "width" "150px"
            , style "text-align" "center"
            ]
            [ title
            , button "ARM MISSILE" onClick.armMissile
            , buttonMaybe "FIRE MISSILE" onClick.fireMissile
            , button "SHIELD" onClick.shield
            , button "MINE" onClick.mine
            , button "MOVE" onClick.move
            , separator
            , button "CANCEL" onClick.cancel
            ]
        ]


title : Html msg
title =
    div
        [ style "background" "#666666"
        , style "color" "white"
        , style "padding" "4px 0"
        , style "font-size" "12px"
        ]
        [ text "ACTIONS" ]


separator : Html msg
separator =
    div
        [ style "margin" "0 6px"
        , style "background" "#666666"
        , style "height" "4px"
        ]
        []


buttonMaybe : String -> Maybe msg -> Html msg
buttonMaybe label maybeOnClick =
    case maybeOnClick of
        Just onClick ->
            button label onClick

        Nothing ->
            text ""


button : String -> msg -> Html msg
button label onClick =
    div []
        [ Html.button
            [ stopPropagationOn "click" onClick
            , style "width" "100%"
            , style "background" "#3A3A3A"
            , style "border" "none"
            , style "color" "white"
            , style "font-size" "16px"
            , style "padding" "6px 0"
            , style "cursor" "pointer"
            ]
            [ text label ]
        ]


stopPropagationOn : String -> msg -> Html.Attribute msg
stopPropagationOn event msg =
    Html.Events.stopPropagationOn event <|
        Decode.succeed ( msg, True )
