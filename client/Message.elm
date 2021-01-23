port module Message exposing
    ( ClientMessage(..)
    , ServerMessage(..)
    , ServerMessageLobby(..)
    , receiveClientMessage
    , receiveServerMessage
    , receiveServerMessageLobby
    , sendClientMessage
    , sendServerMessage
    , sendServerMessageLobby
    )

import ClientAction exposing (ClientAction)
import Codec
import HeliumGrid exposing (HeliumGrid)
import Json.Decode as Decode exposing (Decoder, Error)
import Json.Decode.Extra as Decode
import Json.Encode as Encode exposing (Value)
import Players exposing (PlayerIndex)
import ServerAction exposing (ServerAction)


type ClientMessage
    = Queue ClientAction


{-| When a client connects to the server, it is placed in the lobby. The server
waits for four players to join the lobby, then starts a new game.
-}
type ServerMessageLobby
    = PlayerCount Int -- count
    | GameJoin String PlayerIndex -- game ID


{-| While in a game:

  - The server will broadcast events such as player turns or countdowns
  - After the game starts, clients can queue actions. Actions may not be queued while a player is moving.
  - Clients are automatically removed from the game after it ends

-}
type ServerMessage
    = Start Int HeliumGrid -- Allows user to queue actions
    | Countdown PlayerIndex -- Countdown until turn ends and player will move
    | Actions PlayerIndex (List ServerAction)


sendServerMessage : List PlayerIndex -> ServerMessage -> Cmd msg
sendServerMessage receivers message =
    messageOut ( serverEncoder message, List.map Players.toNumber receivers )


sendServerMessageLobby : ServerMessageLobby -> List PlayerIndex -> Cmd msg
sendServerMessageLobby message receivers =
    messageOut ( lobbyEncoder message, List.map Players.toNumber receivers )


receiveServerMessage : (ServerMessage -> msg) -> (Error -> msg) -> Sub msg
receiveServerMessage =
    receive serverDecoder


receiveServerMessageLobby : (ServerMessageLobby -> msg) -> (Error -> msg) -> Sub msg
receiveServerMessageLobby =
    receive lobbyDecoder


sendClientMessage : ClientMessage -> Cmd msg
sendClientMessage message =
    messageOut ( clientEncoder message, [] )


receiveClientMessage : (ClientMessage -> msg) -> (Error -> msg) -> Sub msg
receiveClientMessage =
    receive clientDecoder


receive : Decoder a -> (a -> msg) -> (Error -> msg) -> Sub msg
receive decoder msg errorMsg =
    messageIn
        (Decode.decodeValue decoder
            >> splitResult msg errorMsg
        )


splitResult : (a -> b) -> (x -> b) -> Result x a -> b
splitResult a x result =
    case result of
        Ok value ->
            a value

        Err err ->
            x err


port messageOut : ( Value, List Int ) -> Cmd msg


port messageIn : (Value -> msg) -> Sub msg



-- DECODERS


clientDecoder : Decoder ClientMessage
clientDecoder =
    typeDecoder
        |> Decode.andThen clientDecoderWithType


clientDecoderWithType : String -> Decoder ClientMessage
clientDecoderWithType messageType =
    case messageType of
        "queue" ->
            Decode.succeed Queue
                |> Decode.andMap (Decode.field "action" ClientAction.decoder)

        _ ->
            Decode.fail <| "Unknown type:" ++ messageType


lobbyDecoder : Decoder ServerMessageLobby
lobbyDecoder =
    typeDecoder
        |> Decode.andThen lobbyDecoderWithType


lobbyDecoderWithType : String -> Decoder ServerMessageLobby
lobbyDecoderWithType messageType =
    case messageType of
        "player-count" ->
            Decode.succeed PlayerCount
                |> Decode.andMap (Decode.field "count" Decode.int)

        "game-join" ->
            Decode.succeed GameJoin
                |> Decode.andMap (Decode.field "id" Decode.string)
                |> Decode.andMap (Decode.field "position" Players.indexDecoder)

        _ ->
            Decode.fail <| "Unknown type:" ++ messageType


serverDecoder : Decoder ServerMessage
serverDecoder =
    typeDecoder
        |> Decode.andThen serverDecoderWithType


serverDecoderWithType : String -> Decoder ServerMessage
serverDecoderWithType messageType =
    case messageType of
        "game-start" ->
            Decode.succeed Start
                |> Decode.andMap (Decode.field "end" Decode.int)
                |> Decode.andMap (Decode.field "helium" (Codec.decoder HeliumGrid.codec))

        "action-countdown" ->
            Decode.succeed Countdown
                |> Decode.andMap (Decode.field "player" Players.indexDecoder)

        "action" ->
            Decode.succeed Actions
                |> Decode.andMap (Decode.field "player" Players.indexDecoder)
                |> Decode.andMap (Decode.field "actions" (Decode.list ServerAction.decoder))

        _ ->
            Decode.fail <| "Unknown type:" ++ messageType


typeDecoder : Decoder String
typeDecoder =
    Decode.field "type" Decode.string



-- ENCODERS


clientEncoder : ClientMessage -> Value
clientEncoder message =
    case message of
        Queue action ->
            Encode.object
                [ ( "type", Encode.string "queue" )
                , ( "action", ClientAction.encoder action )
                ]


lobbyEncoder : ServerMessageLobby -> Value
lobbyEncoder message =
    case message of
        PlayerCount count ->
            Encode.object
                [ ( "type", Encode.string "player-count" )
                , ( "count", Encode.int count )
                ]

        GameJoin id index ->
            Encode.object
                [ ( "type", Encode.string "game-join" )
                , ( "id", Encode.string id )
                , ( "position", Players.indexEncoder index )
                ]


serverEncoder : ServerMessage -> Value
serverEncoder message =
    case message of
        Start endTime helium ->
            Encode.object
                [ ( "type", Encode.string "game-start" )
                , ( "end", Encode.int endTime )
                , ( "helium", Codec.encoder HeliumGrid.codec helium )
                ]

        Countdown player ->
            Encode.object
                [ ( "type", Encode.string "action-countdown" )
                , ( "player", Players.indexEncoder player )
                ]

        Actions player actions ->
            Encode.object
                [ ( "type", Encode.string "action" )
                , ( "player", Players.indexEncoder player )
                , ( "actions", Encode.list ServerAction.encoder actions )
                ]
