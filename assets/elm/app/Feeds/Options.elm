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
import Types.Feed as Feed exposing (Feed)


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


additionalInfo : Dict Int Feed -> Html Msg
additionalInfo feeds =
    let
        numberOfEntries =
            Dict.foldl
                (\_ feed acc ->
                    acc + Feed.unreadEntriesCount feed + Feed.readEntriesCount feed
                )
                0
                feeds

        numberOfUnreadEntries =
            Dict.foldl
                (\_ feed acc ->
                    acc + Feed.unreadEntriesCount feed
                )
                0
                feeds

        infoText =
            if numberOfEntries == 1 then
                "1 entry"

            else
                String.fromInt numberOfEntries ++ " entries"

        infoTextUnread =
            if numberOfUnreadEntries == 0 then
                ""

            else
                String.fromInt numberOfUnreadEntries ++ " unread"

        numberOfFeedsWithError =
            Dict.foldl
                (\_ feed acc ->
                    if Feed.hasError feed then
                        acc + 1

                    else
                        acc
                )
                0
                feeds

        infoTextError =
            if numberOfFeedsWithError == 1 then
                "1 feed had errors when it was last updated"

            else if numberOfFeedsWithError > 1 then
                String.fromInt numberOfFeedsWithError ++ " feeds had errors when they were last updated"

            else
                ""
    in
    H.ul [ A.class "my-2" ]
        [ H.li [ A.class "inline-block mr-2" ] [ H.text infoText ]
        , H.li [ A.class "inline-block mr-2" ] [ H.text infoTextUnread ]
        , H.li [ A.class "inline-block mr-2" ] [ H.text infoTextError ]
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
            [ A.class "px-4 py-2 text-sm font-extrabold bg-blue-700 text-white"
            , A.type_ "button"
            , E.onClick ToggleOptions
            ]
            [ H.text buttonText ]
        , additionalInfo model.feeds
        , collapsible
            model.showOptions
            [ Discovery.discoverFeedsFieldset model.discoveryUrl
            , Discovery.discoverFeedFieldset
            , requests model.requests
            ]
        ]
