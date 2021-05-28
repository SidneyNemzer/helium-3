module Page.GameClient exposing (..)

import Array
import ClientAction exposing (ClientAction(..))
import Dict exposing (Dict)
import Effect exposing (Effect(..), Timeline)
import HeliumGrid exposing (HeliumGrid)
import Html exposing (Html, button, div, span, text)
import Html.Attributes exposing (style)
import Html.Events exposing (onClick)
import Json.Decode exposing (Error)
import List
import Matrix
import Maybe.Extra
import Message exposing (ServerMessage)
import Page exposing (Page)
import Players exposing (Player, PlayerIndex(..), Players)
import Point exposing (Point)
import Ports
import Process
import Robot exposing (Robot, Tool(..))
import ServerAction exposing (ServerAction)
import Svg exposing (Svg, defs, g, rect, svg)
import Svg.Attributes exposing (color, fill, height, stroke, viewBox, width, x, y)
import Task
import View.Grid
import View.Miner
import View.Missile
import View.Robot
import View.RobotActions
import View.ScoreText
import View.Shield


type alias Flags =
    { player : PlayerIndex
    , helium : HeliumGrid
    , turns : Int
    }


type alias Model =
    { robots : Dict Int Robot
    , timeline : Timeline
    , selectedRobot : Maybe ( Selection, Int )
    , helium : HeliumGrid
    , players : Players
    , player : PlayerIndex
    , turn : PlayerIndex
    , turns : Int
    , countdownSeconds : Int
    , scoreAnimations : ScoreAnimations
    , gameOver : Bool
    }


type alias ScoreAnimations =
    Dict Int ( Point, Int )


type Selection
    = ChoosingAction
    | ChoosingMoveLocation
    | ChoosingArmMissileLocation
    | ChoosingFireMissileLocation
    | ChoosingShieldLocation
    | ChoosingMineLocation



-- | ChoosingLaserTarget
-- | ChoosingArmLaserLocation


init : Flags -> ( Model, Cmd Msg )
init { player, helium, turns } =
    ( { robots = Robot.initAll
      , timeline = []
      , selectedRobot = Nothing
      , helium = helium
      , players = Players.init
      , player = player
      , turn = Player1
      , turns = turns
      , countdownSeconds = 0
      , scoreAnimations = Dict.empty
      , gameOver = False
      }
    , Cmd.none
    )


type Msg
    = NextAnimation
    | DeselectRobot
    | ClickRobot Int
    | ChooseAction Selection
    | ClickPoint Point
    | OnServerMessage ServerMessage
    | OnError Error
    | Countdown
    | DeleteScoreAnimation Int
    | ReturnToLobby
    | Noop


update : Msg -> Model -> ( Model, Cmd Msg, Maybe Page )
update msg model =
    case msg of
        NextAnimation ->
            animate model
                |> Page.stay

        DeselectRobot ->
            ( { model | selectedRobot = Nothing }, Cmd.none )
                |> Page.stay

        ClickRobot id ->
            case Dict.get id model.robots of
                Just robot ->
                    onClickRobot robot model
                        |> Page.stay

                Nothing ->
                    ( model, Cmd.none, Nothing )

        ChooseAction selection ->
            ( { model
                | selectedRobot =
                    model.selectedRobot
                        |> Maybe.map (Tuple.mapFirst (\_ -> selection))
              }
            , Cmd.none
            , Nothing
            )

        ClickPoint point ->
            case model.selectedRobot of
                Just ( ChoosingMoveLocation, id ) ->
                    queueAction (Move id point) model
                        |> Page.stay

                Just ( ChoosingArmMissileLocation, id ) ->
                    queueAction (ArmMissile id point) model
                        |> Page.stay

                Just ( ChoosingFireMissileLocation, id ) ->
                    queueAction (FireMissile id point) model
                        |> Page.stay

                Just ( ChoosingShieldLocation, id ) ->
                    queueAction (Shield id point) model
                        |> Page.stay

                Just ( ChoosingMineLocation, id ) ->
                    queueAction (Mine id point) model
                        |> Page.stay

                Just ( ChoosingAction, _ ) ->
                    ( model, Cmd.none, Nothing )

                Nothing ->
                    ( model, Cmd.none, Nothing )

        OnServerMessage message ->
            case message of
                Message.Actions player actions ->
                    onActionRecieved model actions
                        |> Page.stay

                Message.Countdown player ->
                    startCountdown player model
                        |> Page.stay

                Message.GameLobbyJoin ->
                    ( model, Cmd.none, Just Page.Lobby )

                Message.GameEnd ->
                    ( { model | gameOver = True, turns = 0 }, Cmd.none, Nothing )

        OnError err ->
            ( model, Ports.log ("Error: " ++ Json.Decode.errorToString err), Nothing )

        Countdown ->
            tickCountdown model |> Page.stay

        DeleteScoreAnimation key ->
            ( { model | scoreAnimations = Dict.remove key model.scoreAnimations }
            , Cmd.none
            , Nothing
            )

        ReturnToLobby ->
            ( model, Message.sendClientMessageLobby Message.NewLobby, Just Page.Lobby )

        Noop ->
            ( model, Cmd.none, Nothing )


onClickRobot : Robot -> Model -> ( Model, Cmd Msg )
onClickRobot target model =
    let
        maybeSelection =
            getSelection model
    in
    if isValidTarget model maybeSelection model.player target then
        case maybeSelection of
            Just ( selection, selected ) ->
                queueFromSelection selection selected target model

            Nothing ->
                ( { model | selectedRobot = Just ( ChoosingAction, target.id ) }
                , Cmd.none
                )

    else
        ( model, Cmd.none )


queueFromSelection : Selection -> Robot -> Robot -> Model -> ( Model, Cmd Msg )
queueFromSelection selection selected target model =
    case selection of
        ChoosingAction ->
            ( model, Cmd.none )

        ChoosingMoveLocation ->
            -- Player clicked another robot, but robots can't occupy the same
            -- cell.
            ( model, Cmd.none )

        ChoosingArmMissileLocation ->
            queueActionAt ArmMissile selected.id model

        ChoosingShieldLocation ->
            queueActionAt Shield selected.id model

        ChoosingFireMissileLocation ->
            queueAction (FireMissile selected.id target.location) model

        ChoosingMineLocation ->
            queueActionAt Mine selected.id model


isValidTarget : Model -> Maybe ( Selection, Robot ) -> PlayerIndex -> Robot -> Bool
isValidTarget model selection player target =
    let
        properties =
            selection
                |> Maybe.andThen
                    (\( selection_, robot ) ->
                        selectionArea selection_
                            |> Maybe.map
                                (\( range, canTargetSelf ) ->
                                    { range = range
                                    , canTargetSelf = canTargetSelf
                                    , selectedRobot = robot
                                    }
                                )
                    )
    in
    if model.gameOver then
        False

    else
        case properties of
            Just { range, canTargetSelf, selectedRobot } ->
                if selectedRobot.id == target.id then
                    canTargetSelf

                else
                    Point.distance selectedRobot.location target.location <= range

            Nothing ->
                -- Nothing is selected. Players can only select their own robots.
                player == target.owner


queueActionAt : (Int -> Point -> ClientAction) -> Int -> Model -> ( Model, Cmd Msg )
queueActionAt action id model =
    case Dict.get id model.robots of
        Just robot ->
            queueAction (action id robot.location) model

        Nothing ->
            ( model, Cmd.none )


queueAction : ClientAction -> Model -> ( Model, Cmd Msg )
queueAction action model =
    ( updateRobot
        (ClientAction.id action)
        (Robot.queueAction action)
        { model | selectedRobot = Nothing }
    , Message.sendClientMessage <| Message.Queue action
    )


onActionRecieved : Model -> List ServerAction -> ( Model, Cmd Msg )
onActionRecieved model actions =
    animate
        { model
            | countdownSeconds = 0
            , turns =
                if model.turn == model.player then
                    model.turns - 1

                else
                    model.turns
            , timeline =
                List.foldl
                    (\action timeline ->
                        case Dict.get (ServerAction.id action) model.robots of
                            Just robot ->
                                Effect.fromServer action robot ++ timeline

                            Nothing ->
                                timeline
                    )
                    []
                    actions
        }


startCountdown : PlayerIndex -> Model -> ( Model, Cmd Msg )
startCountdown player model =
    ( { model
        | turn = player
        , countdownSeconds = 5
      }
      -- Only start a timer if the countdown already finished. Otherwise,
      -- there's already a timer running
    , if model.countdownSeconds == 0 then
        Process.sleep 1000 |> Task.perform (\() -> Countdown)

      else
        Cmd.none
    )


tickCountdown : Model -> ( Model, Cmd Msg )
tickCountdown model =
    let
        remaining =
            max (model.countdownSeconds - 1) 0
    in
    ( { model | countdownSeconds = remaining }
    , if remaining > 0 then
        Process.sleep 1000 |> Task.perform (\() -> Countdown)

      else
        Cmd.none
    )


updateRobot : Int -> (Robot -> Robot) -> Model -> Model
updateRobot id fn model =
    { model | robots = Dict.update id (Maybe.map fn) model.robots }


getSelection : Model -> Maybe ( Selection, Robot )
getSelection model =
    model.selectedRobot
        |> Maybe.andThen
            (\( selection, id ) ->
                Dict.get id model.robots
                    |> Maybe.map (Tuple.pair selection)
            )


{-| Returns the range of each type of action. `ChoosingAction` is a special
case that renders a menu instead of a selection area. The `Bool` indicates
if the selected robot can be targeted.
-}
selectionArea : Selection -> Maybe ( Int, Bool )
selectionArea selection =
    case selection of
        ChoosingAction ->
            Nothing

        ChoosingMoveLocation ->
            Just ( 4, False )

        ChoosingArmMissileLocation ->
            Just ( 4, True )

        ChoosingFireMissileLocation ->
            Just ( 3, True )

        ChoosingShieldLocation ->
            Just ( 4, True )

        ChoosingMineLocation ->
            Just ( 3, True )



-- ANIMATION


animate : Model -> ( Model, Cmd Msg )
animate model =
    case model.timeline of
        [] ->
            ( model, Cmd.none )

        next :: rest ->
            let
                ( newModel, sleepMs, cmd1 ) =
                    animateHelp next { model | timeline = rest }
            in
            if sleepMs == 0 then
                animate newModel |> Tuple.mapSecond (\cmd2 -> Cmd.batch [ cmd1, cmd2 ])

            else
                ( newModel
                , Cmd.batch
                    [ Process.sleep (toFloat sleepMs) |> Task.perform (\() -> NextAnimation)
                    , cmd1
                    ]
                )


animateHelp : Effect -> Model -> ( Model, Int, Cmd Msg )
animateHelp effect model =
    case effect of
        SetLocation id point ->
            ( updateRobot id (Robot.setLocation point) model, 0, Cmd.none )

        SetRotation id rotation ->
            ( updateRobot id (Robot.setRotation rotation) model, 0, Cmd.none )

        SetMinerActive id ->
            ( updateRobot id Robot.setMinerActive model, 0, Cmd.none )

        MineAt id point ->
            let
                ( ground, mined ) =
                    HeliumGrid.mine point model.helium
            in
            case Dict.get id model.robots of
                Just robot ->
                    let
                        ( newModel, cmd ) =
                            { model
                                | helium = ground
                                , players = Players.addScore robot.owner mined model.players
                            }
                                |> updateRobot id (\r -> { r | mined = r.mined + mined })
                                |> createScoreAnimation robot.location mined
                    in
                    ( newModel, 0, cmd )

                Nothing ->
                    ( model, 0, Cmd.none )

        SetState id state ->
            ( updateRobot id (Robot.setState state) model, 0, Cmd.none )

        Impact point forceShield ->
            case Robot.getRobotAt point model.robots of
                Just robot ->
                    let
                        impacted =
                            Robot.impact forceShield robot

                        destroyed =
                            impacted.state == Robot.Destroyed

                        animation =
                            if not destroyed then
                                [ Wait 1000
                                , SetState robot.id (Robot.removeShield impacted).state
                                ]

                            else
                                []

                        helium =
                            if not destroyed then
                                model.helium

                            else
                                HeliumGrid.drop robot.location (robot.mined // 2) model.helium

                        players =
                            if not destroyed then
                                model.players

                            else
                                Players.addScore robot.owner (-robot.mined // 2) model.players

                        newModel =
                            { model
                                | timeline = animation ++ model.timeline
                                , players = players
                                , helium = helium
                            }
                                |> updateRobot robot.id (\_ -> impacted)
                    in
                    if destroyed then
                        let
                            ( newModel2, cmd ) =
                                createScoreAnimation robot.location (-robot.mined // 2) newModel
                        in
                        ( newModel2, 0, cmd )

                    else
                        ( newModel, 0, Cmd.none )

                Nothing ->
                    ( model, 0, Cmd.none )

        Wait ms ->
            ( model, ms, Cmd.none )


createScoreAnimation : Point -> Int -> { a | scoreAnimations : ScoreAnimations } -> ( { a | scoreAnimations : ScoreAnimations }, Cmd Msg )
createScoreAnimation point amount model =
    let
        nextKey =
            Dict.keys model.scoreAnimations
                |> List.foldl max 0
    in
    ( { model | scoreAnimations = Dict.insert nextKey ( point, amount ) model.scoreAnimations }
    , Process.sleep (toFloat View.ScoreText.durationSeconds * 1000)
        |> Task.perform (\_ -> DeleteScoreAnimation nextKey)
    )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Message.receiveServerMessage OnServerMessage OnError
        ]



-- VIEW


view : Model -> Html Msg
view model =
    div [ style "height" "100%" ]
        [ View.Missile.style
        , View.Grid.style
        , View.Shield.style
        , View.ScoreText.style
        , globalStyles
        , keyframesAppear
        , div
            [ style "display" "flex"
            , style "position" "relative"
            , style "height" "100%"
            ]
            [ div [ style "flex" "1 0", style "padding" "20px" ]
                [ viewPlayers model.players model.player
                , div [ style "margin-bottom" "10px", style "text-align" "center" ]
                    [ text "Your Remaining Turns: "
                    , text <| String.fromInt model.turns
                    ]
                , div [ style "text-align" "center" ]
                    [ text "Current Turn: "
                    , span [ style "color" (Players.color model.turn) ]
                        [ text "Player "
                        , text <| String.fromInt <| Players.toNumber model.turn
                        ]
                    ]
                , if model.countdownSeconds > 0 then
                    div [ style "text-align" "center" ]
                        [ text <| String.fromInt model.countdownSeconds
                        ]

                  else
                    text ""
                ]
            , svg
                [ style "flex" "6 0"
                , style "padding" "20px"
                , viewBox View.Grid.viewBox
                ]
                ([ defs []
                    [ View.Robot.def
                    , View.Missile.def
                    , View.Shield.def
                    , View.Miner.def
                    ]
                 , View.Grid.grid
                 , viewHeliumGrid model.helium
                 , viewSelection model
                 ]
                    ++ (Dict.values model.robots |> List.map (viewRobot model))
                    ++ [ viewScoreTexts model.scoreAnimations ]
                )
            , div [ style "flex" "1" ] []
            , viewActionPicker model.robots model.selectedRobot
            , if model.gameOver then
                viewGameOver

              else
                text ""
            ]
        ]


globalStyles : Html msg
globalStyles =
    Html.node "style"
        []
        [ text """
            html,
            body,
            #root {
                margin: 0;
                height: 100%;
            }
          """
        ]


viewGameOver : Html Msg
viewGameOver =
    let
        gameOverText =
            "Game Over"
                |> String.split ""
                |> List.indexedMap
                    (\i letter ->
                        let
                            delay =
                                String.fromFloat (toFloat i * 0.4) ++ "s"

                            animation =
                                "appear " ++ delay ++ " step-end"
                        in
                        span [ style "animation" animation ]
                            [ text letter ]
                    )
    in
    div
        [ style "position" "absolute"
        , style "top" "0"
        , style "bottom" "0"
        , style "right" "0"
        , style "left" "0"
        , style "display" "flex"
        , style "align-items" "center"
        , style "justify-content" "center"
        , style "flex-direction" "column"
        ]
        [ div [ style "font-size" "100px" ] gameOverText
        , div [ style "margin-top" "30px" ]
            [ button [ onClick ReturnToLobby ] [ text "Return to lobby" ] ]
        ]


keyframesAppear : Html msg
keyframesAppear =
    Html.node "style"
        []
        [ text """
            @keyframes appear {
                from { opacity: 0 }
                to { opacity: 1 }
            }
          """
        ]


viewActionPicker : Dict Int Robot -> Maybe ( Selection, Int ) -> Html Msg
viewActionPicker robots maybeSelection =
    case maybeSelection of
        Just ( ChoosingAction, id ) ->
            case Dict.get id robots of
                Just robot ->
                    viewActionPickerHelp robot

                Nothing ->
                    text ""

        _ ->
            text ""


viewActionPickerHelp : Robot -> Html Msg
viewActionPickerHelp robot =
    View.RobotActions.view
        { noop = Noop
        , cancel = DeselectRobot
        , move = ChooseAction ChoosingMoveLocation
        , armMissile = ChooseAction ChoosingArmMissileLocation
        , fireMissile =
            if Robot.getTool robot == Just ToolMissile then
                Just (ChooseAction ChoosingFireMissileLocation)

            else
                Nothing
        , shield = ChooseAction ChoosingShieldLocation
        , mine = ChooseAction ChoosingMineLocation
        }


viewPlayers : Players -> PlayerIndex -> Html Msg
viewPlayers players self =
    div []
        [ viewPlayer players.player1 (Player1 == self)
        , viewPlayer players.player2 (Player2 == self)
        , viewPlayer players.player3 (Player3 == self)
        , viewPlayer players.player4 (Player4 == self)
        ]


viewPlayer : Player -> Bool -> Html Msg
viewPlayer player isSelf =
    div [ style "margin-bottom" "30px" ]
        [ div
            [ style "display" "flex"
            , style "align-items" "center"
            , style "font-size" "24px"
            ]
            [ span []
                [ text "Player "
                , text <| String.fromInt <| Players.toNumber player.id
                ]
            , if isSelf then
                span [ style "font-size" "14px" ] [ text " (you)" ]

              else
                text ""
            , span [ style "flex" "1" ] []
            , span []
                [ text "$"
                , text (String.fromInt player.score)
                ]
            ]
        , div [ style "background" (Players.color player.id), style "height" "10px" ] []
        ]


viewScoreTexts : ScoreAnimations -> Svg msg
viewScoreTexts =
    Dict.values
        >> List.map (\( point, score ) -> View.ScoreText.view point score)
        >> g []


viewSelection : Model -> Svg Msg
viewSelection model =
    model.selectedRobot
        |> Maybe.andThen
            (\( selection, id ) ->
                Dict.get id model.robots |> Maybe.map (Tuple.pair selection)
            )
        |> Maybe.map viewSelectionHelp
        |> Maybe.withDefault (text "")


viewSelectionHelp : ( Selection, Robot ) -> Svg Msg
viewSelectionHelp ( selection, robot ) =
    -- ChooseAction is rendered outside of the SVG by `viewActionPicker`
    case selectionArea selection of
        Just ( size, center ) ->
            let
                { highlight, hover } =
                    View.Grid.highlightAround robot.location size ClickPoint center
            in
            g [] [ highlight, hover ]

        Nothing ->
            text ""


viewRobot : Model -> Robot -> Svg Msg
viewRobot model robot =
    let
        robotSvg =
            View.Robot.use
                robot.location
                robot.rotation
                (Players.color robot.owner)
                robot.id

        targetSvg =
            case Robot.getTarget robot of
                Just target ->
                    [ View.Grid.highlight target
                    , View.Grid.dottedLine robot.location target
                    ]

                Nothing ->
                    []

        toolSvg =
            Robot.getTool robot
                |> Maybe.map (viewTool robot)
                |> Maybe.Extra.toList

        cursor =
            if isValidTarget model (getSelection model) model.player robot then
                [ style "cursor" "pointer" ]

            else
                []
    in
    if robot.state == Robot.Destroyed then
        text ""

    else
        g []
            [ g [] targetSvg
            , g (onClick (ClickRobot robot.id) :: cursor) <|
                List.concat
                    [ [ robotSvg ]
                    , toolSvg
                    , [ viewMiner robot ]
                    ]
            ]


viewTool : Robot -> Robot.Tool -> Svg msg
viewTool robot tool =
    case tool of
        ToolShield highlight ->
            View.Shield.use robot.location robot.rotation highlight

        ToolLaser ->
            -- TODO
            text ""

        ToolMissile ->
            let
                location =
                    case robot.state of
                        Robot.FireMissile target True ->
                            target

                        _ ->
                            robot.location
            in
            View.Missile.use location robot.rotation


viewMiner : Robot -> Svg msg
viewMiner robot =
    case robot.state of
        Robot.Mine { active } ->
            if active then
                View.Miner.use robot.location robot.rotation

            else
                text ""

        _ ->
            text ""


viewHeliumGrid : HeliumGrid -> Svg msg
viewHeliumGrid helium =
    Matrix.toIndexedArray helium
        |> Array.filter (\( _, amount ) -> amount > 0)
        |> Array.map (Tuple.mapFirst Point.fromTuple >> viewHelium)
        |> Array.toList
        |> g []


viewHelium : ( Point, Int ) -> Svg msg
viewHelium ( point, amount ) =
    View.Grid.fillCell point amount
