module Feeds.View exposing (view)

import Dict
import Feeds.Model exposing (..)
import Feeds.Msg exposing (..)
import Feeds.Options as Options
import Html exposing (Html)
import Html.Attributes as A
import Html.Events as E
import Types.Feed exposing (..)


entry : Entry -> Html Msg
entry entry =
    Html.li
        [ A.classList
            [ ( "entry", True )
            , ( "read", entry.read )
            , ( "update-pending", entry.status == UpdatePending )
            ]
        ]
        [ Html.a
            [ A.href entry.url
            , A.target "_blank"
            , E.onClick (MarkAsRead entry.id)
            ]
            [ Html.text entry.title ]
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
        Html.small
            [ A.class "text-muted" ]
            [ Html.text infoText ]


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
                Html.ul [ A.class "feed" ] (List.map entry entries)
            else
                Html.text ""
    in
        Html.li
            [ A.class "feed" ]
            [ Html.h1
                [ E.onClick (ToggleFeed feed.id) ]
                [ Html.text feed.title
                , additionalInfo feed
                , feed'
                ]
            ]


view : Model -> Html Msg
view model =
    let
        feeds =
            List.map (feed model.visibility) <| Dict.values model.feeds
    in
        Html.div []
            [ Options.view model
            , Html.ul [ A.class "feeds" ] feeds
            ]
