module Effect exposing (..)

import Players exposing (PlayerIndex)
import Point exposing (Point)
import Robot exposing (Robot, State(..), Tool(..))
import ServerAction exposing (ServerAction)


type alias Timeline =
    List Effect


type Effect
    = SetLocation Int Point
    | SetRotation Int Float
    | SetMinerActive Int
    | MineAt Int Point
    | SetState Int State
    | Impact Point Bool
    | SetTurn PlayerIndex
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


fireMissile : Robot -> Point -> Bool -> Timeline
fireMissile robot target forceShield =
    batch
        [ rotate robot target
        , [ SetState robot.id (FireMissile target True)
          , Wait 1000
          ]
        , setIdle robot Nothing
        , [ Impact target forceShield ]
        ]


moveWithTool : Robot -> Point -> Maybe Tool -> Timeline
moveWithTool robot target tool =
    if tool == Just (ToolShield False) then
        batch
            [ setIdle robot Nothing
            , move robot target
            , setIdle robot (Just (ToolShield False))
            ]

    else
        batch
            [ setIdle robot tool
            , if tool /= Nothing then
                [ Wait 1000 ]

              else
                none
            , move robot target
            ]


mine : Robot -> Point -> Timeline
mine robot target =
    batch
        [ move robot target
        , [ SetMinerActive robot.id
          , MineAt robot.id target
          , Wait 1000
          ]
        , setIdle robot Nothing
        ]


fromRobot : Robot -> Timeline
fromRobot robot =
    case robot.state of
        MoveWithTool { target, pending } ->
            moveWithTool robot target pending

        Idle currentTool ->
            none

        Mine { target } ->
            mine robot target

        SelfDestruct currentTool ->
            Debug.todo "SelfDestruct"

        FireMissile target _ ->
            fireMissile robot target False

        FireLaser _ _ ->
            Debug.todo "FireLaser"

        Destroyed ->
            none


fromServer : ServerAction -> Robot -> Timeline
fromServer action robot =
    case action of
        ServerAction.FireMissile args ->
            fireMissile robot args.target args.shield

        ServerAction.ArmMissile _ target ->
            moveWithTool robot target (Just ToolMissile)

        ServerAction.SelfDestruct args ->
            Debug.todo "SelfDestruct"

        ServerAction.Move _ target ->
            moveWithTool robot target Nothing

        ServerAction.Shield _ target ->
            moveWithTool robot target (Just (ToolShield False))

        ServerAction.Mine _ target ->
            mine robot target
