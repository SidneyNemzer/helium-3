module Game.Player exposing (Player, PlayerIndex(..), pushAction, toString)


type PlayerIndex
    = Player1
    | Player2
    | Player3
    | Player4


type alias Player =
    { money : Int
    , playing : Bool
    , moving : List Int
    }


pushAction : Int -> Player -> ( Player, Maybe Int )
pushAction newIndex oldPlayer =
    let
        player =
            { oldPlayer | moving = newIndex :: oldPlayer.moving }
    in
    case player.moving of
        [ index0, index1, index2 ] ->
            ( { player | moving = [ index0, index1 ] }, Just index2 )

        _ ->
            ( player, Nothing )


toString : PlayerIndex -> String
toString playerIndex =
    case playerIndex of
        Player1 ->
            "Player 1"

        Player2 ->
            "Player 2"

        Player3 ->
            "Player 3"

        Player4 ->
            "Player 4"
