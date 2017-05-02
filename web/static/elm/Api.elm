module Api
    exposing
        ( Config
        , config
        , get
        , post
        , patch
        )

{-| @docs get, post, patch, send
-}

import Http
import Json.Decode as Decode
import Json.Encode as Encode
import Task exposing (Task, succeed, fail)


type alias Config =
    { apiToken : String }


type alias Request a =
    { url : String
    , params : Encode.Value
    , decoder : Decode.Decoder a
    }


type Method
    = Get
    | Post
    | Patch


config : String -> Config
config apiToken =
    Config apiToken


toString : Method -> String
toString method =
    case method of
        Get ->
            "GET"

        Post ->
            "POST"

        Patch ->
            "PATCH"


{-| Create a task for sending a GET request to a url.
-}
get : Config -> Request a -> Http.Request a
get =
    send Get


{-| Create a task for sending a POST request to a url.
-}
post : Config -> Request a -> Http.Request a
post =
    send Post


{-| Create a task for sending a PATCH request to a url.
-}
patch : Config -> Request a -> Http.Request a
patch =
    send Patch


{-| Create a task for sending a request to a url.

The API token is sent in an "Authorization" header.

-}
send : Method -> Config -> Request a -> Http.Request a
send method config { url, params, decoder } =
    Http.request
        { method = toString method
        , headers =
            [ Http.header "Authorization" ("Bearer " ++ config.apiToken)
            ]
        , url = url
        , body = Http.jsonBody params
        , expect = Http.expectJson decoder
        , timeout = Nothing
        , withCredentials = False
        }
