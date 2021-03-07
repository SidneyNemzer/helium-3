module Page.Client exposing (..)

import Browser
import Html exposing (Html)
import Page exposing (Page)
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
    case ( msg, model ) of
        ( LobbyMsg pageMsg, Lobby pageModel ) ->
            updatePage LobbyMsg Lobby pageMsg pageModel LobbyClient.update

        ( GameMsg pageMsg, Game pageModel ) ->
            updatePage GameMsg Game pageMsg pageModel GameClient.update

        ( _, _ ) ->
            -- Invalid message, such as a timer finishing after switching pages
            ( model, Cmd.none )


updatePage :
    (pageMsg -> Msg)
    -> (pageModel -> Model)
    -> pageMsg
    -> pageModel
    -> (pageMsg -> pageModel -> ( pageModel, Cmd pageMsg, Maybe Page ))
    -> ( Model, Cmd Msg )
updatePage toMsg toModel msg oldModel updateFn =
    let
        ( pageModel, pageCmd, maybePage ) =
            updateFn msg oldModel

        model =
            toModel pageModel

        cmd =
            Cmd.map toMsg pageCmd
    in
    case maybePage of
        Just (Page.Game flags) ->
            GameClient.init flags
                |> Tuple.mapBoth Game (Cmd.map GameMsg)
                |> batch cmd

        Just Page.Lobby ->
            LobbyClient.init ()
                |> Tuple.mapBoth Lobby (Cmd.map LobbyMsg)
                |> batch cmd

        Nothing ->
            ( model, cmd )


batch : Cmd msg -> ( model, Cmd msg ) -> ( model, Cmd msg )
batch cmd1 ( model, cmd2 ) =
    ( model, Cmd.batch [ cmd1, cmd2 ] )


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
