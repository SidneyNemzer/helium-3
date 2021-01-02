port module Ports exposing (endTurn, log, onEndTurn)

import Json.Decode as Decode exposing (Error, Value)


port log : String -> Cmd msg


endTurn : Cmd msg
endTurn =
    endTurn_ ()


port endTurn_ : () -> Cmd msg


onEndTurn : msg -> Sub msg
onEndTurn msg =
    onEndTurn_ (\_ -> msg)


port onEndTurn_ : (() -> msg) -> Sub msg
