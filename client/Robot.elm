module Robot exposing
    ( Robot
    , Tool(..)
    , init
    , missileRange
    , moveAndArmWeaponRange
    , moveAndMineRange
    , moveAndShieldRange
    , moveRange
    , moveTo
    , updateAnimation
    , view
    )

import Animation
import Array exposing (Array)
import Ease
import Entity exposing (Entity)
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Extra as Decode
import List.Extra
import Maybe.Extra
import Player exposing (Player(..))
import Point exposing (Point)
import Svg exposing (Svg)
import Svg.Grid
import Svg.Robot
import Time



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
    , animation : Animation.State
    }


width : Int
width =
    140


height : Int
height =
    140


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


init : Point -> Float -> Player -> Robot
init point rotation owner =
    { location = point
    , rotation = rotation
    , target = Nothing
    , tool = Nothing
    , destroyed = False
    , owner = owner
    , animation =
        Entity.toAnimationStyle
            { location = point
            , width = width
            , height = height
            , rotation = rotation
            }
    }


toEntity : Robot -> Entity
toEntity robot =
    { location = robot.location
    , width = width
    , height = height
    , rotation = robot.rotation
    }


easingWithDuration : Float -> Animation.Interpolation
easingWithDuration duration =
    Animation.easing
        { duration = duration
        , ease = Ease.bezier 0.42 0 0.58 1
        }


moveTo : Point -> Robot -> Robot
moveTo target oldRobot =
    let
        rotation =
            Point.angle target oldRobot.location

        movedRobot =
            { oldRobot
                | rotation = rotation
                , location = target
            }

        { x, y, rotate, transformOrigin } =
            Entity.toAnimationProperties (toEntity movedRobot)
    in
    { movedRobot
        | animation =
            Animation.interrupt
                [ Animation.toWith
                    (easingWithDuration 1000)
                    [ rotate ]
                , Animation.wait (Time.millisToPosix 500)
                , Animation.toWith
                    (easingWithDuration 2000)
                    [ x, y, transformOrigin ]
                ]
                movedRobot.animation
    }


updateAnimation : Animation.Msg -> Robot -> Robot
updateAnimation time robot =
    { robot | animation = Animation.update time robot.animation }


view : msg -> Robot -> ( Svg msg, Svg msg )
view onClick robot =
    ( Svg.Robot.use
        (Animation.render robot.animation)
        (Player.color robot.owner)
        onClick
    , Maybe.map (Svg.Grid.dottedLine robot.location) robot.target
        |> Maybe.withDefault (Svg.text "")
    )
