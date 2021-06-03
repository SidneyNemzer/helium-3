module RobotTests exposing (suite)

import Dict exposing (Dict)
import Expect
import Players exposing (PlayerIndex(..))
import Point exposing (Point)
import Robot exposing (Robot)
import Test exposing (..)


initRobots : Dict Int Robot
initRobots =
    Dict.fromList
        [ ( 1, Robot.init 1 (Point.fromXY 2 0) Player1 0 )
        , ( 2, Robot.init 2 (Point.fromXY 2 1) Player1 0 )
        , ( 3, Robot.init 3 (Point.fromXY 2 2) Player1 45 )
        , ( 4, Robot.init 4 (Point.fromXY 0 2) Player1 90 )
        , ( 5, Robot.init 5 (Point.fromXY 1 2) Player1 90 )
        ]


setAction : Int -> (Robot -> Robot) -> Dict Int Robot -> Dict Int Robot
setAction index fn =
    Dict.update index (Maybe.map fn)


origin : Point
origin =
    Point.fromXY 0 0


suite : Test
suite =
    describe "Robot"
        [ describe "unqueueAction"
            [ test "does nothing for destroyed robots" <|
                \_ ->
                    let
                        robot =
                            { id = 1
                            , location = origin
                            , rotation = 0
                            , mined = 0
                            , state = Robot.Destroyed
                            , owner = Player1
                            }
                    in
                    Robot.unqueueAction robot
                        |> Expect.equal robot
            , test "keeps the same tool" <|
                \_ ->
                    let
                        robot =
                            { id = 1
                            , location = origin
                            , rotation = 0
                            , mined = 0
                            , state = Robot.FireMissile origin False
                            , owner = Player1
                            }
                    in
                    Robot.unqueueAction robot
                        |> .state
                        |> Expect.equal (Robot.Idle (Just Robot.ToolMissile))
            , test "sets the robot to idle" <|
                \_ ->
                    let
                        robot =
                            { id = 1
                            , location = origin
                            , rotation = 0
                            , mined = 0
                            , state = Robot.MoveWithTool { pending = Nothing, current = Nothing, target = origin }
                            , owner = Player1
                            }
                    in
                    Robot.unqueueAction robot
                        |> .state
                        |> Expect.equal (Robot.Idle Nothing)
            ]
        ]
