module App.Feeds exposing (main)

import Api
import Browser
import Dict
import Feeds.Addition as Addition
import Feeds.Discovery as Discovery
import Feeds.Model as Model exposing (Model)
import Feeds.Msg as Msg exposing (Msg(..))
import Feeds.View as View
import Request exposing (Request(..))
import String
import Types.Feed as Feed


main : Program Flags Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , view = View.view
        , subscriptions = always Sub.none
        }


type alias Flags =
    { apiToken : String
    }


init : Flags -> ( Model, Cmd Msg )
init flags =
    let
        apiConfig =
            Api.configFromToken flags.apiToken
    in
    ( { apiConfig = apiConfig
      , showOptions = False
      , discoveryUrl = ""
      , requests = Dict.empty
      }
    , Cmd.none
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ToggleOptions ->
            ( { model | showOptions = not model.showOptions }, Cmd.none )

        SetDiscoveryUrl url ->
            ( { model | discoveryUrl = url }, Cmd.none )

        DiscoverFeeds url ->
            if String.isEmpty url then
                ( model, Cmd.none )

            else
                let
                    newRequests =
                        Dict.insert
                            url
                            (Model.Discovery <| Request.InProgress url)
                            model.requests
                in
                ( { model | requests = newRequests }
                , Discovery.get model.apiConfig url Msg.Discovery
                )

        AddFeed candidate ->
            let
                newRequests =
                    Dict.insert
                        candidate.url
                        (Model.Addition <| Request.InProgress candidate)
                        model.requests
            in
            ( { model | requests = newRequests }
            , Addition.post model.apiConfig candidate Msg.Addition
            )

        RemoveResponse url ->
            let
                newRequests =
                    Dict.remove url model.requests
            in
            ( { model
                | requests = newRequests
              }
            , Cmd.none
            )

        Msg.Discovery result ->
            let
                url_ =
                    case result of
                        Ok { url } ->
                            url

                        Err { url } ->
                            url

                newRequests =
                    Dict.insert
                        url_
                        (Model.Discovery <| Done result)
                        model.requests
            in
            ( { model | requests = newRequests }, Cmd.none )

        Msg.Addition result ->
            let
                url =
                    case result of
                        Ok { feed } ->
                            Feed.url feed

                        Err { candidate } ->
                            candidate.url

                newRequests =
                    Dict.insert
                        url
                        (Model.Addition <| Done result)
                        model.requests
            in
            ( { model | requests = newRequests }, Cmd.none )
