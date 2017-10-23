module Feeds.Options.Discovery exposing (view)

import Dict exposing (Dict)
import Feeds.Discovery as Discovery exposing (Discovery)
import Feeds.Model exposing (..)
import Feeds.Msg exposing (..)
import Html as H exposing (Html)
import Html.Attributes as A
import Html.Events as E
import Json.Decode as Decode
import Request exposing (..)
import Types.Feed exposing (..)


close : String -> Html Msg
close url =
    H.button
        [ A.type_ "button"
        , A.class "close"
        , E.onClick <| RemoveResponse url
        ]
        [ H.text "×" ]


onEnter : Msg -> H.Attribute Msg
onEnter msg =
    let
        isEnter key =
            if key == 13 then
                Decode.succeed msg
            else
                Decode.fail "keyCode != 13"
    in
        E.on "keydown" <| Decode.andThen isEnter E.keyCode


newFeedFieldset : String -> Html Msg
newFeedFieldset discoveryUrl =
    H.fieldset [ A.class "form-group" ]
        [ H.legend [] [ H.text "Discover feeds on a site" ]
        , H.label
            [ A.for "feed-url"
            , A.class "form-control-label"
            ]
            [ H.text "Address to discover feeds on" ]
        , H.input
            [ A.id "feed-url"
            , A.type_ "url"
            , A.class "form-control"
            , A.value discoveryUrl
            , E.onInput SetDiscoveryUrl
            , onEnter <| DiscoverFeeds discoveryUrl
            ]
            []
        , H.button
            [ A.class "btn btn-primary btn-sm"
            , E.onClick <| DiscoverFeeds discoveryUrl
            ]
            [ H.text "Discover" ]
        , H.p
            [ A.class "form-text text-muted" ]
            [ H.text "Enter the address of a site that contains one or more feeds. "
            , H.text "Make sure it starts with "
            , H.code [] [ H.text "http://" ]
            , H.text " or "
            , H.code [] [ H.text "https://" ]
            , H.text "."
            ]
        ]


inProgressFieldset : String -> Html Msg
inProgressFieldset url =
    H.fieldset [ A.class "form-group" ]
        [ H.legend [] [ H.text "This url is being looked up" ]
        , H.p []
            [ H.text "Waiting for answer for "
            , H.code [] [ H.text url ]
            , H.text "."
            ]
        ]


frequencyInfo : Frequency -> Html Msg
frequencyInfo frequency =
    let
        formatDuration seconds =
            if seconds < 2 * 86400 then
                (toString <| round <| (toFloat seconds) / 3600.0)
                    ++ " hours"
            else
                (toString <| round <| (toFloat seconds) / 86400.0)
                    ++ " days"
    in
        H.text <|
            (toString frequency.posts)
                ++ " posts in "
                ++ (formatDuration frequency.seconds)


addableFeed : Candidate -> Html Msg
addableFeed candidate =
    H.li
        []
        [ H.text candidate.title
        , H.small [ A.class "frequency-info" ]
            [ candidate.frequency
                |> Maybe.map frequencyInfo
                |> Maybe.withDefault
                    (H.text "no information on the frequency of new posts available")
            ]
        , H.p [] [ H.code [] [ H.text candidate.url ] ]
        , H.button
            [ A.type_ "button"
            , A.class "btn btn-primary btn-sm"
            , E.onClick <| AddFeed candidate
            ]
            [ H.text "Add" ]
        ]


successFieldset : Discovery.Success -> Html Msg
successFieldset success =
    if List.isEmpty success.candidates then
        H.fieldset [ A.class "form-group" ]
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
                List.map addableFeed success.candidates
        in
            H.fieldset [ A.class "form-group" ]
                [ H.legend [] [ H.text "These feeds can be added" ]
                , H.ul [] children
                , close success.url
                ]


errorFieldset : Discovery.Error -> Html Msg
errorFieldset error =
    H.fieldset [ A.class "form-group" ]
        [ H.legend [] [ H.text "The lookup for a url failed" ]
        , H.p []
            [ H.text "It was not possible to discover feeds on "
            , H.code [] [ H.text error.url ]
            , H.text "."
            ]
        , close error.url
        , H.button
            [ A.class "btn btn-primary btn-sm"
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


view : String -> Dict String Discovery -> Html Msg
view discoveryUrl requests =
    let
        requestFieldsets =
            List.map requestFieldset <| Dict.values requests
    in
        if Dict.isEmpty requests then
            newFeedFieldset discoveryUrl
        else
            H.div [] <| (newFeedFieldset discoveryUrl) :: requestFieldsets
