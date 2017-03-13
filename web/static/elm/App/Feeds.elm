module App.Feeds exposing (..)

import Dict exposing (Dict)
import Json.Decode
import Model.Feed exposing (Feed, Entry, Status(..))
import View.Feed
import Html exposing (Html, h1, ul, li, small, a, text)
import Html.Attributes exposing (class, classList, href, target)
import Html.App as Html
import Html.Events exposing (onClick)


main =
    Html.programWithFlags
        { init = init
        , update = update
        , view = view
        , subscriptions = (\_ -> Sub.none)
        }


type alias Flags =
    Json.Decode.Value


type alias Model =
    { feeds : Dict Int Feed }


type Msg
    = ToggleFeed Int
    | MarkAsRead Int


init : Flags -> ( Model, Cmd Msg )
init flags =
    let
        feeds =
            Json.Decode.decodeValue Model.Feed.decodeFeeds flags
                |> Result.withDefault []
                |> List.map (\f -> ( f.id, f ))
                |> Dict.fromList
    in
        ( { feeds = feeds }, Cmd.none )


toggleFeed : Maybe Feed -> Maybe Feed
toggleFeed =
    Maybe.map (\f -> { f | open = (not f.open) })


markAsRead : Int -> Int -> Feed -> Feed
markAsRead entryId _ feed =
    let
        updateEntry =
            Maybe.map
                (\e ->
                    { e
                        | status = UpdatePending
                        , read = True
                    }
                )

        newEntries =
            Dict.update entryId updateEntry feed.entries
    in
        { feed | entries = newEntries }


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
                    Dict.map (markAsRead id) model.feeds
            in
                ( { model | feeds = newFeeds }, Cmd.none )


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
