module Feeds.Options.Discovery exposing
    ( addableFeed
    , requestFieldset
    )

import Feeds.Discovery as Discovery exposing (Discovery)
import Feeds.Msg exposing (Msg(..))
import Html as H exposing (Html)
import Html.Attributes as A
import Html.Events as E
import Request exposing (..)
import Types.Feed exposing (..)


close : String -> Html Msg
close url =
    H.button
        [ A.class "mr-2 px-4 py-2 text-sm font-extrabold bg-blue-700 text-white"
        , A.type_ "button"
        , E.onClick <| RemoveResponse url
        ]
        [ H.text "×" ]


inProgressFieldset : String -> Html Msg
inProgressFieldset url =
    H.fieldset [ A.class "border-2 p-2" ]
        [ H.legend [] [ H.text "This url is being looked up" ]
        , H.p []
            [ H.text "Waiting for answer for "
            , H.code [] [ H.text url ]
            , H.text "."
            ]
        ]


frequencyInfo : Frequency -> Html msg
frequencyInfo frequency =
    let
        formatDuration seconds =
            if seconds < 2 * 86400 then
                (String.fromInt <| round <| toFloat seconds / 3600.0)
                    ++ " hours"

            else
                (String.fromInt <| round <| toFloat seconds / 86400.0)
                    ++ " days"
    in
    H.text <|
        String.fromInt frequency.posts
            ++ " posts in "
            ++ formatDuration frequency.seconds


addableFeed : { onAdd : Candidate -> msg } -> Candidate -> Html msg
addableFeed { onAdd } candidate =
    H.li
        []
        [ H.text candidate.title
        , H.small [ A.class "inline-block ml-6" ]
            [ candidate.frequency
                |> Maybe.map frequencyInfo
                |> Maybe.withDefault
                    (H.text "no information on the frequency of new posts available")
            ]
        , H.p [] [ H.code [] [ H.text candidate.url ] ]
        , H.button
            [ A.class "px-4 py-2 text-sm font-extrabold bg-blue-700 text-white"
            , A.type_ "button"
            , E.onClick <| onAdd candidate
            ]
            [ H.text "Add" ]
        ]


successFieldset : Discovery.Success -> Html Msg
successFieldset success =
    if List.isEmpty success.candidates then
        H.fieldset [ A.class "border-2 p-2" ]
            [ H.legend [] [ H.text "No feeds found" ]
            , H.p []
                [ H.text "The page at "
                , H.code [] [ H.text success.url ]
                , H.text " does not contain any feed."
                ]
            , close success.url
            ]

    else
        let
            children =
                List.map (addableFeed { onAdd = AddFeed }) success.candidates
        in
        H.fieldset [ A.class "border-2 p-2" ]
            [ H.legend [] [ H.text "These feeds can be added" ]
            , H.ul [ A.class "mb-2" ] children
            , close success.url
            ]


errorFieldset : Discovery.Error -> Html Msg
errorFieldset error =
    H.fieldset [ A.class "border-2 p-2" ]
        [ H.legend [] [ H.text "The lookup for a url failed" ]
        , H.p []
            [ H.text "It was not possible to discover feeds on "
            , H.code [] [ H.text error.url ]
            , H.text "."
            ]
        , close error.url
        , H.button
            [ A.class "px-4 py-2 text-sm font-extrabold bg-blue-700 text-white"
            , E.onClick <| DiscoverFeeds error.url
            ]
            [ H.text "Retry" ]
        ]


requestFieldset : Discovery -> Html Msg
requestFieldset request =
    case request of
        InProgress url ->
            inProgressFieldset url

        Done (Ok success) ->
            successFieldset success

        Done (Err error) ->
            errorFieldset error
