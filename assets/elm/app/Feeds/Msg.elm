module Feeds.Msg exposing (Msg(..))

import Feeds.Addition as Addition
import Feeds.Discovery as Discovery
import Feeds.Model exposing (..)
import Types.Feed exposing (..)


type Msg
    = ToggleOptions
    | SetDiscoveryUrl String
    | DiscoverFeeds String
    | AddFeed Candidate
    | RemoveResponse String
    | Discovery (Result Discovery.Error Discovery.Success)
    | Addition (Result Addition.Error Addition.Success)
