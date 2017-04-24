module Feeds.View exposing (view)

import Dict
import Feeds.Model exposing (..)
import Feeds.Msg exposing (..)
import Feeds.Options as Options
import Html as H exposing (Html)
import Html.Attributes as A
import Html.Events as E
import Types.Feed exposing (..)


entry : Entry -> Html Msg
entry entry =
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
            , E.onClick (MarkAsRead entry.id)
            ]
            [ H.text entry.title ]
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
        H.small
            [ A.class "text-muted" ]
            [ H.text infoText ]


feed : Visibility -> Feed -> Html Msg
feed visibility feed =
    let
        entries =
            if visibility == HideReadEntries then
                List.filter (not << .read) <| Dict.values feed.entries
            else
                Dict.values feed.entries

        feed' =
            if feed.open then
                H.ul [ A.class "feed" ] (List.map entry entries)
            else
                H.text ""
    in
        H.li
            [ A.class "feed" ]
            [ H.h1
                [ E.onClick (ToggleFeed feed.id) ]
                [ H.text feed.title
                , additionalInfo feed
                ]
            , feed'
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
