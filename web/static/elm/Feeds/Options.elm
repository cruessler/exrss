module Feeds.Options exposing (view)

import Dict exposing (Dict)
import Feeds.Discovery as Discovery exposing (Discovery)
import Feeds.Model exposing (..)
import Feeds.Msg exposing (..)
import Feeds.Options.Addition
import Html as H exposing (Html)
import Html.Attributes as A
import Html.Events as E
import Request exposing (..)
import Types.Feed exposing (..)


radio : Visibility -> Visibility -> String -> Html Msg
radio currentVisibility visibility text' =
    H.div [ A.class "form-check" ]
        [ H.label
            [ A.class "form-check-label" ]
            [ H.input
                [ A.type' "radio"
                , A.class "form-check-input"
                , A.checked (visibility == currentVisibility)
                , E.onClick (SetVisibility visibility)
                ]
                []
            , H.text text'
            ]
        ]


collapsible : Bool -> List (Html Msg) -> Html Msg
collapsible show children =
    H.div
        [ A.classList
            [ ( "collapse", True )
            , ( "show", show )
            ]
        ]
        [ H.div [ A.class "card card-block" ] children ]


visibilityFieldset : Visibility -> Html Msg
visibilityFieldset visibility =
    H.fieldset [ A.class "form-group" ]
        [ H.legend [] [ H.text "Visibility" ]
        , radio visibility ShowAllEntries "Show all entries"
        , radio visibility HideReadEntries "Hide read entries"
        ]


newFeedFieldset : Html Msg
newFeedFieldset =
    H.fieldset [ A.class "form-group" ]
        [ H.legend [] [ H.text "Discover feeds on a site" ]
        , H.label
            [ A.for "feed-url"
            , A.class "form-control-label"
            ]
            [ H.text "Address to discover feeds on" ]
        , H.input
            [ A.id "feed-url"
            , A.type' "url"
            , A.class "form-control"
            , E.onInput SetDiscoveryUrl
            ]
            []
        , H.button
            [ A.class "btn btn-primary btn-sm"
            , E.onClick DiscoverFeeds
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


addableFeed : Candidate -> Html Msg
addableFeed candidate =
    H.li
        []
        [ H.text candidate.title
        , H.p [] [ H.code [] [ H.text candidate.url ] ]
        , H.button
            [ A.type' "button"
            , A.class "btn btn-primary btn-sm"
            , E.onClick <| AddFeed candidate
            ]
            [ H.text "Add" ]
        ]


successFieldset : Discovery.Success -> Html Msg
successFieldset success =
    let
        children =
            List.map addableFeed success.candidates
    in
        H.fieldset [ A.class "form-group" ]
            [ H.legend [] [ H.text "These feeds can be added" ]
            , H.ul [] children
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


discoveryFieldsets : Dict String Discovery -> Html Msg
discoveryFieldsets requests =
    if Dict.isEmpty requests then
        H.text ""
    else
        H.div [] <| List.map requestFieldset <| Dict.values requests


view : Model -> Html Msg
view model =
    let
        buttonText =
            if model.showOptions then
                "Hide options"
            else
                "Show options"
    in
        H.div []
            [ H.button
                [ A.type' "button"
                , A.class "btn btn-primary btn-sm"
                , E.onClick ToggleOptions
                ]
                [ H.text buttonText ]
            , collapsible
                model.showOptions
                [ visibilityFieldset model.visibility
                , newFeedFieldset
                , discoveryFieldsets model.discoveryRequests
                , Feeds.Options.Addition.view model.additionRequests
                ]
            ]
