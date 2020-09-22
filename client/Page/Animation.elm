module Page.Animation exposing (main)

import Browser
import Color
import CountdownRing
import Game.Cell as Cell exposing (Cell)
import Game.Constants as Constants
import Html exposing (div, text)
import Html.Attributes exposing (style)
import Missile
import Player exposing (Player(..))
import Process
import Svg exposing (Svg, animate, defs)
import Svg.Attributes as SA
import Svg.Grid
import Svg.Robot
import Task


main : Program () Model Msg
main =
    Browser.document
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        }


type alias Model =
    { robot : Robot }


type alias Robot =
    { location : Cell
    , rotation : Float
    , animation : List Animation
    , missileArmed : Bool
    , missileFiredAt : Maybe Cell
    }


type Animation
    = Rotate Float
    | Drive Cell
    | ArmMissile
    | FireMissile Cell
    | ResetMissile


init : () -> ( Model, Cmd Msg )
init () =
    ( { robot =
            { location = Cell.fromXY 10 10
            , rotation = 100
            , animation = []
            , missileArmed = False
            , missileFiredAt = Nothing
            }
      }
    , Cmd.none
    )



-- UPDATE


type Msg
    = ClickAt Int Int
    | Animate


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ClickAt x y ->
            if model.robot.missileArmed then
                animate { model | robot = fireMissile (Cell.fromXY x y) model.robot }

            else
                animate { model | robot = armMissile (Cell.fromXY x y) model.robot }

        -- let
        --     robot =
        --         move (Cell.fromXY x y) model.robot
        -- in
        -- animate { model | robot = robot }
        Animate ->
            animate model


move : Cell -> Robot -> Robot
move target robot =
    let
        rotation =
            Cell.angle target robot.location

        animation =
            (if rotation /= robot.rotation then
                [ Rotate rotation ]

             else
                []
            )
                ++ [ Drive target ]
    in
    { robot | animation = animation }


armMissile : Cell -> Robot -> Robot
armMissile target robot =
    let
        rotation =
            Cell.angle target robot.location

        animation =
            (if rotation /= robot.rotation then
                [ Rotate rotation ]

             else
                []
            )
                ++ [ ArmMissile, Drive target ]
    in
    { robot | animation = animation }


fireMissile : Cell -> Robot -> Robot
fireMissile target robot =
    let
        rotation =
            Cell.angle target robot.location

        animation =
            (if rotation /= robot.rotation then
                [ Rotate rotation ]

             else
                []
            )
                ++ [ FireMissile target, ResetMissile ]
    in
    { robot | animation = animation }


animate : Model -> ( Model, Cmd Msg )
animate model =
    case model.robot.animation of
        next :: animation ->
            let
                ( robot, sleepMs ) =
                    applyAnimation next model.robot
            in
            ( { model | robot = { robot | animation = animation } }
            , Process.sleep sleepMs |> Task.perform (\() -> Animate)
            )

        _ ->
            ( model, Cmd.none )


applyAnimation : Animation -> Robot -> ( Robot, Float )
applyAnimation animation robot =
    case animation of
        Rotate angle ->
            ( { robot | rotation = angle }, 1000 )

        Drive cell ->
            ( { robot | location = cell }, 1000 )

        ArmMissile ->
            ( { robot | missileArmed = True }, 500 )

        FireMissile target ->
            ( { robot | missileFiredAt = Just target }, 1000 )

        ResetMissile ->
            ( { robot | missileArmed = False, missileFiredAt = Nothing }, 0 )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- VIEW


view : Model -> Browser.Document Msg
view model =
    { title = "Helium 3"
    , body =
        [ div
            [ style "text-align" "center"
            , style "width" "calc((100vw - 100vh) / 2)"
            , style "padding" "20px"
            ]
            []
        , Svg.svg
            [ SA.viewBox
                ("0 0 "
                    ++ String.fromInt (Svg.Grid.gridSideSvg + CountdownRing.side * 2)
                    ++ " "
                    ++ String.fromInt (Svg.Grid.gridSideSvg + CountdownRing.side * 2)
                )
            , style "display" "block"
            , style "height" "100%"
            , style "flex-grow" "2"
            ]
            (CountdownRing.view Color.green CountdownRing.init
                ++ [ Svg.svg
                        [ SA.x (String.fromInt CountdownRing.side)
                        , SA.y (String.fromInt CountdownRing.side)
                        ]
                        ([ defs []
                            [ Svg.Robot.def
                            , Svg.Robot.defMissile
                            , Missile.def
                            ]
                         , Svg.Grid.grid
                         ]
                            ++ (List.range 0 (20 * 20 - 1)
                                    |> List.map
                                        (\n ->
                                            let
                                                x =
                                                    modBy 20 n

                                                y =
                                                    n // 20
                                            in
                                            Svg.Grid.overlayCell (Just (ClickAt x y)) (Cell.fromXY x y)
                                        )
                               )
                            ++ [ viewRobot model.robot
                               , viewMissile model.robot
                               ]
                        )
                   ]
            )
        , div [ style "width" "calc((100vw - 100vh) / 2)" ]
            []
        , Html.node "style"
            []
            [ text
                """html, body {
                        height: 100%;
                        margin: 0;
                       }
                       body {
                        display: flex;
                       }
                    """
            ]
        ]
    }


viewRobot : Robot -> Svg msg
viewRobot robot =
    let
        -- This point will center the robot in the cell
        ( x, y ) =
            Cell.toScreenOffset
                robot.location
                Constants.cellSide
                -- 140 = robot width
                (Constants.cellSide // 2 - 140 // 2)

        -- The center of the cell
        ( cX, cY ) =
            Cell.toScreenOffset robot.location Constants.cellSide (Constants.cellSide // 2)
    in
    Svg.Robot.use
        [ SA.style
            (String.join ""
                [ "transform-origin: "
                , String.fromInt cX
                , "px "
                , String.fromInt cY
                , "px;"
                , " transform: "
                , "rotate("
                , String.fromFloat robot.rotation
                , "deg) "
                , "translate("
                , String.fromInt x
                , "px, "
                , String.fromInt y
                , "px);"
                , " transition: transform 1s, transform-origin 1s;"
                ]
            )
        ]
        (Player.color Player1)
        Nothing
        []


viewMissile : Robot -> Svg msg
viewMissile robot =
    let
        missileLocation =
            robot.missileFiredAt |> Maybe.withDefault robot.location

        -- This point will center the missile in the cell
        ( missileX, missileY ) =
            Cell.toScreenOffset2
                missileLocation
                Constants.cellSide
                -- 110, 42 = missile width, height
                ( Constants.cellSide // 2 - 110 // 2
                , Constants.cellSide // 2 - 42 // 2
                )

        -- The center of the cell
        ( cX, cY ) =
            Cell.toScreenOffset missileLocation Constants.cellSide (Constants.cellSide // 2)
    in
    if robot.missileArmed then
        Missile.view
            [ SA.style
                (String.join ""
                    [ "transform-origin: "
                    , String.fromInt cX
                    , "px "
                    , String.fromInt cY
                    , "px;"
                    , " transform: "
                    , "rotate("
                    , String.fromFloat robot.rotation
                    , "deg) "
                    , "translate("
                    , String.fromInt missileX
                    , "px, "
                    , String.fromInt missileY
                    , "px);"
                    , " transition: transform 1s, transform-origin 1s;"
                    ]
                )
            ]

    else
        text ""
