module Feeds.Removal exposing (Error, Removal, Success, delete)

import Api
import Http
import Json.Decode as D
import Json.Encode as E
import Paths
import Request exposing (Request)
import Types.Feed as Feed exposing (Feed)


type alias Removal =
    Request Feed Error Success


type alias Error =
    { feed : Feed
    , message : String
    }


type alias Success =
    { feed : Feed
    }


delete : Api.Config -> Feed -> (Result Error Success -> msg) -> Cmd msg
delete apiConfig feed toMsg =
    let
        message =
            "The feed at "
                ++ Feed.url feed
                ++ " could not be deleted"

        error =
            Error feed message

        decoder =
            D.succeed <| Success feed
    in
    Api.delete
        apiConfig
        { url = Paths.feed feed
        , params = E.null
        , expect = Http.expectJson (Result.mapError (\_ -> error) >> toMsg) decoder
        }
