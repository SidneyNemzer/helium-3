module ClientAction exposing (ClientAction(..), decoder, encoder, id)

import Json.Decode as Decode exposing (Decoder, Error)
import Json.Decode.Extra as Decode
import Json.Encode as Encode exposing (Value)
import Point exposing (Point)


type ClientAction
    = FireMissile Int Point
    | ArmMissile Int Point
    | Shield Int Point
    | SelfDestruct Int
    | Move Int Point
    | Mine Int Point



-- FireLaser Int number
-- ArmLaser Int Point


id : ClientAction -> Int
id action =
    case action of
        FireMissile id_ _ ->
            id_

        ArmMissile id_ _ ->
            id_

        Shield id_ _ ->
            id_

        SelfDestruct id_ ->
            id_

        Move id_ _ ->
            id_

        Mine id_ _ ->
            id_



-- DECODERS


decoder : Decoder ClientAction
decoder =
    actionTypeDecoder
        |> Decode.andThen actionToDecoder


actionToDecoder : String -> Decoder ClientAction
actionToDecoder action =
    case action of
        "FIRE_MISSILE" ->
            robotAndTargetDecoder FireMissile

        "ARM_MISSILE" ->
            robotAndTargetDecoder ArmMissile

        "SHIELD" ->
            robotAndTargetDecoder Shield

        "SELF_DESTRUCT" ->
            Decode.field "robot" Decode.int
                |> Decode.map SelfDestruct

        "MOVE" ->
            robotAndTargetDecoder Move

        "MINE" ->
            robotAndTargetDecoder Mine

        _ ->
            Decode.fail <| "Unknown type:" ++ action


robotAndTargetDecoder : (Int -> Point -> ClientAction) -> Decoder ClientAction
robotAndTargetDecoder action =
    Decode.succeed action
        |> Decode.andMap (Decode.field "robot" Decode.int)
        |> Decode.andMap (Decode.field "target" Point.decoder)


actionTypeDecoder : Decoder String
actionTypeDecoder =
    Decode.field "type" Decode.string



-- ENCODERS


encoder : ClientAction -> Value
encoder action =
    case action of
        FireMissile id_ target ->
            robotAndTargetEncoder "FIRE_MISSILE" id_ target

        ArmMissile id_ target ->
            robotAndTargetEncoder "ARM_MISSILE" id_ target

        Shield id_ target ->
            robotAndTargetEncoder "SHIELD" id_ target

        SelfDestruct id_ ->
            Encode.object
                [ ( "type", Encode.string "SELF_DESTRUCT" )
                , ( "robot", Encode.int id_ )
                ]

        Move id_ target ->
            robotAndTargetEncoder "MOVE" id_ target

        Mine id_ target ->
            robotAndTargetEncoder "MINE" id_ target


robotAndTargetEncoder : String -> Int -> Point -> Value
robotAndTargetEncoder action id_ target =
    Encode.object
        [ ( "type", Encode.string action )
        , ( "robot", Encode.int id_ )
        , ( "target", Point.encoder target )
        ]
