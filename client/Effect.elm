module Effect exposing (..)

import Point exposing (Point)
import Robot exposing (Robot, State(..), Tool)


type alias Timeline =
    List Effect


type Effect
    = SetLocation Int Point
    | SetRotation Int Float
    | SetMinerActive Int
    | MineAt Int Point
    | SetState Int State
    | Impact Point
    | Wait Int



-- | Parallel (Dict Int Animation)
-- | SetScore PlayerId Int
-- | DropHelium Cell Int
-- | CreateExplotion Int
-- | DeleteExplotion Int


move : Robot -> Point -> Timeline
move robot target =
    batch
        [ rotate robot target
        , location robot target
        ]


rotate : Robot -> Point -> Timeline
rotate robot target =
    let
        angle =
            Point.angle robot.location target
    in
    if robot.location /= target && angle /= robot.rotation then
        [ SetRotation robot.id angle
        , Wait 1000
        ]

    else
        none


location : Robot -> Point -> Timeline
location robot target =
    if target /= robot.location then
        [ SetLocation robot.id target
        , Wait 1000
        ]

    else
        none


setIdle : Robot -> Maybe Tool -> Timeline
setIdle robot tool =
    [ SetState robot.id (Idle tool) ]


none : Timeline
none =
    []


batch : List Timeline -> Timeline
batch =
    List.concat


fromRobot : Robot -> Timeline
fromRobot robot =
    case robot.state of
        MoveWithTool { target, pending } ->
            batch
                [ setIdle robot pending
                , if pending /= Nothing then
                    [ Wait 1000 ]

                  else
                    none
                , move robot target
                ]

        Idle currentTool ->
            none

        Mine { target, tool } ->
            move robot target
                ++ [ SetMinerActive robot.id
                   , MineAt robot.id target
                   , Wait 1000
                   ]
                ++ setIdle robot Nothing

        SelfDestruct currentTool ->
            Debug.todo "SelfDestruct"

        FireMissile target _ ->
            rotate robot target
                ++ [ SetState robot.id (FireMissile target True)
                   , Wait 1000
                   , Impact target
                   ]
                ++ setIdle robot Nothing

        FireLaser _ _ ->
            Debug.todo "FireLaser"

        Destroyed ->
            none
