module Game exposing (Model, Msg, init, main, subscriptions, update)

import Array exposing (Array)
import Dict exposing (Dict)
import Game.Cell as Cell exposing (Cell)
import Game.Constants as Constants
import Game.Player as Player exposing (Player, PlayerIndex(..))
import Game.Robot as Robot exposing (Robot)
import Matrix exposing (Matrix)
import Platform
import Process
import Random
import Task


main =
    Platform.worker
        { init = init
        , update = update
        , subscriptions = subscriptions
        }


type Countdown
    = UntilMove Int
    | UntilMoveEnd Int


type alias Model =
    { -- Who will move next
      nextMove : PlayerIndex

    -- What is the next event and when will it happen
    , countdown : Countdown

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


type Msg
    = Turn


sleep : Msg -> Float -> Cmd Msg
sleep msg time =
    Process.sleep time |> Task.perform (\() -> msg)


init : () -> ( Model, Cmd Msg )
init () =
    let
        firstMoveTime =
            Constants.secondsBeforeStart
                + Constants.secondsTurnCountdown
                * 1000
    in
    ( { nextMove = Player1
      , countdown = UntilMove firstMoveTime
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
      , helium3 = Matrix.empty
      }
    , sleep Turn (toFloat firstMoveTime)
    )


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
    -> ( Model, List Robot.Action )
    -> ( Model, List Robot.Action )
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
            , Robot.ArmMissile cell :: actions
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
            , Robot.ArmLaser cell :: actions
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
            , Robot.Shield cell :: actions
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
            , Robot.Mine cell :: actions
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
            , Robot.Move cell :: actions
            )

        Nothing ->
            ( model, actions )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Turn ->
            let
                ( newModel, actions ) =
                    Array.toIndexedList model.robots
                        |> List.foldl performRobotMove ( model, [] )
            in
            ( newModel
            , Cmd.none
            )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none
