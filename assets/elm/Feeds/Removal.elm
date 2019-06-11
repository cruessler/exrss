module Feeds.Removal exposing (Error, Removal, Success, delete)

import Api
import Http
import Json.Decode as Decode
import Json.Encode as Encode
import Paths
import Request exposing (..)
import Task exposing (Task)
import Types.Feed exposing (..)


type alias Removal =
    Request Feed Error Success


type alias Error =
    { feed : Feed
    , message : String
    }


type alias Success =
    { feed : Feed
    }


fromApi :
    Error
    -> Http.Request Success
    -> Task Error Success
fromApi error request =
    request
        |> Http.toTask
        |> Task.mapError (always error)


delete :
    Api.Config
    -> Feed
    -> Task Error Success
delete apiConfig feed =
    let
        message =
            "The feed at "
                ++ feed.url
                ++ " could not be deleted"

        error =
            Error feed message
    in
    Api.delete apiConfig
        { url = Paths.feed feed
        , params = Encode.null
        , decoder = Decode.succeed <| Success feed
        }
        |> fromApi error
