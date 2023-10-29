module App.Feeds exposing (main)

import Api
import Browser
import Dict exposing (Dict)
import Feeds.Addition as Addition
import Feeds.Discovery as Discovery
import Feeds.Model as Model exposing (FilterBy(..), Model, SortBy(..), Visibility(..))
import Feeds.Msg as Msg exposing (Msg(..))
import Feeds.Removal as Removal
import Feeds.View as View
import Http
import Json.Encode as E
import Paths
import Request exposing (Request(..))
import Set
import String
import Task
import Time
import Types.Feed as Feed exposing (Entry, Feed, Status(..), updateEntry)


main : Program Flags Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , view = View.view
        , subscriptions = \_ -> Sub.none
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
      , visibility = AlwaysShowUnreadEntries
      , filterBy = DontFilter
      , sortBy = SortByNewestUnread
      , feeds = Dict.empty
      , confirmRemoveFeeds = Set.empty
      , showOptions = False
      , discoveryUrl = ""
      , requests = Dict.empty
      , timezone = Time.utc
      }
    , Cmd.batch [ getFeeds apiConfig, Task.perform SetTimezone Time.here ]
    )


getFeeds : Api.Config -> Cmd Msg
getFeeds apiConfig =
    Api.get
        apiConfig
        { url = Paths.feedsOnlyUnreadEntries
        , params = E.null
        , expect = Http.expectJson NewFeeds Feed.decodeFeedsOnlyUnreadEntries
        }


patchEntry : Api.Config -> Entry -> Cmd Msg
patchEntry apiConfig entry =
    Api.patch
        apiConfig
        { url = Paths.entry entry
        , params = Feed.encodeEntry entry
        , expect = Http.expectJson PatchEntry Feed.decodeEntry
        }


markFeedAsRead : Api.Config -> Feed -> Cmd Msg
markFeedAsRead apiConfig feed =
    let
        encodeFeed =
            E.object
                [ ( "feed"
                  , E.object [ ( "read", E.bool True ) ]
                  )
                ]
    in
    Api.patch
        apiConfig
        { url = Paths.feed feed
        , params = encodeFeed
        , expect = Http.expectJson PatchFeed Feed.decodeFeed
        }


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        SetVisibility visibility ->
            ( { model | visibility = visibility }, Cmd.none )

        SetFilterBy filterBy ->
            ( { model | filterBy = filterBy }, Cmd.none )

        SetSortBy sortBy ->
            ( { model | sortBy = sortBy }, Cmd.none )

        ToggleOptions ->
            ( { model | showOptions = not model.showOptions }, Cmd.none )

        SetDiscoveryUrl url ->
            ( { model | discoveryUrl = url }, Cmd.none )

        SetTimezone timezone ->
            ( { model | timezone = timezone }, Cmd.none )

        GetFeeds ->
            ( model, getFeeds model.apiConfig )

        NewFeeds (Ok feeds) ->
            let
                newFeeds =
                    feeds
                        |> List.map (\f -> ( Feed.id f, f ))
                        |> Dict.fromList
            in
            ( { model | feeds = newFeeds }, Cmd.none )

        NewFeeds (Err message) ->
            ( model, Cmd.none )

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

        ConfirmRemoveFeed feed ->
            let
                id =
                    Feed.id feed
            in
            ( { model | confirmRemoveFeeds = Set.insert id model.confirmRemoveFeeds }, Cmd.none )

        CancelRemoveFeed feed ->
            let
                id =
                    Feed.id feed
            in
            ( { model | confirmRemoveFeeds = Set.remove id model.confirmRemoveFeeds }, Cmd.none )

        RemoveFeed feed ->
            let
                newRequests =
                    Dict.insert
                        (Feed.url feed)
                        (Model.Removal <| Request.InProgress feed)
                        model.requests

                id =
                    Feed.id feed
            in
            ( { model
                | requests = newRequests
                , confirmRemoveFeeds = Set.remove id model.confirmRemoveFeeds
              }
            , Removal.delete model.apiConfig feed Msg.Removal
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
                    Dict.insert (Feed.id feed)
                        (Feed.toggle feed)
                        model.feeds
            in
            ( { model | feeds = newFeeds }, Cmd.none )

        MarkAsRead entry ->
            let
                newFeeds =
                    Feed.markAsRead entry model.feeds

                newEntry =
                    Feed.entry entry.id newFeeds

                cmd =
                    newEntry
                        |> Maybe.map (patchEntry model.apiConfig)
                        |> Maybe.withDefault Cmd.none
            in
            ( { model | feeds = newFeeds }, cmd )

        MarkFeedAsRead feed ->
            let
                newEntries =
                    feed
                        |> Feed.entries
                        |> Dict.map
                            (\_ entry -> { entry | read = True, status = UpdatePending })

                newFeed =
                    Feed.updateEntries feed newEntries

                newFeeds =
                    Dict.insert (Feed.id feed) newFeed model.feeds

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
                    Dict.insert (Feed.id newFeed) newFeed model.feeds
            in
            ( { model | feeds = newFeeds }, Cmd.none )

        PatchFeed (Err _) ->
            ( model, Cmd.none )

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

                newFeeds =
                    case result of
                        Ok { feed } ->
                            Dict.insert (Feed.id feed) feed model.feeds

                        _ ->
                            model.feeds
            in
            ( { model | feeds = newFeeds, requests = newRequests }, Cmd.none )

        Msg.Removal result ->
            let
                url =
                    case result of
                        Ok { feed } ->
                            Feed.url feed

                        Err { feed } ->
                            Feed.url feed

                newRequests =
                    Dict.insert
                        url
                        (Model.Removal <| Done result)
                        model.requests

                newFeeds =
                    case result of
                        Ok { feed } ->
                            Dict.remove (Feed.id feed) model.feeds

                        _ ->
                            model.feeds
            in
            ( { model | feeds = newFeeds, requests = newRequests }, Cmd.none )
