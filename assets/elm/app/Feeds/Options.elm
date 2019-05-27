module Feeds.Options exposing (view)

import Dict exposing (Dict)
import Feeds.Model as Model exposing (..)
import Feeds.Msg exposing (..)
import Feeds.Options.Addition as Addition
import Feeds.Options.Discovery as Discovery
import Feeds.Options.Removal as Removal
import Html as H exposing (Html)
import Html.Attributes as A
import Html.Events as E


radio : msg -> a -> a -> String -> Html msg
radio onClick currentValue value text =
    H.div []
        [ H.label
            []
            [ H.input
                [ A.type_ "radio"
                , A.checked (value == currentValue)
                , E.onClick onClick
                ]
                []
            , H.text text
            ]
        ]


collapsible : Bool -> List (Html Msg) -> Html Msg
collapsible show children =
    if show then
        H.div [] children

    else
        H.div [] []


actionsFieldset : Html Msg
actionsFieldset =
    H.fieldset []
        [ H.legend [] [ H.text "Actions" ]
        , H.button [ A.type_ "button", E.onClick GetFeeds ]
            [ H.text "Update feeds" ]
        ]


visibilityRadio : Visibility -> Visibility -> String -> Html Msg
visibilityRadio currentVisibility visibility text =
    radio (SetVisibility visibility) currentVisibility visibility text


visibilityFieldset : Visibility -> Html Msg
visibilityFieldset visibility =
    H.fieldset []
        [ H.legend [] [ H.text "Visibility" ]
        , visibilityRadio visibility
            ShowAllEntries
            "Show all entries"
        , visibilityRadio visibility
            HideReadEntries
            "Hide read entries"
        , visibilityRadio visibility
            AlwaysShowUnreadEntries
            "Smart: Show unread entries if feed is collapsed, show all entries if feed is not collapsed"
        ]


sortByRadio : SortBy -> SortBy -> String -> Html Msg
sortByRadio currentSortBy sortBy text =
    radio (SetSortBy sortBy) currentSortBy sortBy text


sortByFieldset : SortBy -> Html Msg
sortByFieldset sortBy =
    H.fieldset []
        [ H.legend [] [ H.text "Sort feeds by" ]
        , sortByRadio sortBy
            SortByNewest
            "Sort by newest entry"
        , sortByRadio sortBy
            SortByNewestUnread
            "Sort by newest unread entry"
        , H.p [] [ H.text "Feeds with unread entries will always be shown first" ]
        ]


requests : Dict String Model.Request -> Html Msg
requests =
    Dict.map
        (\_ request ->
            case request of
                Model.Discovery discovery ->
                    Discovery.requestFieldset discovery

                Model.Addition addition ->
                    Addition.requestFieldset
                        { onAdd = AddFeed, onRemove = RemoveResponse }
                        addition

                Model.Removal removal ->
                    Removal.requestFieldset removal
        )
        >> Dict.values
        >> H.div []


view : Model -> Html Msg
view model =
    let
        buttonText =
            if model.showOptions then
                "Hide options"

            else
                "Show options"
    in
    H.div []
        [ H.button
            [ A.type_ "button"
            , E.onClick ToggleOptions
            ]
            [ H.text buttonText ]
        , collapsible
            model.showOptions
            [ actionsFieldset
            , visibilityFieldset model.visibility
            , sortByFieldset model.sortBy
            , Discovery.discoverFeedsFieldset model.discoveryUrl
            , Discovery.discoverFeedFieldset
            , requests model.requests
            ]
        ]
