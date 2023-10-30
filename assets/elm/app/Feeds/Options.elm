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
import Types.Feed as Feed exposing (Feed)


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
    H.fieldset [ A.class "border-2 p-2" ]
        [ H.legend [] [ H.text "Actions" ]
        , H.button
            [ A.class "px-4 py-2 text-sm font-extrabold bg-blue-700 text-white"
            , A.type_ "button"
            , E.onClick GetFeeds
            ]
            [ H.text "Update feeds" ]
        ]


visibilityRadio : Visibility -> Visibility -> String -> Html Msg
visibilityRadio currentVisibility visibility text =
    radio (SetVisibility visibility) currentVisibility visibility text


visibilityFieldset : Visibility -> Html Msg
visibilityFieldset visibility =
    H.fieldset [ A.class "border-2 p-4" ]
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


filterByRadio : FilterBy -> FilterBy -> String -> Html Msg
filterByRadio currentFilterBy filterBy text =
    radio (SetFilterBy filterBy) currentFilterBy filterBy text


filterByFieldset : FilterBy -> Html Msg
filterByFieldset filterBy =
    H.fieldset [ A.class "border-2 p-4" ]
        [ H.legend [] [ H.text "Filter feeds by" ]
        , filterByRadio filterBy
            DontFilter
            "Don’t filter feeds"
        , filterByRadio filterBy
            FilterByErrorStatus
            "Only show feeds with error"
        ]


sortByRadio : SortBy -> SortBy -> String -> Html Msg
sortByRadio currentSortBy sortBy text =
    radio (SetSortBy sortBy) currentSortBy sortBy text


sortByFieldset : SortBy -> Html Msg
sortByFieldset sortBy =
    H.fieldset [ A.class "border-2 p-4" ]
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


additionalInfo : Dict Int Feed -> Html Msg
additionalInfo feeds =
    let
        numberOfEntries =
            Dict.foldl
                (\_ feed acc ->
                    acc + Feed.unreadEntriesCount feed + Feed.readEntriesCount feed
                )
                0
                feeds

        numberOfUnreadEntries =
            Dict.foldl
                (\_ feed acc ->
                    acc + Feed.unreadEntriesCount feed
                )
                0
                feeds

        infoText =
            if numberOfEntries == 1 then
                "1 entry"

            else
                String.fromInt numberOfEntries ++ " entries"

        infoTextUnread =
            if numberOfUnreadEntries == 0 then
                ""

            else
                String.fromInt numberOfUnreadEntries ++ " unread"

        numberOfFeedsWithError =
            Dict.foldl
                (\_ feed acc ->
                    if Feed.hasError feed then
                        acc + 1

                    else
                        acc
                )
                0
                feeds

        infoTextError =
            if numberOfFeedsWithError == 1 then
                "1 feed had errors when it was last updated"

            else if numberOfFeedsWithError > 1 then
                String.fromInt numberOfFeedsWithError ++ " feeds had errors when they were last updated"

            else
                ""
    in
    H.ul [ A.class "my-2" ]
        [ H.li [ A.class "inline-block mr-2" ] [ H.text infoText ]
        , H.li [ A.class "inline-block mr-2" ] [ H.text infoTextUnread ]
        , H.li [ A.class "inline-block mr-2" ] [ H.text infoTextError ]
        ]


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
            [ A.class "px-4 py-2 text-sm font-extrabold bg-blue-700 text-white"
            , A.type_ "button"
            , E.onClick ToggleOptions
            ]
            [ H.text buttonText ]
        , additionalInfo model.feeds
        , collapsible
            model.showOptions
            [ actionsFieldset
            , visibilityFieldset model.visibility
            , filterByFieldset model.filterBy
            , sortByFieldset model.sortBy
            , Discovery.discoverFeedsFieldset model.discoveryUrl
            , Discovery.discoverFeedFieldset
            , requests model.requests
            ]
        ]
