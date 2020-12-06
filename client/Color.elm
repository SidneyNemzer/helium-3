module Color exposing
    ( backgroundGray
    , blue
    , blueShade
    , cyan
    , green
    , progressBarGray
    , purple
    , red
    )


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


backgroundGray : String
backgroundGray =
    "#E0E0E0"


progressBarGray : String
progressBarGray =
    "#B9B9B9"



-- fromPlayer : PlayerIndex -> String
-- fromPlayer player =
--     case player of
--         Player1 ->
--             green
--         Player2 ->
--             purple
--         Player3 ->
--             cyan
--         Player4 ->
--             red


blueShade : Int -> String
blueShade lightness =
    "hsl(201, 100%, " ++ String.fromInt lightness ++ "%)"
