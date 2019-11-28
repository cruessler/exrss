module Feeds.Discovery exposing (Discovery, Error, Success, get)

import Api
import Http
import Json.Decode as Decode
import Json.Encode as Encode
import Paths
import Request exposing (..)
import Task exposing (Task)
import Types.Feed exposing (..)


type alias Discovery =
    Request String Error Success


type alias Error =
    { url : String
    , message : String
    }


type alias Success =
    { url : String
    , candidates : List Candidate
    }


fromApi :
    Error
    -> Http.Request Success
    -> Task Error Success
fromApi error request =
    request
        |> Http.toTask
        |> Task.mapError (always error)


successDecoder : String -> Decode.Decoder Success
successDecoder url =
    Decode.map2 Success
        (Decode.succeed url)
        Types.Feed.decodeCandidates


get :
    Api.Config
    -> String
    -> Task Error Success
get apiConfig url =
    let
        message =
            "Feeds for url "
                ++ url
                ++ " could not be discovered"

        error =
            Error url message
    in
    Api.get
        apiConfig
        { url = Paths.candidates url
        , params = Encode.null
        , decoder = successDecoder url
        }
        |> fromApi error
