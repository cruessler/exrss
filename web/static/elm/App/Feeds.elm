module App.Feeds exposing (main)

import Api
import Dict exposing (Dict)
import Feeds.Discovery as Discovery
import Feeds.Model exposing (..)
import Feeds.Msg exposing (..)
import Feeds.View as View
import Json.Decode as Decode
import Json.Encode as Encode
import Html.App as Html
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
          , discoveryRequests = Dict.empty
          }
        , Cmd.none
        )


toggleFeed : Maybe Feed -> Maybe Feed
toggleFeed =
    Maybe.map (\f -> { f | open = (not f.open) })


getEntry : Int -> Dict Int Feed -> Maybe Entry
getEntry id feeds =
    feeds
        |> Dict.values
        |> List.map (.entries >> Dict.get id)
        |> Maybe.oneOf


updateEntry : Int -> (Maybe Entry -> Maybe Entry) -> Dict Int Feed -> Dict Int Feed
updateEntry id f feeds =
    let
        updateEntry' _ feed =
            { feed | entries = (Dict.update id f feed.entries) }
    in
        Dict.map updateEntry' feeds


patchEntry : Api.Config -> Maybe Entry -> Cmd Msg
patchEntry apiConfig entry =
    let
        task entry =
            entry
                |> Types.Feed.encodeEntry
                |> Api.patch apiConfig (Paths.entry entry)
                |> Api.fromJson (Decode.succeed ()) Types.Feed.decodeEntry
                |> Task.perform PostFail PostSuccess
    in
        Maybe.map task entry
            |> Maybe.withDefault Cmd.none


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        SetVisibility visibility ->
            ( { model | visibility = visibility }, Cmd.none )

        ToggleOptions ->
            ( { model | showOptions = not model.showOptions }, Cmd.none )

        SetDiscoveryUrl url ->
            ( { model | discoveryUrl = url }, Cmd.none )

        DiscoverFeeds ->
            if String.isEmpty model.discoveryUrl then
                ( model, Cmd.none )
            else
                let
                    url =
                        model.discoveryUrl

                    newRequests =
                        Dict.insert
                            url
                            (Request.InProgress url)
                            model.discoveryRequests
                in
                    ( { model | discoveryRequests = newRequests }
                    , Discovery.get model.apiConfig url
                        |> Discovery.perform Discovery
                    )

        ToggleFeed id ->
            let
                newFeeds =
                    Dict.update id toggleFeed model.feeds
            in
                ( { model | feeds = newFeeds }, Cmd.none )

        MarkAsRead id ->
            let
                newFeeds =
                    updateEntry id
                        (Maybe.map
                            (\e -> { e | read = True, status = UpdatePending })
                        )
                        model.feeds

                cmd =
                    newFeeds
                        |> getEntry id
                        |> patchEntry model.apiConfig
            in
                ( { model | feeds = newFeeds }, cmd )

        PostSuccess response ->
            case response of
                Api.Success newEntry ->
                    let
                        newFeeds =
                            updateEntry
                                newEntry.id
                                (Maybe.map (always newEntry))
                                model.feeds
                    in
                        ( { model | feeds = newFeeds }, Cmd.none )

                Api.Error _ ->
                    ( model, Cmd.none )

        PostFail error ->
            ( model, Cmd.none )

        Discovery result ->
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
                        (Done result)
                        model.discoveryRequests
            in
                ( { model | discoveryRequests = newRequests }, Cmd.none )
