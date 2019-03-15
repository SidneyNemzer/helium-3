module Game.Robot exposing
    ( Action(..)
    , Robot
    , ServerAction(..)
    , Tool(..)
    , init
    , serverActionEncoder
    )

import Game.Cell as Cell exposing (Cell)
import Game.Player as Player exposing (PlayerIndex)
import Json.Encode as Encode


{-| Describes what a robot did so that clients can animate it. Includes
information that clients don't know, like if a weapon hit a shielded robot.
-}
type ServerAction
    = ServerFireMissile Cell Bool
    | ServerFireLaser Float Int
    | ServerArmMissile Cell
    | ServerArmLaser Cell
    | ServerShield Cell
    | ServerMine Cell
    | ServerKamikaze (List Int)
    | ServerMove Cell


type Action
    = FireMissile Cell
    | FireLaser Float
    | ArmMissile Cell
    | ArmLaser Cell
    | Shield Cell
    | Mine Cell
    | Kamikaze
    | Move Cell


type Tool
    = ToolShield
    | ToolLaser
    | ToolMissile


type alias Robot =
    { location : Cell
    , action : Maybe Action
    , tool : Maybe Tool
    , destroyed : Bool
    , owner : PlayerIndex
    }


init : Cell -> PlayerIndex -> Robot
init cell owner =
    { location = cell
    , action = Nothing
    , tool = Nothing
    , destroyed = False
    , owner = owner
    }


moveTarget : Robot -> Maybe Cell
moveTarget robot =
    case robot.action of
        Just (FireMissile _) ->
            Nothing

        Just (FireLaser _) ->
            Nothing

        Just (ArmMissile cell) ->
            Just cell

        Just (ArmLaser cell) ->
            Just cell

        Just (Shield cell) ->
            Just cell

        Just (Mine cell) ->
            Just cell

        Just Kamikaze ->
            Nothing

        Just (Move cell) ->
            Just cell

        Nothing ->
            Nothing


serverActionEncoder : ServerAction -> Int -> Encode.Value
serverActionEncoder serverAction robot =
    case serverAction of
        ServerFireMissile target shield ->
            Encode.object
                [ ( "action", Encode.string "FIRE_MISSILE" )
                , ( "target", Cell.encode target )
                , ( "shield", Encode.bool shield )
                , ( "robot", Encode.int robot )
                ]

        ServerFireLaser angle stoppedBy ->
            Encode.object
                [ ( "action", Encode.string "FIRE_LASER" )
                , ( "target", Encode.float angle )
                , ( "stoppedBy", Encode.int stoppedBy )
                , ( "robot", Encode.int robot )
                ]

        ServerArmMissile target ->
            Encode.object
                [ ( "action", Encode.string "ARM_MISSILE" )
                , ( "target", Cell.encode target )
                , ( "robot", Encode.int robot )
                ]

        ServerArmLaser target ->
            Encode.object
                [ ( "action", Encode.string "ARM_LASER" )
                , ( "target", Cell.encode target )
                , ( "robot", Encode.int robot )
                ]

        ServerShield target ->
            Encode.object
                [ ( "action", Encode.string "SHIELD" )
                , ( "target", Cell.encode target )
                , ( "robot", Encode.int robot )
                ]

        ServerMine target ->
            Encode.object
                [ ( "action", Encode.string "MINE" )
                , ( "target", Cell.encode target )
                , ( "robot", Encode.int robot )
                ]

        ServerKamikaze destroyed ->
            Encode.object
                [ ( "action", Encode.string "KAMAKAZIE" )
                , ( "destroyed", Encode.list Encode.int destroyed )
                , ( "robot", Encode.int robot )
                ]

        ServerMove target ->
            Encode.object
                [ ( "action", Encode.string "MOVE" )
                , ( "target", Cell.encode target )
                , ( "robot", Encode.int robot )
                ]
