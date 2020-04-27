module Api exposing
    ( get, post, patch
    , Config, configFromToken, delete
    )

{-|

@docs get, post, patch, send

-}

import Http
import Json.Encode as E


type Config
    = Config
        { apiToken : String
        }


type alias Request msg =
    { url : String
    , params : E.Value
    , expect : Http.Expect msg
    }


type Method
    = Get
    | Post
    | Patch
    | Delete


configFromToken : String -> Config
configFromToken apiToken =
    Config { apiToken = apiToken }


toString : Method -> String
toString method =
    case method of
        Get ->
            "GET"

        Post ->
            "POST"

        Patch ->
            "PATCH"

        Delete ->
            "DELETE"


{-| Create a task for sending a GET request to a url.
-}
get : Config -> Request msg -> Cmd msg
get =
    send Get


{-| Create a task for sending a POST request to a url.
-}
post : Config -> Request msg -> Cmd msg
post =
    send Post


{-| Create a task for sending a PATCH request to a url.
-}
patch : Config -> Request msg -> Cmd msg
patch =
    send Patch


{-| Create a task for sending a DELETE request to a url.
-}
delete : Config -> Request msg -> Cmd msg
delete =
    send Delete


{-| Create a `Cmd` for sending a request to a URL.

The API token is sent in an "Authorization" header.

-}
send : Method -> Config -> Request msg -> Cmd msg
send method (Config config_) { url, params, expect } =
    Http.request
        { method = toString method
        , headers =
            [ Http.header "Authorization" ("Bearer " ++ config_.apiToken)
            ]
        , url = url
        , body = Http.jsonBody params
        , expect = expect
        , timeout = Nothing
        , tracker = Nothing
        }
