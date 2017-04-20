module Feeds.Msg exposing (Msg(..))

import Api
import Feeds.Addition as Addition
import Feeds.Discovery as Discovery
import Feeds.Model exposing (..)
import Http
import Types.Feed exposing (..)


type Msg
    = SetVisibility Visibility
    | ToggleOptions
    | SetDiscoveryUrl String
    | DiscoverFeeds
    | AddFeed Candidate
    | ToggleFeed Int
    | MarkAsRead Int
    | PostFail Http.Error
    | PostSuccess (Api.Response () Entry)
    | Discovery (Result Discovery.Error Discovery.Success)
    | Addition (Result Addition.Error Addition.Success)
