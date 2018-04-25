module Feeds.View exposing (view)

import Dict
import Date
import Date.Format
import Feeds.Model exposing (..)
import Feeds.Msg exposing (..)
import Feeds.Options as Options
import Html as H exposing (Html)
import Html.Attributes as A
import Html.Events as E
import Types.Feed exposing (..)


entry : Entry -> Html Msg
entry entry =
    let
        postedAt =
            entry.postedAt
                |> Maybe.map
                    (Date.fromTime
                        >> Date.Format.format "%B %e, %Y, %k:%M"
                    )
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
                [ H.text entry.title ]
            , H.span [] [ H.text postedAt ]
            , actions
            ]


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
        H.span [] [ H.text infoText ]


feed : Visibility -> Feed -> Html Msg
feed visibility feed =
    let
        compareByPostedAt a b =
            case ( a.postedAt, b.postedAt ) of
                ( Just x, Just y ) ->
                    -- Flipping x and y saves a later call to `List.reverse`.
                    compare y x

                _ ->
                    EQ

        sortedEntries =
            feed.entries
                |> Dict.values
                |> List.sortWith compareByPostedAt

        entries =
            if visibility == HideReadEntries then
                List.filter (not << .read) <| sortedEntries
            else
                sortedEntries

        feed_ =
            if feed.open then
                H.ul [ A.class "feed" ] (List.map entry entries)
            else
                H.text ""

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
            List.map (feed model.visibility) <| Dict.values model.feeds
    in
        H.main_ [ A.attribute "role" "main" ]
            [ Options.view model
            , H.ul [ A.class "feeds" ] feeds
            ]
