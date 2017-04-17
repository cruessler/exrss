module Feeds.Msg exposing (Msg(..))

import Api
import Feeds.Model exposing (..)
import Http
import Types.Feed exposing (..)


type Msg
    = SetVisibility Visibility
    | ToggleOptions
    | ToggleFeed Int
    | MarkAsRead Int
    | PostFail Http.Error
    | PostSuccess (Api.Response () Entry)
