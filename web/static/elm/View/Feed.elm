module View.Feed exposing (view)

import Model.Feed exposing (Feed, Entry)
import Html exposing (Html, h2, div, ul, li, a, text)
import Html.Attributes exposing (class, href)


entry : Entry -> Html msg
entry entry =
    li [ class "entry" ] [ a [ href entry.url ] [ text entry.title ] ]


view : Feed -> Html msg
view feed =
    let
        children =
            List.map entry feed.entries
    in
        ul [ class "feed" ] children
