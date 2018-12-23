module Robot exposing
    ( Robot
    , Tool(..)
    , decoder
    , missileRange
    , moveAndArmWeaponRange
    , moveAndMineRange
    , moveAndShieldRange
    , moveRange
    , view
    )

import Json.Decode as Decode exposing (Decoder)
import Maybe.Extra
import Player exposing (Player)
import Point exposing (Point)
import Svg exposing (Svg)
import Svg.Grid
import Svg.Robot



-- type Action
--     = FireMissile
--     | FireLaser
--     | ArmMissile
--     | ArmLaser
--     | Shield
--     | Mine
--     | Kamikaze
--     | Move


type Tool
    = Shield
    | Laser
    | Missile


type alias Robot =
    { location : Point
    , rotation : Float
    , target : Maybe Point
    , tool : Maybe Tool
    , destroyed : Bool
    , owner : Player
    }


startingRotations : List Float
startingRotations =
    [ 0, 0, 45, 90, 90, 180, 180, 134, 90, 90, 180, 180, 225, 270, 270, 270, 270, 315, 0, 0 ]


moveRange : Int
moveRange =
    4


moveAndShieldRange : Int
moveAndShieldRange =
    3


moveAndArmWeaponRange : Int
moveAndArmWeaponRange =
    2


missileRange : Int
missileRange =
    5


moveAndMineRange : Int
moveAndMineRange =
    3


targetDecoder : Decoder (Maybe Point)
targetDecoder =
    Decode.maybe (Decode.field "target" Point.decoder)


toolDecoder : Decoder (Maybe Tool)
toolDecoder =
    Decode.nullable
        (Decode.string
            |> Decode.andThen
                (\tool ->
                    case tool of
                        "MISSILE" ->
                            Decode.succeed Missile

                        "LASER" ->
                            Decode.succeed Laser

                        "SHIELD" ->
                            Decode.succeed Shield

                        _ ->
                            Decode.fail ("Unknown tool: " ++ tool)
                )
        )


decoder : Player -> Float -> Decoder Robot
decoder owner rotation =
    Decode.map6 Robot
        (Decode.field "location" Point.decoder)
        (Decode.succeed rotation)
        (Decode.field "action" targetDecoder)
        (Decode.field "tool" toolDecoder)
        (Decode.field "destroyed" Decode.bool)
        (Decode.succeed owner)



-- faceTarget : Robot -> Robot
-- faceTarget robot =
--     case target robot of
--         Just cell ->
--             { robot | rotation = Position.angle robot.position cell }
--
--         Nothing ->
--             robot


view : msg -> Robot -> List (Svg msg)
view onClick robot =
    let
        { x, y } =
            Svg.Grid.cellTopLeft robot.location
    in
    Maybe.Extra.values
        [ Just <|
            Svg.Robot.use
                { x = x
                , y = y
                , rotation = robot.rotation
                , color = Player.color robot.owner
                , onClick = onClick
                }
        , Maybe.map (Svg.Grid.dottedLine robot.location) robot.target
        ]
