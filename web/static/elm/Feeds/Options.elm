module Feeds.Options exposing (view)

import Dict exposing (Dict)
import Feeds.Discovery as Discovery exposing (Discovery)
import Feeds.Model exposing (..)
import Feeds.Msg exposing (..)
import Feeds.Options.Addition
import Feeds.Options.Discovery
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
                , Feeds.Options.Discovery.view
                    model.discoveryUrl
                    model.discoveryRequests
                , Feeds.Options.Addition.view model.additionRequests
                ]
            ]
