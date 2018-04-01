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
                        >> Date.Format.format "%B %e, %Y, %I:%M:%S %P"
                    )
                |> Maybe.withDefault "unknown"
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
            , H.p [] [ H.text postedAt ]
            , H.button
                [ E.onClick (MarkAsRead entry) ]
                [ H.text "Mark as read" ]
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
        H.small [] [ H.text infoText ]


actions : Feed -> List (Html Msg)
actions feed =
    [ H.button [ E.onClick (RemoveFeed feed) ] [ H.text "Remove" ]
    , H.button [ E.onClick (MarkFeedAsRead feed) ] [ H.text "Mark as read" ]
    ]


feed : Visibility -> Feed -> Html Msg
feed visibility feed =
    let
        entries =
            if visibility == HideReadEntries then
                List.filter (not << .read) <| Dict.values feed.entries
            else
                Dict.values feed.entries

        feed_ =
            if feed.open then
                H.ul [ A.class "feed" ] (List.map entry entries)
            else
                H.text ""
    in
        H.li
            [ A.class "feed" ]
            [ H.h1
                [ E.onClick (ToggleFeed feed) ]
                ([ H.text feed.title
                 , additionalInfo feed
                 ]
                    ++ actions feed
                )
            , feed_
            ]


view : Model -> Html Msg
view model =
    let
        feeds =
            List.map (feed model.visibility) <| Dict.values model.feeds
    in
        H.div []
            [ Options.view model
            , H.ul [ A.class "feeds" ] feeds
            ]
