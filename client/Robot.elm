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


type Action
    = FireMissile Point
    | FireLaser Float
    | ArmMissile Point
    | ArmLaser Point
    | Shield Point
    | Mine Point
    | Kamikaze
    | Move Point


type Tool
    = ToolShield
    | ToolLaser
    | ToolMissile


type alias Robot =
    { location : Point
    , rotation : Float
    , action : Maybe Action
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
                            Decode.succeed ToolMissile

                        "LASER" ->
                            Decode.succeed ToolLaser

                        "SHIELD" ->
                            Decode.succeed ToolShield

                        _ ->
                            Decode.fail ("Unknown tool: " ++ tool)
                )
        )


init : Point -> Float -> Player -> Robot
init point rotation owner =
    { location = point
    , rotation = rotation
    , action = Nothing
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


easingWithDuration : Float -> Animation.Interpolation
easingWithDuration duration =
    Animation.easing
        { duration = duration
        , ease = Ease.bezier 0.42 0 0.58 1
        }


moveTo : Point -> Robot -> Robot
moveTo target robot =
    let
        rotation =
            Point.angle target robot.location

        { x, y, rotate, transformOrigin } =
            Entity.toAnimationProperties
                { location = target
                , rotation = rotation
                , width = width
                , height = height
                }
    in
    { robot
        | location = target
        , rotation = rotation
        , animation =
            Animation.interrupt
                [ Animation.toWith (easingWithDuration 1000) [ rotate ]
                , Animation.wait (Time.millisToPosix 500)
                , Animation.toWith
                    (easingWithDuration 2000)
                    [ x, y, transformOrigin ]
                ]
                robot.animation
    }


updateAnimation : Animation.Msg -> Robot -> Robot
updateAnimation time robot =
    { robot | animation = Animation.update time robot.animation }


moveTarget : Robot -> Maybe Point
moveTarget robot =
    case robot.action of
        Just (FireMissile _) ->
            Nothing

        Just (FireLaser _) ->
            Nothing

        Just (ArmMissile point) ->
            Just point

        Just (ArmLaser point) ->
            Just point

        Just (Shield point) ->
            Just point

        Just (Mine point) ->
            Just point

        Just Kamikaze ->
            Nothing

        Just (Move point) ->
            Just point

        Nothing ->
            Nothing


view : Maybe msg -> Robot -> ( Svg msg, Svg msg )
view onClick robot =
    ( Svg.Robot.use
        (Animation.render robot.animation)
        (Player.color robot.owner)
        onClick
    , moveTarget robot
        |> Maybe.map (Svg.Grid.dottedLine robot.location)
        |> Maybe.withDefault (Svg.text "")
    )
