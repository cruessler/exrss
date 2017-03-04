module App.Feeds exposing (..)

import Json.Decode
import Model.Feed exposing (Feed)
import View.Feed
import Html exposing (Html, h1, ul, li, small, text)
import Html.Attributes exposing (class)
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
    { feeds : List Feed }


type Msg
    = ToggleFeed Int


init : Flags -> ( Model, Cmd Msg )
init flags =
    let
        feeds =
            Json.Decode.decodeValue Model.Feed.decodeFeeds flags
                |> Result.withDefault []
    in
        ( { feeds = feeds }, Cmd.none )


toggleFeed : Int -> Feed -> Feed
toggleFeed id feed =
    if feed.id == id then
        { feed | open = (not feed.open) }
    else
        feed


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ToggleFeed id ->
            let
                newFeeds =
                    List.map (toggleFeed id) model.feeds
            in
                ( { model | feeds = newFeeds }, Cmd.none )


additionalInfo : Feed -> Html Msg
additionalInfo feed =
    let
        length =
            List.length feed.entries

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
                [ View.Feed.view feed ]
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
            List.map feed model.feeds
    in
        ul [ class "feeds" ] feeds
