module Page.LobbyClient exposing (..)

import Html exposing (Html, div, h1, p, text)
import Json.Decode as Decode exposing (Error)
import Message exposing (ServerMessageLobby)
import Page exposing (Page)
import Ports


init : () -> ( Model, Cmd Msg )
init () =
    ( { playerCount = 0 }, Cmd.none )


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
        Message.PlayerCount count ->
            ( { model | playerCount = count }, Cmd.none, Nothing )

        Message.GameJoin gameId playerId helium turns ->
            ( { model | playerCount = model.playerCount - 1 }
            , Cmd.none
            , Just (Page.Game { player = playerId, helium = helium, turns = turns })
            )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Message.receiveServerMessageLobby Message DecodeError
        ]


view : Model -> Html Msg
view model =
    div []
        [ h1 [] [ text "Lobby" ]
        , if model.playerCount == 4 then
            p [] [ text "Four players have joined, starting in a moment.." ]

          else
            let
                needed =
                    4 - model.playerCount
            in
            p []
                [ text "Waiting for "
                , text <| String.fromInt needed
                , text " more player"
                , if needed /= 1 then
                    text "s"

                  else
                    text ""
                ]
        ]
