module GameTests exposing (suite)

import ClientAction
import Dict exposing (Dict)
import Expect
import Game exposing (Game)
import Players exposing (PlayerIndex(..))
import Point exposing (Point)
import Robot exposing (Robot)
import Test exposing (..)


suite : Test
suite =
    describe "Game"
        [ describe "queue"
            [ test "adds action to the correct robot" <|
                \_ ->
                    let
                        game : Game {}
                        game =
                            { robots = initRobots
                            , players = Players.init
                            }

                        actual =
                            Game.queue (ClientAction.Move 1 origin) game
                                |> Game.queue (ClientAction.Mine 2 origin)
                    in
                    Expect.all
                        [ .players >> .player1 >> .queued >> Expect.equal [ 2, 1 ]
                        , expectRobotStateEquals 1 moveNoTool
                        , expectRobotStateEquals 2 mineNoTool
                        ]
                        actual
            , test "does not duplicate queued robots" <|
                \_ ->
                    let
                        game : Game {}
                        game =
                            { robots = initRobots
                            , players = Players.init
                            }

                        actual =
                            Game.queue (ClientAction.Move 1 origin) game
                                |> Game.queue (ClientAction.Mine 2 origin)
                                |> Game.queue (ClientAction.ArmMissile 1 origin)
                    in
                    Expect.all
                        [ .players >> .player1 >> .queued >> Expect.equal [ 1, 2 ]
                        , expectRobotStateEquals 1 armMissile
                        , expectRobotStateEquals 2 mineNoTool
                        ]
                        actual
            , test "only allows two queued robots" <|
                \_ ->
                    let
                        game : Game {}
                        game =
                            { robots = initRobots
                            , players = Players.init
                            }

                        actual =
                            Game.queue (ClientAction.Move 1 origin) game
                                |> Game.queue (ClientAction.Mine 2 origin)
                                |> Game.queue (ClientAction.ArmMissile 3 origin)
                    in
                    Expect.all
                        [ .players >> .player1 >> .queued >> Expect.equal [ 3, 2 ]
                        , expectRobotStateEquals 1 (Robot.Idle Nothing)
                        , expectRobotStateEquals 2 mineNoTool
                        , expectRobotStateEquals 3 armMissile
                        ]
                        actual
            ]
        ]


expectRobotStateEquals : Int -> Robot.State -> Game model -> Expect.Expectation
expectRobotStateEquals id state =
    .robots >> Dict.get id >> Maybe.map .state >> Expect.equal (Just state)


moveNoTool : Robot.State
moveNoTool =
    Robot.MoveWithTool { pending = Nothing, current = Nothing, target = origin }


armMissile : Robot.State
armMissile =
    Robot.MoveWithTool { pending = Just Robot.ToolMissile, current = Nothing, target = origin }


mineNoTool : Robot.State
mineNoTool =
    Robot.Mine { target = origin, tool = Nothing, active = False }


initRobots : Dict Int Robot
initRobots =
    Dict.fromList
        [ ( 1, Robot.init 1 (Point.fromXY 2 0) Player1 0 )
        , ( 2, Robot.init 2 (Point.fromXY 2 1) Player1 0 )
        , ( 3, Robot.init 3 (Point.fromXY 2 2) Player1 45 )
        , ( 4, Robot.init 4 (Point.fromXY 0 2) Player1 90 )
        , ( 5, Robot.init 5 (Point.fromXY 1 2) Player1 90 )
        ]


origin : Point
origin =
    Point.fromXY 0 0
