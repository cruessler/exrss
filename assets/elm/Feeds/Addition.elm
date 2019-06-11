module Feeds.Addition exposing (Addition, Error, Success, post)

import Api
import Http
import Json.Decode as Decode
import Json.Encode as Encode
import Paths
import Request exposing (..)
import Task exposing (Task)
import Types.Feed exposing (..)


type alias Addition =
    Request Candidate Error Success


type alias Error =
    { candidate : Candidate
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


post :
    Api.Config
    -> Candidate
    -> Task Error Success
post apiConfig candidate =
    let
        message =
            "The feed at "
                ++ candidate.url
                ++ " could not be added"

        error =
            Error candidate message
    in
    Api.post apiConfig
        { url = Paths.createFeed
        , params = Types.Feed.encodeCandidate candidate
        , decoder = Types.Feed.decodeFeed |> Decode.map Success
        }
        |> fromApi error
