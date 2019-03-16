module Game exposing (Model, init)

import Array exposing (Array)
import Dict exposing (Dict)
import Game.Cell as Cell exposing (Cell, Direction)
import Game.Constants as Constants
import Game.Grid as Grid
import Game.Player as Player exposing (Player, PlayerIndex(..))
import Game.Robot as Robot exposing (Robot)
import Matrix exposing (Matrix)
import Platform
import Process
import Random
import Task


type alias Model =
    { -- Who will move next
      turn : PlayerIndex

    -- When the game ends
    , gameTime : Int
    , robots : Array Robot

    -- Keep track of how much money players have, and who is currenly playing
    , player1 : Player
    , player2 : Player
    , player3 : Player
    , player4 : Player

    -- The Helium 3 distributed on the board
    , helium3 : Matrix Int
    }


init : () -> Model
init () =
    { turn = Player1
    , gameTime = Constants.secondsGameTime * 1000
    , robots =
        [ Robot.init (Cell.fromXY 2 0) Player1
        , Robot.init (Cell.fromXY 2 1) Player1
        , Robot.init (Cell.fromXY 2 2) Player1
        , Robot.init (Cell.fromXY 0 2) Player1
        , Robot.init (Cell.fromXY 1 2) Player1
        , Robot.init (Cell.fromXY 17 0) Player2
        , Robot.init (Cell.fromXY 17 1) Player2
        , Robot.init (Cell.fromXY 17 2) Player2
        , Robot.init (Cell.fromXY 18 2) Player2
        , Robot.init (Cell.fromXY 19 2) Player2
        , Robot.init (Cell.fromXY 17 19) Player3
        , Robot.init (Cell.fromXY 17 18) Player3
        , Robot.init (Cell.fromXY 17 17) Player3
        , Robot.init (Cell.fromXY 18 17) Player3
        , Robot.init (Cell.fromXY 19 17) Player3
        , Robot.init (Cell.fromXY 0 17) Player4
        , Robot.init (Cell.fromXY 1 17) Player4
        , Robot.init (Cell.fromXY 2 17) Player4
        , Robot.init (Cell.fromXY 2 18) Player4
        , Robot.init (Cell.fromXY 2 19) Player4
        ]
            |> Array.fromList
    , player1 = { money = 0, playing = True }
    , player2 = { money = 0, playing = True }
    , player3 = { money = 0, playing = True }
    , player4 = { money = 0, playing = True }
    , helium3 =
        Random.initialSeed 0
            |> Random.step Grid.generator
            |> Tuple.first
    }


robotAt : Model -> Cell -> Maybe ( Int, Robot )
robotAt model cell =
    Array.toIndexedList model.robots
        |> List.filter (Tuple.second >> .location >> (==) cell)
        |> List.head


mineHelium3 : Matrix Int -> Cell -> ( Matrix Int, Int )
mineHelium3 matrix cell =
    let
        ( x, y ) =
            Cell.toXY cell

        cellHelium3 =
            Matrix.get x y matrix
                |> Maybe.withDefault 0

        minedHelium3 =
            min Constants.maxMinedHelium3 cellHelium3

        remainingHelium3 =
            max 0 (cellHelium3 - minedHelium3)
    in
    ( Matrix.set x y remainingHelium3 matrix
    , minedHelium3
    )


addMoney : PlayerIndex -> Int -> Model -> Model
addMoney playerIndex money model =
    case playerIndex of
        Player1 ->
            let
                player =
                    model.player1
            in
            { model | player1 = { player | money = player.money + money } }

        Player2 ->
            let
                player =
                    model.player2
            in
            { model | player2 = { player | money = player.money + money } }

        Player3 ->
            let
                player =
                    model.player3
            in
            { model | player3 = { player | money = player.money + money } }

        Player4 ->
            let
                player =
                    model.player4
            in
            { model | player4 = { player | money = player.money + money } }


performRobotMove :
    ( Int, Robot )
    -> ( Model, List Robot.ServerAction )
    -> ( Model, List Robot.ServerAction )
performRobotMove ( index, robot ) ( model, actions ) =
    case robot.action of
        Just (Robot.FireMissile _) ->
            ( model, actions )

        Just (Robot.FireLaser _) ->
            ( model, actions )

        Just (Robot.ArmMissile cell) ->
            ( { model
                | robots =
                    Array.set
                        index
                        { robot
                            | location = cell
                            , tool = Just Robot.ToolMissile
                            , action = Nothing
                        }
                        model.robots
              }
            , Robot.ServerArmMissile cell :: actions
            )

        Just (Robot.ArmLaser cell) ->
            ( { model
                | robots =
                    Array.set
                        index
                        { robot
                            | location = cell
                            , tool = Just Robot.ToolLaser
                            , action = Nothing
                        }
                        model.robots
              }
            , Robot.ServerArmLaser cell :: actions
            )

        Just (Robot.Shield cell) ->
            ( { model
                | robots =
                    Array.set
                        index
                        { robot
                            | location = cell
                            , tool = Just Robot.ToolShield
                            , action = Nothing
                        }
                        model.robots
              }
            , Robot.ServerShield cell :: actions
            )

        Just (Robot.Mine cell) ->
            let
                ( helium3, minedHelium3 ) =
                    mineHelium3 model.helium3 cell
            in
            ( { model
                | robots =
                    Array.set
                        index
                        { robot
                            | location = cell
                            , tool = Nothing
                            , action = Nothing
                        }
                        model.robots
                , helium3 = helium3
              }
                |> addMoney robot.owner minedHelium3
            , Robot.ServerMine cell :: actions
            )

        Just Robot.Kamikaze ->
            ( model, actions )

        Just (Robot.Move cell) ->
            ( { model
                | robots =
                    Array.set
                        index
                        { robot
                            | location = cell
                            , tool = Nothing
                            , action = Nothing
                        }
                        model.robots
              }
            , Robot.ServerMove cell :: actions
            )

        Nothing ->
            ( model, actions )


progressLaser : Direction -> Cell -> Model -> ( Model, Maybe Int )
progressLaser direction cell model =
    if Cell.onBoard cell then
        case robotAt model cell of
            Just ( index, robot ) ->
                let
                    ( hitRobot, shielded ) =
                        Robot.hit robot

                    updatedModel =
                        { model | robots = Array.set index hitRobot model.robots }
                in
                if shielded then
                    ( updatedModel, Just index )

                else
                    progressLaser direction (Cell.move direction cell) updatedModel

            Nothing ->
                progressLaser direction (Cell.move direction cell) model

    else
        ( model, Nothing )


shootWeapon :
    ( Int, Robot )
    -> ( Model, List Robot.ServerAction )
    -> ( Model, List Robot.ServerAction )
shootWeapon ( index, robot ) ( model, actions ) =
    case robot.action of
        Just (Robot.FireMissile target) ->
            let
                maybeHitRobot =
                    robotAt model target
                        |> Maybe.map (Tuple.mapSecond Robot.hit)

                robotsWithAttackingRobot =
                    Array.set
                        index
                        { robot | tool = Nothing, action = Nothing }
                        model.robots
            in
            case maybeHitRobot of
                Just ( hitRobotIndex, ( hitRobot, hadShield ) ) ->
                    ( { model
                        | robots =
                            Array.set
                                hitRobotIndex
                                hitRobot
                                robotsWithAttackingRobot
                      }
                    , Robot.ServerFireMissile target hadShield :: actions
                    )

                Nothing ->
                    ( { model | robots = robotsWithAttackingRobot }, actions )

        Just (Robot.FireLaser direction) ->
            progressLaser direction (Cell.move direction robot.location) model
                |> Tuple.mapSecond
                    (\maybeIndex ->
                        Robot.ServerFireLaser direction maybeIndex :: actions
                    )

        Just (Robot.ArmMissile cell) ->
            ( model, actions )

        Just (Robot.ArmLaser cell) ->
            ( model, actions )

        Just (Robot.Shield cell) ->
            ( model, actions )

        Just (Robot.Mine cell) ->
            ( model, actions )

        Just Robot.Kamikaze ->
            let
                robotsAround =
                    List.filterMap (robotAt model) (Cell.ring3 robot.location)

                hitRobots =
                    ( index, robot )
                        :: robotsAround
                        |> List.map (Tuple.mapSecond Robot.hit)

                destroyed =
                    List.filterMap
                        (\( index_, ( _, shield ) ) ->
                            if not shield then
                                Just index_

                            else
                                Nothing
                        )
                        hitRobots
            in
            ( { model
                | robots =
                    List.foldl
                        (\( index_, ( robot_, _ ) ) robots_ ->
                            Array.set index_ robot_ robots_
                        )
                        model.robots
                        hitRobots
              }
            , Robot.ServerKamikaze destroyed :: actions
            )

        Just (Robot.Move cell) ->
            ( model, actions )

        Nothing ->
            ( model, actions )


performTurn : Model -> ( Model, List Robot.ServerAction )
performTurn model =
    Array.toIndexedList model.robots
        |> List.foldl performRobotMove ( model, [] )
        |> (\( updatedModel, actions ) ->
                List.foldl
                    shootWeapon
                    ( updatedModel, actions )
                    (Array.toIndexedList updatedModel.robots)
           )
