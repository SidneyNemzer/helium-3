module Game.Player exposing (Player, PlayerIndex(..))


type PlayerIndex
    = Player1
    | Player2
    | Player3
    | Player4


type alias Player =
    { money : Int
    , playing : Bool
    }
