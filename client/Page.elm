module Page exposing (..)

import HeliumGrid exposing (HeliumGrid)
import Players exposing (PlayerIndex)



-- Flags are redefined here to avoid circular imports


type alias GameFlags =
    { player : PlayerIndex
    , helium : HeliumGrid
    , turns : Int
    }


type Page
    = Lobby
    | Game GameFlags
    | Error String


stay : ( model, msg ) -> ( model, msg, Maybe Page )
stay ( model, msg ) =
    ( model, msg, Nothing )



-- TODO Maybe the update function should use this signature:
--
--     update : Msg -> Model -> Page.Update
--
--     type Update
--         = Stay (model, Cmd msg)
--         | Switch Page
