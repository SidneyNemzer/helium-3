module Player exposing
    ( Player(..)
    , color
    , decodeTurn
    , nextTurn
    , toString
    , viewColoredName
    )

import Color
import Html exposing (Html, span, text)
import Html.Attributes as HA
import Json.Decode as Decode exposing (Decoder)
import Maybe.Extra
import Svg exposing (Svg)


type Player
    = Player1
    | Player2
    | Player3
    | Player4



-- DECODERS


decodeTurn : Decoder Player
decodeTurn =
    Decode.int
        |> Decode.andThen
            (\turn ->
                case turn of
                    0 ->
                        Decode.succeed Player1

                    1 ->
                        Decode.succeed Player2

                    2 ->
                        Decode.succeed Player3

                    3 ->
                        Decode.succeed Player4

                    _ ->
                        Decode.fail
                            ("Unknown player turn:" ++ String.fromInt turn)
            )



-- UTILITIES


color : Player -> String
color player =
    case player of
        Player1 ->
            Color.green

        Player2 ->
            Color.purple

        Player3 ->
            Color.cyan

        Player4 ->
            Color.red


nextTurn : Player -> Player
nextTurn player =
    case player of
        Player1 ->
            Player2

        Player2 ->
            Player3

        Player3 ->
            Player4

        Player4 ->
            Player1


toString : Player -> String
toString player =
    case player of
        Player1 ->
            "Player 1"

        Player2 ->
            "Player 2"

        Player3 ->
            "Player 3"

        Player4 ->
            "Player 4"


viewColoredName : Player -> Html msg
viewColoredName player =
    span [ HA.style "color" (color player) ]
        [ text (toString player) ]
