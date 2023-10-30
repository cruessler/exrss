module Feeds.Options.Removal exposing (requestFieldset)

import Dict exposing (Dict)
import Feeds.Model exposing (..)
import Feeds.Msg exposing (..)
import Feeds.Removal as Removal exposing (Removal)
import Html as H exposing (Html)
import Html.Attributes as A
import Html.Events as E
import Request exposing (..)
import Types.Feed as Feed exposing (..)


close : String -> Html Msg
close url =
    H.button
        [ A.type_ "button"
        , E.onClick <| RemoveResponse url
        ]
        [ H.text "×" ]


inProgressFieldset : Feed -> Html Msg
inProgressFieldset feed =
    H.fieldset [ A.class "border-2 p-2" ]
        [ H.legend [] [ H.text "This feed is being deleted" ]
        , H.p []
            [ H.text "Waiting for answer for "
            , H.code [] [ H.text <| Feed.url feed ]
            , H.text "."
            ]
        ]


successFieldset : Removal.Success -> Html Msg
successFieldset success =
    let
        feed =
            success.feed

        candidate =
            { url = Feed.url feed
            , title = Feed.title feed
            , href = Feed.url feed
            , frequency = Nothing
            }
    in
    H.fieldset [ A.class "border-2 p-2" ]
        [ H.legend [] [ H.text "This feed has been deleted" ]
        , H.code [] [ H.text <| Feed.url feed ]
        , H.text ". You can undo the removal by clicking "
        , H.button
            [ A.class "px-4 py-2 text-sm font-extrabold bg-blue-700 text-white"
            , E.onClick <| AddFeed candidate
            ]
            [ H.text "Undo" ]
        , close <| Feed.url feed
        ]


errorFieldset : Removal.Error -> Html Msg
errorFieldset error =
    H.fieldset [ A.class "border-2 p-2" ]
        [ H.legend [] [ H.text "This feed could not be deleted" ]
        , H.p []
            [ H.text "It was not possible to delete the feed at "
            , H.code [] [ H.text <| Feed.url error.feed ]
            , H.text "."
            ]
        , close <| Feed.url error.feed
        , H.button
            [ E.onClick <| RemoveFeed error.feed ]
            [ H.text "Retry" ]
        ]


requestFieldset : Removal -> Html Msg
requestFieldset request =
    case request of
        InProgress feed ->
            inProgressFieldset feed

        Done (Ok success) ->
            successFieldset success

        Done (Err error) ->
            errorFieldset error
