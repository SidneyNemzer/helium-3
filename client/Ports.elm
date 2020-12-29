port module Ports exposing (onActionReceived)

import Json.Decode as Decode exposing (Error, Value)
import ServerAction exposing (ServerAction)


onActionReceived : (Result Error (List ServerAction) -> msg) -> Sub msg
onActionReceived msg =
    onActionReceived_
        (Decode.decodeValue (Decode.list ServerAction.decoder)
            >> msg
        )


port onActionReceived_ : (Value -> msg) -> Sub msg
