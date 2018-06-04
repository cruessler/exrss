module Feeds.Options.Removal exposing (requestFieldset)

import Dict exposing (Dict)
import Feeds.Removal as Removal exposing (Removal)
import Feeds.Model exposing (..)
import Feeds.Msg exposing (..)
import Html as H exposing (Html)
import Html.Attributes as A
import Html.Events as E
import Request exposing (..)
import Types.Feed exposing (..)


close : String -> Html Msg
close url =
    H.button
        [ A.type_ "button"
        , E.onClick <| RemoveResponse url
        ]
        [ H.text "×" ]


inProgressFieldset : Feed -> Html Msg
inProgressFieldset feed =
    H.fieldset []
        [ H.legend [] [ H.text "This feed is being deleted" ]
        , H.p []
            [ H.text "Waiting for answer for "
            , H.code [] [ H.text feed.url ]
            , H.text "."
            ]
        ]


successFieldset : Removal.Success -> Html Msg
successFieldset success =
    let
        feed =
            success.feed

        candidate =
            { url = feed.url
            , title = feed.title
            , href = feed.url
            , frequency = Nothing
            }
    in
        H.fieldset []
            [ H.legend [] [ H.text "This feed has been deleted" ]
            , H.code [] [ H.text feed.url ]
            , H.text ". You can undo the removal by clicking "
            , H.button
                [ E.onClick <| AddFeed candidate ]
                [ H.text "Undo" ]
            , close feed.url
            ]


errorFieldset : Removal.Error -> Html Msg
errorFieldset error =
    H.fieldset []
        [ H.legend [] [ H.text "This feed could not be deleted" ]
        , H.p []
            [ H.text "It was not possible to delete the feed at "
            , H.code [] [ H.text error.feed.url ]
            , H.text "."
            ]
        , close error.feed.url
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
