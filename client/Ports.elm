port module Ports exposing (log, setPromptOnNavigation)


port log : String -> Cmd msg


port setPromptOnNavigation : Bool -> Cmd msg
