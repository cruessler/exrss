module Feeds.Msg exposing (Msg(..))

import Feeds.Addition as Addition
import Feeds.Discovery as Discovery
import Feeds.Model exposing (..)
import Feeds.Removal as Removal
import Http
import Json.Decode as D
import Time
import Types.Feed exposing (..)


type Msg
    = SetVisibility Visibility
    | SetFilterBy FilterBy
    | SetSortBy SortBy
    | ToggleOptions
    | SetDiscoveryUrl String
    | SetTimezone Time.Zone
    | GetFeeds
    | NewFeeds (Result Http.Error (List Feed))
    | NewFeed (Result D.Error Feed)
    | DiscoverFeeds String
    | AddFeed Candidate
    | RemoveResponse String
    | ToggleFeed Feed
    | ConfirmRemoveFeed Feed
    | CancelRemoveFeed Feed
    | RemoveFeed Feed
    | MarkAsRead Entry
    | MarkFeedAsRead Feed
    | PatchEntry (Result Http.Error Entry)
    | PatchFeed (Result Http.Error Feed)
    | Discovery (Result Discovery.Error Discovery.Success)
    | Addition (Result Addition.Error Addition.Success)
    | Removal (Result Removal.Error Removal.Success)
