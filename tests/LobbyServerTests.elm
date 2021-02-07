module LobbyServerTests exposing (suite)

import Expect exposing (Expectation)
import LobbyServer
import Message
import Test exposing (..)


suite : Test
suite =
    describe "LobbyServer"
        [ describe "autostart" <|
            let
                ( update0, _ ) =
                    LobbyServer.init ()

                ( update1, _, switch1 ) =
                    LobbyServer.update (LobbyServer.Message Message.Connect) update0

                ( update2, _, switch2 ) =
                    LobbyServer.update (LobbyServer.Message Message.Connect) update1

                ( update3, _, switch3 ) =
                    LobbyServer.update (LobbyServer.Message Message.Connect) update2

                ( _, _, switch4 ) =
                    LobbyServer.update (LobbyServer.Message Message.Connect) update3
            in
            testAll
                [ ( "does not start on first connection", switch1, Expect.false )
                , ( "does not start on second connection", switch2, Expect.false )
                , ( "does not start on third connection", switch3, Expect.false )
                , ( "starts on the fourth connection", switch4, Expect.true )
                ]
        ]


testAll : List ( String, Bool, String -> Bool -> Expectation ) -> List Test
testAll =
    List.map testBool


testBool : ( String, Bool, String -> Bool -> Expectation ) -> Test
testBool ( name, value, expect ) =
    test name (\_ -> expect name value)
