module Page.LobbyClient exposing (..)

import Html exposing (Html, div, h1, p, text)
import Html.Attributes exposing (style)
import Json.Decode as Decode exposing (Error)
import Message exposing (ServerMessageLobby)
import Page exposing (Page)
import Ports


init : () -> ( Model, Cmd Msg )
init () =
    ( { playerCount = 1 }, Cmd.none )


type alias Model =
    { playerCount : Int
    }


type Msg
    = Message ServerMessageLobby
    | DecodeError Error


{-| The LobbyClient module is embeded in the Client.elm module. The
`Maybe GameInfo` is returned when the game has started, and the
client switches to the GameClient.
-}
update : Msg -> Model -> ( Model, Cmd Msg, Maybe Page )
update msg model =
    case msg of
        Message message ->
            onMessage message model

        DecodeError error ->
            ( model, Ports.log (Decode.errorToString error), Nothing )


onMessage : ServerMessageLobby -> Model -> ( Model, Cmd Msg, Maybe Page )
onMessage message model =
    case message of
        Message.PlayerCount count playerId ->
            ( { model | playerCount = count }, Cmd.none, Nothing )

        Message.GameJoin gameId playerId helium turns ->
            ( { model | playerCount = model.playerCount - 1 }
            , Cmd.none
            , Just (Page.Game { player = playerId, helium = helium, turns = turns })
            )

        Message.LobbyJoin ->
            ( model, Cmd.none, Nothing )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Message.receiveServerMessageLobby Message DecodeError
        ]


view : Model -> Html Msg
view model =
    let
        needed =
            4 - model.playerCount

        plural =
            if needed /= 1 then
                "s"

            else
                ""

        message =
            if model.playerCount == 4 then
                "Four players have joined, starting in a moment.."

            else
                "Waiting for "
                    ++ String.fromInt needed
                    ++ " more player"
                    ++ plural
    in
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
            [ text message ]
        ]
