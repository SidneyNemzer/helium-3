module Color exposing
    ( blue
    , cyan
    , fromPlayer
    , green
    , purple
    , red
    )

import Game.Player as Player exposing (PlayerIndex(..))


green : String
green =
    "#45D042"


purple : String
purple =
    "#5642D0"


red : String
red =
    "#D04242"


cyan : String
cyan =
    "#42D0C7"


blue : String
blue =
    "#487CFF"


fromPlayer : PlayerIndex -> String
fromPlayer player =
    case player of
        Player1 ->
            green

        Player2 ->
            purple

        Player3 ->
            cyan

        Player4 ->
            red
