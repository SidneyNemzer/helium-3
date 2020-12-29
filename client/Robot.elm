module Robot exposing (..)

import Players exposing (PlayerIndex)
import Point exposing (Point)


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


init : Int -> Point -> PlayerIndex -> Robot
init id point owner =
    { id = id
    , location = point
    , rotation = 0
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
        Idle currentTool ->
            False

        Destroyed ->
            False

        _ ->
            True



-- phase : State -> Int
-- phase state =
--     case state of
--         MoveWithTool _ ->
--             2
--         SelfDestruct _ ->
--             1
--         FireMissile _ _ ->
--             1
--         FireLaser _ _ ->
--             1
--         Idle currentTool ->
--             0
--         Destroyed ->
--             0


getTarget : Robot -> Maybe Point
getTarget robot =
    case robot.state of
        MoveWithTool { target } ->
            Just target

        SelfDestruct _ ->
            Nothing

        FireMissile target _ ->
            Just target

        FireLaser target _ ->
            Nothing

        Mine { target } ->
            Just target

        Idle currentTool ->
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
