module View.Feed exposing (view)

import Dict
import Model.Feed exposing (Feed, Entry, Status(..))
import Html exposing (Html, h2, div, ul, li, a, text)
import Html.Attributes exposing (class, classList, href, target)
import Html.Events exposing (onClick)


entry : (Int -> msg) -> Entry -> Html msg
entry onMsg entry =
    li
        [ classList
            [ ( "entry", True )
            , ( "read", entry.read )
            , ( "update-pending", entry.status == UpdatePending )
            ]
        ]
        [ a
            [ href entry.url, target "_blank", onClick (onMsg entry.id) ]
            [ text entry.title ]
        ]


view : (Int -> msg) -> Feed -> Html msg
view onMsg feed =
    let
        children =
            List.map (entry onMsg) (Dict.values feed.entries)
    in
        ul [ class "feed" ] children
