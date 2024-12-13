module Feeds.View exposing (view)

import Feeds.Model exposing (..)
import Feeds.Msg exposing (..)
import Feeds.Options as Options
import Html as H exposing (Html)
import Html.Attributes as A
import Types.Feed exposing (..)


view : Model -> Html Msg
view model =
    H.main_ [ A.attribute "role" "main" ]
        [ Options.view model
        ]
