module Feeds.View exposing (view)

import DateFormat as F
import Dict
import Feeds.Model exposing (..)
import Feeds.Msg exposing (..)
import Feeds.Options as Options
import Html as H exposing (Html)
import Html.Attributes as A
import Html.Events as E
import Time
import Types.Feed as Feed exposing (..)


formatTimestamp : Time.Zone -> Time.Posix -> String
formatTimestamp timezone =
    let
        suffix =
            if timezone == Time.utc then
                F.text " (UTC)"

            else
                F.text ""
    in
    F.format [ F.monthNameFull, F.text " ", F.dayOfMonthNumber, F.text ", ", F.yearNumber, F.text ", ", F.hourMilitaryFixed, F.text ":", F.minuteFixed, suffix ] timezone


viewEntry : Time.Zone -> Entry -> Html Msg
viewEntry timezone entry =
    let
        postedAt =
            entry.postedAt
                |> Maybe.map (formatTimestamp timezone)
                |> Maybe.withDefault "unknown"

        maybeButton =
            if entry.read then
                H.text ""

            else
                H.button
                    [ E.onClick (MarkAsRead entry) ]
                    [ H.text "Mark as read" ]

        actions =
            H.div [ A.class "actions" ]
                [ H.a
                    [ A.href entry.url
                    , A.target "_blank"
                    , A.class "button"
                    , E.onClick (MarkAsRead entry)
                    ]
                    [ H.text "View" ]
                , maybeButton
                ]
    in
    H.li
        [ A.classList
            [ ( "entry", True )
            , ( "read", entry.read )
            , ( "update-pending", entry.status == UpdatePending )
            ]
        ]
        [ H.a
            [ A.href entry.url
            , A.target "_blank"
            , E.onClick (MarkAsRead entry)
            ]
            [ entry.title |> Maybe.withDefault "[no title]" |> H.text ]
        , H.span [] [ H.text postedAt ]
        , actions
        ]


additionalInfo : Time.Zone -> Feed -> Html Msg
additionalInfo timezone feed =
    let
        numberOfEntries =
            Feed.unreadEntriesCount feed + Feed.readEntriesCount feed

        numberOfUnreadEntries =
            Feed.unreadEntriesCount feed

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

        infoTextError =
            if Feed.hasError feed then
                "there were errors when the feed was last updated"

            else
                ""

        infoTextLastUpdate =
            case Feed.lastSuccessfulUpdateAt feed of
                Just updateAt ->
                    "last successful update at " ++ formatTimestamp timezone updateAt

                Nothing ->
                    "last successful update at n/a"
    in
    H.ul [ A.class "additional-info" ]
        [ H.li [] [ H.text infoText ]
        , H.li [] [ H.text infoTextUnread ]
        , H.li [] [ H.text infoTextError ]
        , H.li [] [ H.text infoTextLastUpdate ]
        ]


viewFeed : Model -> Feed -> Html Msg
viewFeed model feed =
    let
        sortedEntries =
            feed
                |> Feed.entries
                |> Dict.values
                |> List.sortWith Feed.compareByPostedAt
                |> List.reverse

        entries =
            case model.visibility of
                HideReadEntries ->
                    if Feed.open feed then
                        List.filter (not << .read) <| sortedEntries

                    else
                        []

                AlwaysShowUnreadEntries ->
                    if Feed.open feed then
                        sortedEntries

                    else
                        List.filter (not << .read) <| sortedEntries

                ShowAllEntries ->
                    if Feed.open feed then
                        sortedEntries

                    else
                        []

        feed_ =
            H.ul [ A.class "feed" ] (List.map (viewEntry model.timezone) entries)

        actions =
            H.div [ A.class "actions" ]
                [ H.button [ E.onClick (RemoveFeed feed) ] [ H.text "Remove" ]
                , H.button [ E.onClick (MarkFeedAsRead feed) ] [ H.text "Mark as read" ]
                ]

        children =
            [ H.h1 [ E.onClick (ToggleFeed feed) ] [ H.text <| Feed.title feed ]
            , additionalInfo model.timezone feed
            , actions
            , feed_
            ]
    in
    H.li
        [ A.class "feed" ]
        children


filterBy : FilterBy -> List Feed -> List Feed
filterBy filterBy_ feeds =
    case filterBy_ of
        DontFilter ->
            feeds

        FilterByErrorStatus ->
            List.filter (\feed -> Feed.hasError feed) feeds


sortWith : SortBy -> (Feed -> Feed -> Order)
sortWith sortBy =
    case sortBy of
        SortByNewest ->
            Feed.compareByNewestEntry

        SortByNewestUnread ->
            Feed.compareByNewestUnreadEntry


view : Model -> Html Msg
view model =
    let
        feeds =
            model.feeds
                |> Dict.values
                |> filterBy model.filterBy
                |> List.sortWith (sortWith model.sortBy)
                |> List.reverse
                |> List.sortWith Feed.compareByStatus
                |> List.map (viewFeed model)
    in
    H.main_ [ A.attribute "role" "main" ]
        [ Options.view model
        , H.ul [ A.class "feeds" ] feeds
        ]
