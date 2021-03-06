module Robot exposing (..)

import ClientAction exposing (ClientAction)
import Dict exposing (Dict)
import Players exposing (PlayerIndex(..))
import Point exposing (Point)
import ServerAction exposing (ServerAction)


{-| A robot can 'hold' one of the following items.

The Bool indicates the tool has been activated. Otherwise, tools render in a
resting state.

Shield: Bright (after impact)

-}
type Tool
    = ToolShield Bool
    | ToolLaser
    | ToolMissile


type State
    = Idle (Maybe Tool)
    | MoveWithTool { pending : Maybe Tool, current : Maybe Tool, target : Point }
    | SelfDestruct (Maybe Tool)
    | FireMissile Point Bool -- target, fired
    | FireLaser Float Bool -- target, fired
    | Mine { target : Point, tool : Maybe Tool, active : Bool }
    | Destroyed


type alias Robot =
    { id : Int
    , location : Point
    , rotation : Float -- degrees
    , mined : Int
    , state : State
    , owner : PlayerIndex
    }


domId : Int -> String
domId id =
    "robot-" ++ String.fromInt id


initAll : Dict Int Robot
initAll =
    Dict.fromList
        [ ( 1, init 1 (Point.fromXY 2 0) Player1 0 )
        , ( 2, init 2 (Point.fromXY 2 1) Player1 0 )
        , ( 3, init 3 (Point.fromXY 2 2) Player1 45 )
        , ( 4, init 4 (Point.fromXY 0 2) Player1 90 )
        , ( 5, init 5 (Point.fromXY 1 2) Player1 90 )
        , ( 6, init 6 (Point.fromXY 17 0) Player2 180 )
        , ( 7, init 7 (Point.fromXY 17 1) Player2 180 )
        , ( 8, init 8 (Point.fromXY 17 2) Player2 135 )
        , ( 9, init 9 (Point.fromXY 18 2) Player2 90 )
        , ( 10, init 10 (Point.fromXY 19 2) Player2 90 )
        , ( 11, init 11 (Point.fromXY 17 19) Player3 180 )
        , ( 12, init 12 (Point.fromXY 17 18) Player3 180 )
        , ( 13, init 13 (Point.fromXY 17 17) Player3 225 )
        , ( 14, init 14 (Point.fromXY 18 17) Player3 270 )
        , ( 15, init 15 (Point.fromXY 19 17) Player3 270 )
        , ( 16, init 16 (Point.fromXY 0 17) Player4 270 )
        , ( 17, init 17 (Point.fromXY 1 17) Player4 270 )
        , ( 18, init 18 (Point.fromXY 2 17) Player4 315 )
        , ( 19, init 19 (Point.fromXY 2 18) Player4 0 )
        , ( 20, init 20 (Point.fromXY 2 19) Player4 0 )
        ]


init : Int -> Point -> PlayerIndex -> Float -> Robot
init id point owner rotation =
    { id = id
    , location = point
    , rotation = rotation
    , mined = 0
    , state = Idle Nothing
    , owner = owner
    }


move : Maybe Tool -> Point -> Robot -> Robot
move tool point robot =
    { robot
        | state =
            case robot.state of
                MoveWithTool { current } ->
                    MoveWithTool { pending = tool, current = current, target = point }

                Idle currentTool ->
                    MoveWithTool { pending = tool, current = currentTool, target = point }

                SelfDestruct currentTool ->
                    MoveWithTool { pending = tool, current = currentTool, target = point }

                FireMissile _ _ ->
                    MoveWithTool { pending = tool, current = Just ToolMissile, target = point }

                FireLaser _ _ ->
                    MoveWithTool { pending = tool, current = Just ToolLaser, target = point }

                Mine state ->
                    MoveWithTool { pending = tool, current = state.tool, target = point }

                Destroyed ->
                    robot.state
    }


queueMine : Point -> Robot -> Robot
queueMine point robot =
    { robot
        | state =
            case robot.state of
                MoveWithTool { current } ->
                    Mine { tool = current, target = point, active = False }

                Idle currentTool ->
                    Mine { tool = currentTool, target = point, active = False }

                SelfDestruct currentTool ->
                    Mine { tool = currentTool, target = point, active = False }

                FireMissile _ _ ->
                    Mine { tool = Just ToolMissile, target = point, active = False }

                FireLaser _ _ ->
                    Mine { tool = Just ToolLaser, target = point, active = False }

                Mine state ->
                    Mine { tool = state.tool, target = point, active = False }

                Destroyed ->
                    robot.state
    }


hasAction : Robot -> Bool
hasAction robot =
    case robot.state of
        Idle _ ->
            False

        Destroyed ->
            False

        _ ->
            True


getTarget : Robot -> Maybe Point
getTarget robot =
    case robot.state of
        MoveWithTool { target } ->
            Just target

        SelfDestruct _ ->
            Nothing

        FireMissile target _ ->
            Just target

        FireLaser _ _ ->
            Nothing

        Mine { target } ->
            Just target

        Idle _ ->
            Nothing

        Destroyed ->
            Nothing


getTool : Robot -> Maybe Tool
getTool robot =
    case robot.state of
        MoveWithTool { current } ->
            current

        Idle current ->
            current

        SelfDestruct current ->
            current

        FireMissile _ _ ->
            Just ToolMissile

        FireLaser _ _ ->
            Just ToolLaser

        Mine { tool } ->
            tool

        Destroyed ->
            Nothing


impact : Bool -> Robot -> Robot
impact forceShield robot =
    { robot
        | state =
            case robot.state of
                MoveWithTool ({ current } as state) ->
                    if current == Just (ToolShield False) || forceShield then
                        MoveWithTool { state | current = Just (ToolShield True) }

                    else
                        Destroyed

                Idle current ->
                    if current == Just (ToolShield False) || forceShield then
                        Idle (Just (ToolShield True))

                    else
                        Destroyed

                SelfDestruct current ->
                    if current == Just (ToolShield False) || forceShield then
                        SelfDestruct (Just (ToolShield True))

                    else
                        Destroyed

                FireMissile _ _ ->
                    Destroyed

                FireLaser _ _ ->
                    Destroyed

                Mine ({ tool } as state) ->
                    if tool == Just (ToolShield False) || forceShield then
                        Mine { state | tool = Just (ToolShield True) }

                    else
                        Destroyed

                Destroyed ->
                    Destroyed
    }


{-| Removes the shield if it has absorbed an impact. Does not modify state of
other tools, or shields that have not been impacted.
-}
removeShield : Robot -> Robot
removeShield robot =
    { robot
        | state =
            case robot.state of
                MoveWithTool state ->
                    if state.current == Just (ToolShield True) then
                        MoveWithTool { state | current = Nothing }

                    else
                        robot.state

                Idle current ->
                    if current == Just (ToolShield True) then
                        Idle Nothing

                    else
                        robot.state

                SelfDestruct current ->
                    if current == Just (ToolShield True) then
                        SelfDestruct Nothing

                    else
                        robot.state

                FireMissile _ _ ->
                    robot.state

                FireLaser _ _ ->
                    robot.state

                Mine state ->
                    if state.tool == Just (ToolShield True) then
                        Mine { state | tool = Nothing }

                    else
                        robot.state

                Destroyed ->
                    Destroyed
    }


{-| Robot will preform the given action on the next turn.

Note that ID is ignored. Maybe ID should not be part of the `ClientAction` type?

-}
queueAction : ClientAction -> Robot -> Robot
queueAction action =
    case action of
        ClientAction.FireMissile _ target ->
            setState (FireMissile target False)

        ClientAction.ArmMissile _ target ->
            move (Just ToolMissile) target

        ClientAction.Shield _ target ->
            move (Just (ToolShield False)) target

        ClientAction.SelfDestruct _ ->
            Debug.todo "self destruct"

        ClientAction.Move _ target ->
            move Nothing target

        ClientAction.Mine _ target ->
            queueMine target


toServerAction : Dict Int Robot -> Robot -> Maybe ServerAction
toServerAction robots robot =
    case robot.state of
        Idle _ ->
            Nothing

        MoveWithTool { pending, target } ->
            case pending of
                Just ToolLaser ->
                    Debug.todo "laser"

                Just ToolMissile ->
                    Just (ServerAction.ArmMissile robot.id target)

                Just (ToolShield _) ->
                    Just (ServerAction.Shield robot.id target)

                Nothing ->
                    Just (ServerAction.Move robot.id target)

        SelfDestruct _ ->
            Debug.todo "self destruct"

        FireMissile target _ ->
            Just <|
                ServerAction.FireMissile
                    { id = robot.id
                    , target = target
                    , shield =
                        getRobotAt target robots
                            |> Maybe.map (getTool >> (==) (Just (ToolShield False)))
                            |> Maybe.withDefault False
                    }

        FireLaser _ _ ->
            Debug.todo "laser"

        Mine { target } ->
            Just (ServerAction.Mine robot.id target)

        Destroyed ->
            Nothing


getRobotAt : Point -> Dict Int Robot -> Maybe Robot
getRobotAt point =
    Dict.filter (\_ robot -> robot.location == point)
        >> Dict.toList
        >> List.head
        >> Maybe.map Tuple.second



-- SETTERS


setLocation : Point -> Robot -> Robot
setLocation point robot =
    { robot | location = point }


setRotation : Float -> Robot -> Robot
setRotation rotation robot =
    { robot | rotation = rotation }


setState : State -> Robot -> Robot
setState state robot =
    { robot | state = state }


setMinerActive : Robot -> Robot
setMinerActive robot =
    { robot
        | state =
            case robot.state of
                Mine state ->
                    Mine { state | active = True }

                _ ->
                    Mine { target = robot.location, tool = Nothing, active = True }
    }
