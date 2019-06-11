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


formatPostedAt : Time.Posix -> String
formatPostedAt =
    F.format [ F.monthNameFull, F.text " ", F.dayOfMonthNumber, F.text ", ", F.yearNumber, F.text ", ", F.hourMilitaryFixed, F.text ":", F.minuteFixed ] Time.utc


viewEntry : Entry -> Html Msg
viewEntry entry =
    let
        postedAt =
            entry.postedAt
                |> Maybe.map formatPostedAt
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


additionalInfo : Feed -> Html Msg
additionalInfo feed =
    let
        numberOfEntries =
            Dict.size feed.entries

        numberOfUnreadEntries =
            Dict.foldl
                (\k v acc ->
                    if v.read then
                        acc

                    else
                        acc + 1
                )
                0
                feed.entries

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
    in
    H.ul [ A.class "additional-info" ]
        [ H.li [] [ H.text infoText ]
        , H.li [] [ H.text infoTextUnread ]
        ]


viewFeed : Visibility -> Feed -> Html Msg
viewFeed visibility feed =
    let
        sortedEntries =
            feed.entries
                |> Dict.values
                |> List.sortWith Feed.compareByPostedAt
                |> List.reverse

        entries =
            case visibility of
                HideReadEntries ->
                    if feed.open then
                        List.filter (not << .read) <| sortedEntries

                    else
                        []

                AlwaysShowUnreadEntries ->
                    if feed.open then
                        sortedEntries

                    else
                        List.filter (not << .read) <| sortedEntries

                ShowAllEntries ->
                    if feed.open then
                        sortedEntries

                    else
                        []

        feed_ =
            H.ul [ A.class "feed" ] (List.map viewEntry entries)

        actions =
            H.div [ A.class "actions" ]
                [ H.button [ E.onClick (RemoveFeed feed) ] [ H.text "Remove" ]
                , H.button [ E.onClick (MarkFeedAsRead feed) ] [ H.text "Mark as read" ]
                ]

        children =
            [ H.h1 [ E.onClick (ToggleFeed feed) ] [ H.text feed.title ]
            , additionalInfo feed
            , actions
            , feed_
            ]
    in
    H.li
        [ A.class "feed" ]
        children


view : Model -> Html Msg
view model =
    let
        feeds =
            model.feeds
                |> Dict.values
                |> List.sortWith Feed.compareByNewestEntry
                |> List.reverse
                |> List.sortWith Feed.compareByStatus
                |> List.map (viewFeed model.visibility)
    in
    H.main_ [ A.attribute "role" "main" ]
        [ Options.view model
        , H.ul [ A.class "feeds" ] feeds
        ]
