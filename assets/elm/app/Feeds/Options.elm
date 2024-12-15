module Feeds.Options exposing (view)

import Dict exposing (Dict)
import Feeds.Model as Model exposing (..)
import Feeds.Msg exposing (..)
import Feeds.Options.Addition as Addition
import Feeds.Options.Discovery as Discovery
import Feeds.Options.Removal as Removal
import Html as H exposing (Html)
import Html.Attributes as A
import Html.Events as E


collapsible : Bool -> List (Html Msg) -> Html Msg
collapsible show children =
    if show then
        H.div [] children

    else
        H.div [] []


requests : Dict String Model.Request -> Html Msg
requests =
    Dict.map
        (\_ request ->
            case request of
                Model.Discovery discovery ->
                    Discovery.requestFieldset discovery

                Model.Addition addition ->
                    Addition.requestFieldset
                        { onAdd = AddFeed, onRemove = RemoveResponse }
                        addition

                Model.Removal removal ->
                    Removal.requestFieldset removal
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
            [ A.class "px-4 py-2 text-sm font-extrabold bg-blue-700 text-white"
            , A.type_ "button"
            , E.onClick ToggleOptions
            ]
            [ H.text buttonText ]
        , collapsible
            model.showOptions
            [ Discovery.discoverFeedsFieldset model.discoveryUrl
            , Discovery.discoverFeedFieldset
            , requests model.requests
            ]
        ]
