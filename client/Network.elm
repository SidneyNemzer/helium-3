module Network exposing (gameDecoder)

import Helium3Grid
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Extra as Decode
import Model exposing (Countdown, Model)
import Player
import Robot
import Time exposing (Posix)


gameDecoder : Posix -> Maybe Countdown -> List Float -> Maybe Int -> Decoder Model
gameDecoder time countdown rotations selectedRobot =
    Decode.succeed Model
        |> Decode.andMap (Decode.field "turn" Player.decodeTurn)
        |> Decode.andMap (Decode.succeed countdown)
        |> Decode.andMap (Decode.field "players" Player.decodePlayers)
        |> Decode.andMap (Decode.field "robots" (Robot.robotsDecoder rotations))
        |> Decode.andMap (Decode.field "helium3" Helium3Grid.decoder)
        |> Decode.andMap (Decode.succeed selectedRobot)
        |> Decode.andMap (Decode.succeed time)
