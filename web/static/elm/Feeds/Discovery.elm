module Feeds.Discovery exposing (Discovery, Error, Success, get, perform)

import Api
import Json.Decode as Decode
import Json.Encode as Encode
import Http
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


transformApiError :
    Api.Response a b
    -> Task (Result a c) (Result d b)
transformApiError response =
    case response of
        Api.Success success ->
            Task.succeed <| Ok success

        Api.Error error ->
            Task.fail <| Err error


fromApi :
    Error
    -> Task a (Api.Response Error b)
    -> Task (Result Error c) (Result d b)
fromApi error task =
    (task `Task.onError` (always <| Task.fail <| Err error))
        `Task.andThen` transformApiError


successDecoder : String -> Decode.Decoder Success
successDecoder url =
    Decode.object2 Success
        (Decode.succeed url)
        Types.Feed.decodeCandidates


get :
    Api.Config
    -> String
    -> Task (Result Error a) (Result b Success)
get apiConfig url =
    let
        message =
            "Feeds for url "
                ++ url
                ++ " could not be discovered"

        error =
            Error url message
    in
        Api.get apiConfig (Paths.candidates url) Encode.null
            |> Api.fromJson (Decode.succeed error) (successDecoder url)
            |> fromApi error


perform : (a -> b) -> Task a a -> Cmd b
perform onMsg task =
    Task.perform onMsg onMsg task
