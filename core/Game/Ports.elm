port module Game.Ports exposing (action, actionCountdown, onQueueAction, start)

import Game.Cell as Cell exposing (Cell)
import Game.Robot as Robot exposing (ServerAction(..))
import Json.Decode as Decode exposing (Value)


port start : () -> Cmd msg


port actionCountdown : () -> Cmd msg


action : ServerAction -> Int -> Cmd msg
action serverAction index =
    Robot.serverActionEncoder serverAction index |> portAction


port portAction : Value -> Cmd msg


port onQueueArmMissile : (( ( Int, Int ), Int ) -> msg) -> Sub msg


port onQueueFireLaser : (( ( Int, Int ), Int ) -> msg) -> Sub msg


port onQueueArmLaser : (( ( Int, Int ), Int ) -> msg) -> Sub msg


port onQueueShield : (( ( Int, Int ), Int ) -> msg) -> Sub msg


port onQueueKamakazie : (Int -> msg) -> Sub msg


port onQueueMove : (( ( Int, Int ), Int ) -> msg) -> Sub msg


port onQueueMine : (( ( Int, Int ), Int ) -> msg) -> Sub msg


portToMsg : (Cell -> Int -> a) -> ( ( Int, Int ), Int ) -> a
portToMsg fn ( cellTuple, index ) =
    fn (Cell.fromTuple cellTuple) index


onQueueAction : (Robot.Action -> Int -> msg) -> Sub msg
onQueueAction msg =
    Sub.batch
        [ onQueueArmMissile (portToMsg (Robot.ArmMissile >> msg))
        , onQueueFireLaser
            (\( direction, index ) ->
                msg (Robot.FireLaser (Cell.directionFromTuple direction)) index
            )
        , onQueueArmLaser (portToMsg (Robot.ArmLaser >> msg))
        , onQueueShield (portToMsg (Robot.Shield >> msg))
        , onQueueKamakazie (msg Robot.Kamikaze)
        , onQueueMove (portToMsg (Robot.Move >> msg))
        , onQueueMine (portToMsg (Robot.Mine >> msg))
        ]
