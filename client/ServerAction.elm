module ServerAction exposing (..)

import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Extra as Decode
import Point exposing (Point)


type ServerAction
    = FireMissile FireMissileArgs
    | ArmMissile Int Point
    | SelfDestruct SelfDestructArgs
    | Move Int Point
    | Mine Int Point



-- TODO
-- // if the laser was stopped, that robot was shielded. all robots in the laser
-- // path up to `stoppedBy` are destroyed
-- | { type: 'FIRE_LASER', robot: RobotIndex, target: Direction, stoppedBy: RobotIndex? }
-- | { type: 'ARM_LASER', robot: RobotIndex, target: Point }


type alias FireMissileArgs =
    { id : Int
    , target : Point
    , shield : Bool
    }


type alias SelfDestructArgs =
    { id : Int
    , destroyed : List Int
    }


id : ServerAction -> Int
id action =
    case action of
        FireMissile args ->
            args.id

        ArmMissile id_ _ ->
            id_

        SelfDestruct args ->
            args.id

        Move id_ _ ->
            id_

        Mine id_ _ ->
            id_



-- DECODE


decoder : Decoder ServerAction
decoder =
    Decode.oneOf
        [ Decode.when actionTypeDecoder (equals "FIRE_MISSILE") fireMissileDecoder
        , Decode.when actionTypeDecoder (equals "ARM_MISSILE") armMissileDecoder
        , Decode.when actionTypeDecoder (equals "SELF_DESTRUCT") selfDestructDecoder
        , Decode.when actionTypeDecoder (equals "MOVE") moveDecoder
        , Decode.when actionTypeDecoder (equals "MINE") mineDecoder
        ]


actionTypeDecoder : Decoder String
actionTypeDecoder =
    Decode.field "type" Decode.string


fireMissileDecoder : Decoder ServerAction
fireMissileDecoder =
    Decode.succeed FireMissileArgs
        |> Decode.andMap (Decode.field "robot" Decode.int)
        |> Decode.andMap targetDecoder
        |> Decode.andMap (Decode.field "shield" Decode.bool)
        |> Decode.map FireMissile


armMissileDecoder : Decoder ServerAction
armMissileDecoder =
    Decode.succeed ArmMissile
        |> Decode.andMap (Decode.field "robot" Decode.int)
        |> Decode.andMap targetDecoder


selfDestructDecoder : Decoder ServerAction
selfDestructDecoder =
    Decode.succeed SelfDestructArgs
        |> Decode.andMap (Decode.field "robot" Decode.int)
        |> Decode.andMap (Decode.field "destroyed" (Decode.list Decode.int))
        |> Decode.map SelfDestruct


moveDecoder : Decoder ServerAction
moveDecoder =
    Decode.succeed Move
        |> Decode.andMap (Decode.field "robot" Decode.int)
        |> Decode.andMap targetDecoder


mineDecoder : Decoder ServerAction
mineDecoder =
    Decode.succeed Mine
        |> Decode.andMap (Decode.field "robot" Decode.int)
        |> Decode.andMap targetDecoder


targetDecoder : Decoder Point
targetDecoder =
    Decode.field "target" Point.decoder


equals : a -> a -> Bool
equals =
    (==)
