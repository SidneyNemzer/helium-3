module RobotTests exposing (suite)

import Dict exposing (Dict)
import Expect
import Players exposing (PlayerIndex(..))
import Point
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


suite : Test
suite =
    describe "Robot"
        [ describe "queue"
            [ test "does nothing for empty queues" <|
                \_ ->
                    let
                        robots =
                            initRobots
                                |> setAction 1 (Robot.queueMine (Point.fromXY 2 0))
                                |> setAction 2 (Robot.queueMine (Point.fromXY 2 0))
                    in
                    Robot.queue [] robots
                        |> Expect.equal ( [], robots )
            , test "does nothing when one robot is queued" <|
                \_ ->
                    let
                        robots =
                            initRobots
                                |> setAction 1 (Robot.queueMine (Point.fromXY 2 0))
                                |> setAction 2 (Robot.queueMine (Point.fromXY 2 0))
                    in
                    Robot.queue [ 1 ] robots
                        |> Expect.equal ( [ 1 ], robots )
            , test "does nothing when two robots are queued" <|
                \_ ->
                    let
                        robots =
                            initRobots
                                |> setAction 1 (Robot.queueMine (Point.fromXY 2 0))
                                |> setAction 2 (Robot.queueMine (Point.fromXY 2 0))
                    in
                    Robot.queue [ 1, 2 ] robots
                        |> Expect.equal ( [ 1, 2 ], robots )
            , test "resets last robot when three are queued" <|
                \_ ->
                    let
                        expected =
                            initRobots
                                |> setAction 1 (Robot.queueMine (Point.fromXY 2 0))
                                |> setAction 2 (Robot.queueMine (Point.fromXY 2 0))

                        robots =
                            expected
                                |> setAction 3 (Robot.queueMine (Point.fromXY 2 0))
                    in
                    Robot.queue [ 1, 2, 3 ] robots
                        |> Expect.equal ( [ 1, 2 ], expected )
            , test "resets all but first two robots when more than three are queued" <|
                \_ ->
                    let
                        expected =
                            initRobots
                                |> setAction 1 (Robot.queueMine (Point.fromXY 2 0))
                                |> setAction 2 (Robot.queueMine (Point.fromXY 2 0))

                        robots =
                            expected
                                |> setAction 3 (Robot.queueMine (Point.fromXY 2 0))
                                |> setAction 4 (Robot.queueMine (Point.fromXY 2 0))
                    in
                    Robot.queue [ 1, 2, 3, 4 ] robots
                        |> Expect.equal ( [ 1, 2 ], expected )
            ]
        ]
