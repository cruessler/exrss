module App.Feeds exposing (..)

import Api
import Dict exposing (Dict)
import Json.Decode
import Model.Feed exposing (Feed, Entry, Status(..))
import View.Feed
import Html exposing (Html, h1, ul, li, small, a, text)
import Html.Attributes exposing (class, classList, href, target)
import Html.App as Html
import Html.Events exposing (onClick)
import Http
import Paths
import Task exposing (Task)


main =
    Html.programWithFlags
        { init = init
        , update = update
        , view = view
        , subscriptions = (\_ -> Sub.none)
        }


type alias Flags =
    { apiToken : String
    , feeds : Json.Decode.Value
    }


type alias Model =
    { apiConfig : Api.Config
    , feeds : Dict Int Feed
    }


type Msg
    = ToggleFeed Int
    | MarkAsRead Int
    | PostFail Http.Error
    | PostSuccess (Api.Response () Entry)


decodeFeeds : Json.Decode.Value -> Dict Int Feed
decodeFeeds value =
    value
        |> Json.Decode.decodeValue Model.Feed.decodeFeeds
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
          , feeds = feeds
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
                |> Model.Feed.encodeEntry
                |> Api.patch apiConfig (Paths.entry entry)
                |> Api.fromJson (Json.Decode.succeed ()) Model.Feed.decodeEntry
                |> Task.perform PostFail PostSuccess
    in
        Maybe.map task entry
            |> Maybe.withDefault Cmd.none


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
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


additionalInfo : Feed -> Html Msg
additionalInfo feed =
    let
        length =
            Dict.size feed.entries

        infoText =
            if length == 1 then
                "1 entry"
            else
                toString (length) ++ " entries"
    in
        small [ class "text-muted" ] [ text infoText ]


feed : Feed -> Html Msg
feed feed =
    let
        children =
            if feed.open then
                [ View.Feed.view MarkAsRead feed ]
            else
                []
    in
        li
            [ class "feed" ]
            (h1
                [ onClick (ToggleFeed feed.id) ]
                [ text feed.title, additionalInfo feed ]
                :: children
            )


view : Model -> Html Msg
view model =
    let
        feeds =
            List.map feed (Dict.values model.feeds)
    in
        ul [ class "feeds" ] feeds
