module LobbyServer exposing (..)

import Json.Decode as Decode exposing (Error)
import Message exposing (ClientMessageLobby)
import Players exposing (PlayerIndex(..))
import Ports


type alias Model =
    { playerCount : Int
    }


type Msg
    = Message ClientMessageLobby
    | DecodeError Error


init : () -> ( Model, Cmd Msg )
init _ =
    ( { playerCount = 0 }, Cmd.none )


update : Msg -> Model -> ( Model, Cmd Msg, Bool )
update msg model =
    case msg of
        Message message ->
            onMessage message model

        DecodeError error ->
            ( model, Ports.log (Decode.errorToString error), False )


onMessage : ClientMessageLobby -> Model -> ( Model, Cmd Msg, Bool )
onMessage message model =
    case message of
        Message.Connect ->
            let
                playerCount =
                    model.playerCount + 1
            in
            ( { model | playerCount = playerCount }
            , Message.sendServerMessageLobby (Message.PlayerCount playerCount) []
            , playerCount == 4
            )

        Message.Disconnect ->
            ( { model | playerCount = model.playerCount - 1 }
            , Message.sendServerMessageLobby (Message.PlayerCount (model.playerCount - 1)) []
            , False
            )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Message.receiveClientMessageLobby Message DecodeError
        ]
