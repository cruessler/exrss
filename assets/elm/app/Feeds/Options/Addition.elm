module Feeds.Options.Addition exposing (requestFieldset)

import Dict exposing (Dict)
import Feeds.Addition as Addition exposing (Addition)
import Feeds.Msg exposing (..)
import Html as H exposing (Html)
import Html.Attributes as A
import Html.Events as E
import Request exposing (..)
import Types.Feed as Feed exposing (..)


type alias Config msg =
    { onAdd : Candidate -> msg
    , onRemove : String -> msg
    }


close : Config msg -> String -> Html msg
close { onRemove } url =
    H.button
        [ A.class "px-4 py-2 text-sm font-extrabold bg-blue-700 text-white"
        , A.type_ "button"
        , E.onClick <| onRemove url
        ]
        [ H.text "×" ]


inProgressFieldset : Candidate -> Html msg
inProgressFieldset candidate =
    H.fieldset [ A.class "border-2 p-2" ]
        [ H.legend [] [ H.text "This feed is being added" ]
        , H.p []
            [ H.text "Waiting for answer for "
            , H.code [] [ H.text candidate.url ]
            , H.text "."
            ]
        ]


successFieldset : Config msg -> Addition.Success -> Html msg
successFieldset config success =
    H.fieldset [ A.class "border-2 p-2" ]
        [ H.legend [] [ H.text "This feed has been added" ]
        , H.code [] [ H.text <| Feed.url success.feed ]
        , close config <| Feed.url success.feed
        ]


errorFieldset : Config msg -> Addition.Error -> Html msg
errorFieldset ({ onAdd } as config) error =
    H.fieldset [ A.class "border-2 p-2" ]
        [ H.legend [] [ H.text "This feed could not be added" ]
        , H.p []
            [ H.text "It was not possible to add the feed at "
            , H.code [] [ H.text error.candidate.url ]
            , H.text "."
            ]
        , close config error.candidate.url
        , H.button
            [ A.class "px-4 py-2 text-sm font-extrabold bg-blue-700 text-white"
            , E.onClick <| onAdd error.candidate
            ]
            [ H.text "Retry" ]
        ]


requestFieldset : Config msg -> Addition -> Html msg
requestFieldset config request =
    case request of
        InProgress candidate ->
            inProgressFieldset candidate

        Done (Ok success) ->
            successFieldset config success

        Done (Err error) ->
            errorFieldset config error
