module Page.Client exposing (..)

import Browser
import Html exposing (Html)
import Page.GameClient as GameClient
import Page.LobbyClient as LobbyClient


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        }


init : () -> ( Model, Cmd Msg )
init () =
    let
        ( lModel, lCmd ) =
            LobbyClient.init ()
    in
    ( Lobby lModel, Cmd.map LobbyMsg lCmd )


type Model
    = Lobby LobbyClient.Model
    | Game GameClient.Model


type Msg
    = LobbyMsg LobbyClient.Msg
    | GameMsg GameClient.Msg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        LobbyMsg lMsg ->
            case model of
                Lobby oldLModel ->
                    let
                        ( lModel, lCmd, maybeGame ) =
                            LobbyClient.update lMsg oldLModel

                        ( page, cmd ) =
                            case maybeGame of
                                Just game ->
                                    GameClient.init { player = game.playerId }
                                        |> Tuple.mapBoth Game (Cmd.map GameMsg)

                                Nothing ->
                                    ( Lobby lModel, Cmd.none )
                    in
                    ( page, Cmd.batch [ cmd, Cmd.map LobbyMsg lCmd ] )

                _ ->
                    ( model, Cmd.none )

        GameMsg gMsg ->
            case model of
                Game oldGModel ->
                    GameClient.update gMsg oldGModel
                        |> Tuple.mapBoth Game (Cmd.map GameMsg)

                _ ->
                    ( model, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions model =
    case model of
        Lobby m ->
            LobbyClient.subscriptions m
                |> Sub.map LobbyMsg

        Game m ->
            GameClient.subscriptions m
                |> Sub.map GameMsg


view : Model -> Html Msg
view model =
    case model of
        Lobby m ->
            LobbyClient.view m
                |> Html.map LobbyMsg

        Game m ->
            GameClient.view m
                |> Html.map GameMsg
