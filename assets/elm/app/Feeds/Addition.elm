module Feeds.Addition exposing (Addition, Error, Success, post)

import Api
import Http
import Json.Decode as D
import Paths
import Request exposing (Request)
import Types.Feed exposing (Candidate, Feed)


type alias Addition =
    Request Candidate Error Success


type alias Error =
    { candidate : Candidate
    , message : String
    }


type alias Success =
    { feed : Feed
    }


post : Api.Config -> Candidate -> (Result Error Success -> msg) -> Cmd msg
post apiConfig candidate toMsg =
    let
        message =
            "The feed at "
                ++ candidate.url
                ++ " could not be added"

        error =
            Error candidate message

        decoder =
            Types.Feed.decodeFeed |> D.map Success
    in
    Api.post
        apiConfig
        { url = Paths.createFeed
        , params = Types.Feed.encodeCandidate candidate
        , expect = Http.expectJson (Result.mapError (\_ -> error) >> toMsg) decoder
        }
