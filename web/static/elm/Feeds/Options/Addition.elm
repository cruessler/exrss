module Feeds.Options.Addition exposing (view)

import Dict exposing (Dict)
import Feeds.Addition as Addition exposing (Addition)
import Feeds.Model exposing (..)
import Feeds.Msg exposing (..)
import Html as H exposing (Html)
import Html.Attributes as A
import Html.Events as E
import Request exposing (..)
import Types.Feed exposing (..)


inProgressFieldset : Candidate -> Html Msg
inProgressFieldset candidate =
    H.fieldset [ A.class "form-group" ]
        [ H.legend [] [ H.text "This feed is being added" ]
        , H.p []
            [ H.text "Waiting for answer for "
            , H.code [] [ H.text candidate.url ]
            , H.text "."
            ]
        ]


successFieldset : Addition.Success -> Html Msg
successFieldset success =
    H.fieldset [ A.class "form-group" ]
        [ H.legend [] [ H.text "This feed has been added" ]
        , H.code [] [ H.text success.candidate.url ]
        ]


errorFieldset : Addition.Error -> Html Msg
errorFieldset error =
    H.fieldset [ A.class "form-group" ]
        [ H.legend [] [ H.text "This feed could not be added" ]
        , H.p []
            [ H.text "It was not possible to add the feed at "
            , H.code [] [ H.text error.candidate.url ]
            , H.text "."
            ]
        , H.button
            [ A.class "btn btn-primary btn-sm"
            , E.onClick <| AddFeed error.candidate
            ]
            [ H.text "Retry" ]
        ]


requestFieldset : Addition -> Html Msg
requestFieldset request =
    case request of
        InProgress candidate ->
            inProgressFieldset candidate

        Done (Ok success) ->
            successFieldset success

        Done (Err error) ->
            errorFieldset error


view : Dict String Addition -> Html Msg
view requests =
    if Dict.isEmpty requests then
        H.text ""
    else
        H.div [] <| List.map requestFieldset <| Dict.values requests
