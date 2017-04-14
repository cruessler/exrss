module App.Feeds exposing (..)

import Api
import Dict exposing (Dict)
import Json.Decode
import Model.Feed exposing (Feed, Entry, Status(..))
import View.Feed
import Html exposing (Html, h1, ul, li, small, a, text)
import Html.Attributes exposing (class, classList, href, target, type', checked)
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


type Visibility
    = ShowAllEntries
    | HideReadEntries


type alias Model =
    { apiConfig : Api.Config
    , visibility : Visibility
    , feeds : Dict Int Feed
    , showOptions : Bool
    }


type Msg
    = SetVisibility Visibility
    | ToggleOptions
    | ToggleFeed Int
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
          , visibility = ShowAllEntries
          , feeds = feeds
          , showOptions = True
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
        SetVisibility visibility ->
            ( { model | visibility = visibility }, Cmd.none )

        ToggleOptions ->
            ( { model | showOptions = not model.showOptions }, Cmd.none )

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


feed : Visibility -> Feed -> Html Msg
feed visibility feed =
    let
        entries =
            if visibility == HideReadEntries then
                List.filter (not << .read) <| Dict.values feed.entries
            else
                Dict.values feed.entries

        children =
            if feed.open then
                [ View.Feed.view MarkAsRead entries ]
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


radio : Visibility -> Visibility -> String -> Html Msg
radio currentVisibility visibility text' =
    Html.div [ class "form-check" ]
        [ Html.label
            [ class "form-check-label" ]
            [ Html.input
                [ type' "radio"
                , class "form-check-input"
                , checked (visibility == currentVisibility)
                , onClick (SetVisibility visibility)
                ]
                []
            , text text'
            ]
        ]


collapsible : Bool -> List (Html Msg) -> Html Msg
collapsible show children =
    Html.div
        [ classList
            [ ( "collapse", True )
            , ( "show", show )
            ]
        ]
        [ Html.div [ class "card card-block" ] children ]


visibilityFieldset : Visibility -> Html Msg
visibilityFieldset visibility =
    Html.fieldset [ class "form-group" ]
        [ Html.legend [] [ text "Visibility" ]
        , radio visibility ShowAllEntries "Show all entries"
        , radio visibility HideReadEntries "Hide read entries"
        ]


header : Model -> Html Msg
header model =
    let
        buttonText =
            if model.showOptions then
                "Hide options"
            else
                "Show options"
    in
        Html.div []
            [ Html.button
                [ type' "button"
                , class "btn btn-primary btn-sm"
                , onClick ToggleOptions
                ]
                [ text buttonText ]
            , collapsible
                model.showOptions
                [ visibilityFieldset model.visibility ]
            ]


view : Model -> Html Msg
view model =
    let
        feeds =
            List.map (feed model.visibility) <| Dict.values model.feeds
    in
        Html.div []
            [ header model
            , ul [ class "feeds" ] feeds
            ]
