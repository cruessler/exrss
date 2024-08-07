module Feeds.View exposing (view)

import DateFormat as F
import Dict
import Feeds.Icons exposing (arrowTopRightOnSquareSolid, bookmarkSlashSolid)
import Feeds.Model exposing (..)
import Feeds.Msg exposing (..)
import Feeds.Options as Options
import Heroicons.Solid exposing (bookmark, checkCircle, trash)
import Html as H exposing (Html)
import Html.Attributes as A
import Html.Events as E
import Set
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
                    [ A.class "size-6"
                    , A.attribute "aria-label" "Mark as read"
                    , E.onClick (MarkAsRead entry)
                    ]
                    [ checkCircle [] ]

        title =
            H.div [ A.class "flex flex-col" ]
                [ H.a
                    [ A.href entry.url
                    , A.target "_blank"
                    , E.onClick (MarkAsRead entry)
                    ]
                    [ entry.title |> Maybe.withDefault "[no title]" |> H.text ]
                , H.span [] [ H.text postedAt ]
                ]

        label =
            "View entry "
                ++ (entry.title
                        |> Maybe.withDefault "n/a"
                   )

        actions =
            H.div [ A.class "md:shrink-0 flex self-start mt-1 ml-auto space-x-4" ]
                [ H.a
                    [ A.href entry.url
                    , A.target "_blank"
                    , A.class "size-6"
                    , A.attribute "aria-label" label
                    , E.onClick (MarkAsRead entry)
                    ]
                    [ arrowTopRightOnSquareSolid ]
                , maybeButton
                ]
    in
    H.li
        [ A.classList
            [ ( "flex flex-col md:flex-row mt-4", True )
            , ( "opacity-50", entry.read )
            , ( "text-gray-300", entry.status == UpdatePending )
            ]
        ]
        [ title
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
    H.ul []
        [ H.li [ A.class "inline-block mr-2" ] [ H.text infoText ]
        , H.li [ A.class "inline-block mr-2" ] [ H.text infoTextUnread ]
        , H.li [ A.class "inline-block mr-2" ] [ H.text infoTextError ]
        , H.li [ A.class "inline-block mr-2" ] [ H.text infoTextLastUpdate ]
        ]


viewEntries : Time.Zone -> List Entry -> Html Msg
viewEntries timezone entries =
    let
        numberOfEntries =
            List.length entries
    in
    if numberOfEntries > 5 then
        let
            head =
                List.take 2 entries
                    |> List.map (viewEntry timezone)

            numberOfEntriesNotShown =
                numberOfEntries - 4

            middle =
                H.li
                    [ A.class "flex flex-col mt-6" ]
                    [ H.text (String.fromInt numberOfEntriesNotShown ++ " entries not shown") ]

            tail =
                List.drop (numberOfEntries - 2) entries
                    |> List.map (viewEntry timezone)
        in
        H.ul [ A.class "mb-6 flex flex-col" ] (List.append head (middle :: tail))

    else
        H.ul [ A.class "mb-6 flex flex-col" ] (List.map (viewEntry timezone) entries)


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
            viewEntries model.timezone entries

        id =
            Feed.id feed

        pinAction =
            if Feed.position feed == Nothing then
                [ H.button
                    [ A.class "size-6"
                    , A.attribute "aria-label" "Pin feed"
                    , E.onClick (PinFeed feed)
                    ]
                    [ bookmark [] ]
                ]

            else
                [ H.button
                    [ A.class "size-6"
                    , A.attribute "aria-label" "Unpin feed"
                    , E.onClick (UnPinFeed feed)
                    ]
                    [ bookmarkSlashSolid
                    ]
                ]

        removeAction =
            if Set.member id model.confirmRemoveFeeds then
                [ H.button [ A.class "px-4 py-2 text-sm font-extrabold bg-blue-700 text-white", E.onClick (RemoveFeed feed) ] [ H.text "Confirm removal" ]
                , H.button [ A.class "px-4 py-2 text-sm font-extrabold bg-blue-700 text-white", E.onClick (CancelRemoveFeed feed) ] [ H.text "Cancel" ]
                ]

            else
                [ H.button
                    [ A.class "size-6"
                    , A.attribute "aria-label" "Remove feed"
                    , E.onClick (ConfirmRemoveFeed feed)
                    ]
                    [ trash [] ]
                ]

        actions =
            H.div [ A.class "md:shrink-0 flex self-start justify-end mt-1 ml-auto space-x-4" ]
                (List.concat
                    [ removeAction
                    , pinAction
                    , [ H.button
                            [ A.class "size-6"
                            , A.attribute "aria-label" "Mark as read"
                            , E.onClick (MarkFeedAsRead feed)
                            ]
                            [ checkCircle [] ]
                      ]
                    ]
                )

        header =
            H.div []
                [ H.h1
                    [ A.class "mb-2 font-bold"
                    , E.onClick (ToggleFeed feed)
                    ]
                    [ H.text <| Feed.title feed ]
                , additionalInfo model.timezone feed
                ]

        children =
            [ H.div [ A.class "flex" ] [ header, actions ], feed_ ]
    in
    H.li [ A.class "flex flex-col mt-4" ] children


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
                |> List.sortWith Feed.compareByPinned
                |> List.map (viewFeed model)
    in
    H.main_ [ A.attribute "role" "main" ]
        [ Options.view model
        , H.ul [] feeds
        ]
