module Feeds.Discovery exposing (Discovery, Error, Success, get)

import Api
import Http
import Json.Decode as D
import Json.Encode as E
import Paths
import Request exposing (Request)
import Types.Feed exposing (Candidate)


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


successDecoder : String -> D.Decoder Success
successDecoder url =
    D.map2 Success
        (D.succeed url)
        Types.Feed.decodeCandidates


get : Api.Config -> String -> (Result Error Success -> msg) -> Cmd msg
get apiConfig url toMsg =
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
        , params = E.null
        , expect = Http.expectJson (Result.mapError (\_ -> error) >> toMsg) (successDecoder url)
        }
