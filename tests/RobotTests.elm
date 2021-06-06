module RobotTests exposing (suite)

import Dict exposing (Dict)
import Expect
import Players exposing (PlayerIndex(..))
import Point exposing (Point)
import Robot exposing (Robot)
import Test exposing (..)


origin : Point
origin =
    Point.fromXY 0 0


suite : Test
suite =
    describe "Robot"
        [ describe "unqueue"
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
                    Robot.unqueue robot
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
                    Robot.unqueue robot
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
                    Robot.unqueue robot
                        |> .state
                        |> Expect.equal (Robot.Idle Nothing)
            ]
        ]
