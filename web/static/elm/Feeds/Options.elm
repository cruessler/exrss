module Feeds.Options exposing (view)

import Feeds.Model exposing (..)
import Feeds.Msg exposing (..)
import Html exposing (Html)
import Html.Attributes as A
import Html.Events as E
import Types.Feed exposing (..)


radio : Visibility -> Visibility -> String -> Html Msg
radio currentVisibility visibility text' =
    Html.div [ A.class "form-check" ]
        [ Html.label
            [ A.class "form-check-label" ]
            [ Html.input
                [ A.type' "radio"
                , A.class "form-check-input"
                , A.checked (visibility == currentVisibility)
                , E.onClick (SetVisibility visibility)
                ]
                []
            , Html.text text'
            ]
        ]


collapsible : Bool -> List (Html Msg) -> Html Msg
collapsible show children =
    Html.div
        [ A.classList
            [ ( "collapse", True )
            , ( "show", show )
            ]
        ]
        [ Html.div [ A.class "card card-block" ] children ]


visibilityFieldset : Visibility -> Html Msg
visibilityFieldset visibility =
    Html.fieldset [ A.class "form-group" ]
        [ Html.legend [] [ Html.text "Visibility" ]
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
        Html.div []
            [ Html.button
                [ A.type' "button"
                , A.class "btn btn-primary btn-sm"
                , E.onClick ToggleOptions
                ]
                [ Html.text buttonText ]
            , collapsible
                model.showOptions
                [ visibilityFieldset model.visibility ]
            ]
