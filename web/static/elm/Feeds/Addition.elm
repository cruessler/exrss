module Feeds.Addition exposing (Addition, Error, Success, post, perform)

import Api
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
    { candidate : Candidate
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


post :
    Api.Config
    -> Candidate
    -> Task (Result Error a) (Result b Success)
post apiConfig candidate =
    let
        message =
            "The feed at "
                ++ candidate.url
                ++ " could not be added"

        error =
            Error candidate message
    in
        Api.post apiConfig Paths.createFeed (Types.Feed.encodeCandidate candidate)
            |> Api.fromJson
                (Decode.succeed error)
                (Decode.succeed <| Success candidate)
            |> fromApi error


perform : (a -> b) -> Task a a -> Cmd b
perform onMsg task =
    Task.perform onMsg onMsg task
