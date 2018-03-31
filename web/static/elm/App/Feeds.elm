module App.Feeds exposing (main)

import Api
import Dict exposing (Dict)
import Feeds.Addition as Addition
import Feeds.Discovery as Discovery
import Feeds.Removal as Removal
import Feeds.Model as Model exposing (..)
import Feeds.Msg as Msg exposing (..)
import Feeds.View as View
import Json.Decode as Decode
import Json.Encode as Encode
import Html
import Http
import Paths
import Request exposing (..)
import String
import Task exposing (Task)
import Types.Feed exposing (..)


main =
    Html.programWithFlags
        { init = init
        , update = update
        , view = View.view
        , subscriptions = (\_ -> Sub.none)
        }


type alias Flags =
    { apiToken : String
    , feeds : Decode.Value
    }


decodeFeeds : Decode.Value -> Dict Int Feed
decodeFeeds value =
    value
        |> Decode.decodeValue Types.Feed.decodeFeeds
        |> Result.withDefault []
        |> List.map (\f -> ( f.id, f ))
        |> Dict.fromList


init : Flags -> ( Model, Cmd Msg )
init flags =
    let
        feeds =
            decodeFeeds flags.feeds
    in
        ( { apiConfig = Api.config flags.apiToken
          , visibility = ShowAllEntries
          , feeds = feeds
          , showOptions = True
          , discoveryUrl = ""
          , requests = Dict.empty
          }
        , Cmd.none
        )


updateEntry : Int -> (Entry -> Entry) -> Dict Int Feed -> Dict Int Feed
updateEntry id f =
    let
        updateEntry_ _ feed =
            { feed
                | entries =
                    Dict.update
                        id
                        (Maybe.map f)
                        feed.entries
            }
    in
        Dict.map updateEntry_


patchEntry : Api.Config -> Entry -> Cmd Msg
patchEntry apiConfig entry =
    Api.patch
        apiConfig
        { url = Paths.entry entry
        , params = Types.Feed.encodeEntry entry
        , decoder = Types.Feed.decodeEntry
        }
        |> Http.send PatchEntry


markFeedAsRead : Api.Config -> Feed -> Cmd Msg
markFeedAsRead apiConfig feed =
    let
        encodeFeed =
            Encode.object
                [ ( "feed"
                  , Encode.object [ ( "read", Encode.bool True ) ]
                  )
                ]
    in
        Api.patch
            apiConfig
            { url = Paths.feed feed
            , params = encodeFeed
            , decoder = Types.Feed.decodeFeed
            }
            |> Http.send PatchFeed


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        SetVisibility visibility ->
            ( { model | visibility = visibility }, Cmd.none )

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
                    , Discovery.get model.apiConfig url
                        |> Task.attempt Msg.Discovery
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
                , Addition.post model.apiConfig candidate
                    |> Task.attempt Msg.Addition
                )

        RemoveFeed feed ->
            let
                newRequests =
                    Dict.insert
                        feed.url
                        (Model.Removal <| Request.InProgress feed)
                        model.requests
            in
                ( { model | requests = newRequests }
                , Removal.delete model.apiConfig feed
                    |> Task.attempt Msg.Removal
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

        ToggleFeed feed ->
            let
                newFeeds =
                    Dict.insert feed.id
                        { feed | open = not feed.open }
                        model.feeds
            in
                ( { model | feeds = newFeeds }, Cmd.none )

        MarkAsRead entry ->
            let
                newEntry =
                    { entry | read = True, status = UpdatePending }

                newFeeds =
                    updateEntry entry.id
                        (always newEntry)
                        model.feeds

                cmd =
                    newEntry
                        |> patchEntry model.apiConfig
            in
                ( { model | feeds = newFeeds }, cmd )

        MarkFeedAsRead feed ->
            let
                newEntries =
                    Dict.map
                        (\_ entry -> { entry | read = True, status = UpdatePending })
                        feed.entries

                newFeeds =
                    Dict.insert feed.id { feed | entries = newEntries } model.feeds

                cmd =
                    feed
                        |> markFeedAsRead model.apiConfig
            in
                ( { model | feeds = newFeeds }, cmd )

        PatchEntry (Ok newEntry) ->
            let
                newFeeds =
                    updateEntry
                        newEntry.id
                        (always newEntry)
                        model.feeds
            in
                ( { model | feeds = newFeeds }, Cmd.none )

        PatchEntry (Err _) ->
            ( model, Cmd.none )

        PatchFeed (Ok newFeed) ->
            let
                newFeeds =
                    Dict.insert newFeed.id newFeed model.feeds
            in
                ( { model | feeds = newFeeds }, Cmd.none )

        PatchFeed (Err _) ->
            ( model, Cmd.none )

        Msg.Discovery result ->
            let
                url =
                    case result of
                        Ok success ->
                            success.url

                        Err error ->
                            error.url

                newRequests =
                    Dict.insert
                        url
                        (Model.Discovery <| Done result)
                        model.requests
            in
                ( { model | requests = newRequests }, Cmd.none )

        Msg.Addition result ->
            let
                url =
                    case result of
                        Ok success ->
                            success.candidate.url

                        Err error ->
                            error.candidate.url

                newRequests =
                    Dict.insert
                        url
                        (Model.Addition <| Done result)
                        model.requests
            in
                ( { model | requests = newRequests }, Cmd.none )

        Msg.Removal result ->
            let
                url =
                    case result of
                        Ok success ->
                            success.feed.url

                        Err error ->
                            error.feed.url

                newRequests =
                    Dict.insert
                        url
                        (Model.Removal <| Done result)
                        model.requests
            in
                ( { model | requests = newRequests }, Cmd.none )
