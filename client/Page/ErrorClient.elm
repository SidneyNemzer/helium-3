module Page.ErrorClient exposing (..)

import Html exposing (Html, div, h1, p, text)
import Html.Attributes exposing (style)


type alias Model =
    { error : String
    }


init : String -> ( Model, Cmd msg )
init error =
    ( { error = error }, Cmd.none )


view : Model -> Html msg
view model =
    div [ style "margin-top" "10%" ]
        [ h1
            [ style "text-align" "center"
            , style "font-size" "35px"
            ]
            [ text "HELIUM 3" ]
        , p
            [ style "text-align" "center"
            , style "margin-top" "20px"
            , style "font-size" "45px"
            ]
            [ text "A connection error occured" ]
        , p
            [ style "text-align" "center"
            , style "margin-top" "20px"
            , style "font-size" "25px"
            ]
            [ text "Try refreshing the page" ]
        ]
