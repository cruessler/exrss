module View.Feed exposing (view)

import Model.Feed exposing (Feed, Entry)
import Html exposing (Html, h2, div, ul, li, a, text)
import Html.Attributes exposing (href)


entry : Entry -> Html msg
entry entry =
    li [] [ a [ href entry.url ] [ text entry.title ] ]


view : Feed -> Html msg
view feed =
    let
        children =
            List.map entry feed.entries
    in
        div []
            [ h2 [] [ text feed.title ]
            , ul [] children
            ]
