module Feeds.Msg exposing (Msg(..))

import Api
import Feeds.Addition as Addition
import Feeds.Discovery as Discovery
import Feeds.Removal as Removal
import Feeds.Model exposing (..)
import Http
import Types.Feed exposing (..)


type Msg
    = SetVisibility Visibility
    | ToggleOptions
    | SetDiscoveryUrl String
    | DiscoverFeeds String
    | AddFeed Candidate
    | RemoveResponse String
    | ToggleFeed Feed
    | RemoveFeed Feed
    | MarkAsRead Entry
    | PatchEntry (Result Http.Error Entry)
    | Discovery (Result Discovery.Error Discovery.Success)
    | Addition (Result Addition.Error Addition.Success)
    | Removal (Result Removal.Error Removal.Success)
