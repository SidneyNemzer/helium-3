module Server exposing (..)

import GameServer
import LobbyServer
import Platform


type alias Flags =
    { seed : Int }


main : Program Flags Model Msg
main =
    Platform.worker
        { init = init
        , update = update
        , subscriptions = subscriptions
        }


type Page
    = Lobby LobbyServer.Model
    | Game GameServer.Model


type alias Model =
    { page : Page
    , seed : Int
    }


init : Flags -> ( Model, Cmd Msg )
init { seed } =
    let
        ( lModel, lCmd ) =
            LobbyServer.init ()
    in
    ( { page = Lobby lModel, seed = seed }
    , Cmd.map LobbyMsg lCmd
    )


type Msg
    = LobbyMsg LobbyServer.Msg
    | GameMsg GameServer.Msg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        LobbyMsg lMsg ->
            case model.page of
                Lobby oldLModel ->
                    let
                        ( lModel, lCmd, switchToGame ) =
                            LobbyServer.update lMsg oldLModel

                        ( page, cmd ) =
                            if switchToGame then
                                GameServer.init { seed = model.seed }
                                    |> Tuple.mapBoth Game (Cmd.map GameMsg)

                            else
                                ( Lobby lModel, Cmd.none )
                    in
                    ( { model | page = page }
                      -- Cmds run in reverse order, this ensures lobby messages
                      -- send before game messages
                    , Cmd.batch [ cmd, Cmd.map LobbyMsg lCmd ]
                    )

                _ ->
                    -- Log?
                    ( model, Cmd.none )

        GameMsg gMsg ->
            case model.page of
                Game gModel ->
                    let
                        ( page, cmd ) =
                            GameServer.update gMsg gModel
                                |> Tuple.mapBoth Game (Cmd.map GameMsg)
                    in
                    ( { model | page = page }, cmd )

                _ ->
                    -- Log?
                    ( model, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions model =
    case model.page of
        Lobby l ->
            LobbyServer.subscriptions l
                |> Sub.map LobbyMsg

        Game g ->
            GameServer.subscriptions g
                |> Sub.map GameMsg
