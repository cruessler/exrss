module Api exposing (Response(..), fromJson, Config, config, post)

{-|

@docs Response

@docs fromJson
-}

import Http
import Json.Decode as Json
import Json.Encode
import Task exposing (Task, succeed, fail)


{-| Represents an API response.
-}
type Response a b
    = Error a
    | Success b


type alias Config =
    { apiToken : String }


config : String -> Config
config apiToken =
    Config apiToken


{-| Create a task for sending a POST request to a url.

The API token ist sent in an "Authorization" header.
-}
post : Config -> String -> Json.Encode.Value -> Task Http.RawError Http.Response
post config url params =
    let
        body =
            params
                |> Json.Encode.encode 0
                |> Http.string
    in
        Http.send Http.defaultSettings
            { verb = "POST"
            , headers =
                [ ( "Content-Type", "application/json" )
                , ( "Authorization", "Bearer " ++ config.apiToken )
                ]
            , url = url
            , body = body
            }


{-| Turn a `Http.Response` into a `Reponse a b`.

Responses with status code 2xx get decoded by `decodeSuccess` while responses
with status code 400 get decoded by `decodeFailure`.

This accounts for the fact that a JSON API might return a payload on error to
provide further information.
-}
fromJson :
    Json.Decoder a
    -> Json.Decoder b
    -> Task Http.RawError Http.Response
    -> Task Http.Error (Response a b)
fromJson decodeFailure decodeSuccess response =
    let
        transformFailure str =
            case Json.decodeString decodeFailure str of
                Ok v ->
                    succeed (Error v)

                Err msg ->
                    fail (Http.UnexpectedPayload msg)

        transformSuccess str =
            case Json.decodeString decodeSuccess str of
                Ok v ->
                    succeed (Success v)

                Err msg ->
                    fail (Http.UnexpectedPayload msg)
    in
        Task.mapError promoteError response
            `Task.andThen` handleResponse transformFailure transformSuccess


{-| The same as `Http.promoteError` which can’t be used here since it’s
private.
-}
promoteError : Http.RawError -> Http.Error
promoteError rawError =
    case rawError of
        Http.RawTimeout ->
            Http.Timeout

        Http.RawNetworkError ->
            Http.NetworkError


handleResponse :
    (String -> Task Http.Error a)
    -> (String -> Task Http.Error a)
    -> Http.Response
    -> Task Http.Error a
handleResponse transformFailure transformSuccess response =
    if 200 <= response.status && response.status < 300 then
        case response.value of
            Http.Text str ->
                transformSuccess str

            _ ->
                fail (Http.UnexpectedPayload "Response body is a blob, expecting a string.")
    else if response.status == 400 then
        case response.value of
            Http.Text str ->
                transformFailure str

            _ ->
                fail (Http.UnexpectedPayload "Response body is a blob, expecting a string.")
    else
        fail (Http.BadResponse response.status response.statusText)
