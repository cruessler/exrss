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
    | GetFeeds
    | NewFeeds (Result Http.Error (List Feed))
    | DiscoverFeeds String
    | AddFeed Candidate
    | RemoveResponse String
    | ToggleFeed Feed
    | RemoveFeed Feed
    | MarkAsRead Entry
    | MarkFeedAsRead Feed
    | PatchEntry (Result Http.Error Entry)
    | PatchFeed (Result Http.Error Feed)
    | Discovery (Result Discovery.Error Discovery.Success)
    | Addition (Result Addition.Error Addition.Success)
    | Removal (Result Removal.Error Removal.Success)
