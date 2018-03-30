module Feeds.Options exposing (view)

import Dict exposing (Dict)
import Feeds.Model as Model exposing (..)
import Feeds.Msg exposing (..)
import Feeds.Options.Addition as Addition
import Feeds.Options.Discovery as Discovery
import Html as H exposing (Html)
import Html.Attributes as A
import Html.Events as E
import Request exposing (..)
import Types.Feed exposing (..)


radio : Visibility -> Visibility -> String -> Html Msg
radio currentVisibility visibility text_ =
    H.div []
        [ H.label
            []
            [ H.input
                [ A.type_ "radio"
                , A.checked (visibility == currentVisibility)
                , E.onClick (SetVisibility visibility)
                ]
                []
            , H.text text_
            ]
        ]


collapsible : Bool -> List (Html Msg) -> Html Msg
collapsible show children =
    if show then
        H.div [] children
    else
        H.div [] []


visibilityFieldset : Visibility -> Html Msg
visibilityFieldset visibility =
    H.fieldset []
        [ H.legend [] [ H.text "Visibility" ]
        , radio visibility ShowAllEntries "Show all entries"
        , radio visibility HideReadEntries "Hide read entries"
        ]


requests : Dict String Model.Request -> Html Msg
requests =
    Dict.map
        (\_ r ->
            case r of
                Model.Discovery d ->
                    Discovery.requestFieldset d

                Model.Addition a ->
                    Addition.requestFieldset a
        )
        >> Dict.values
        >> H.div []


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
                [ A.type_ "button"
                , E.onClick ToggleOptions
                ]
                [ H.text buttonText ]
            , collapsible
                model.showOptions
                [ visibilityFieldset model.visibility
                , Discovery.newFeedFieldset model.discoveryUrl
                , requests model.requests
                ]
            ]
