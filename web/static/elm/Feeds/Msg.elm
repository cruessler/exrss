module Feeds.Msg exposing (Msg(..))

import Api
import Feeds.Discovery as Discovery
import Feeds.Model exposing (..)
import Http
import Types.Feed exposing (..)


type Msg
    = SetVisibility Visibility
    | ToggleOptions
    | SetDiscoveryUrl String
    | DiscoverFeeds
    | ToggleFeed Int
    | MarkAsRead Int
    | PostFail Http.Error
    | PostSuccess (Api.Response () Entry)
    | Discovery (Result Discovery.Error Discovery.Success)
