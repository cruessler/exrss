module Feeds.Model exposing
    ( FilterBy(..)
    , Model
    , Request(..)
    , SortBy(..)
    , Visibility(..)
    )

import Api
import Dict exposing (Dict)
import Feeds.Addition exposing (Addition)
import Feeds.Discovery exposing (Discovery)
import Feeds.Removal exposing (Removal)
import Types.Feed exposing (Feed)


type FilterBy
    = DontFilter
    | FilterByErrorStatus


type Visibility
    = ShowAllEntries
    | HideReadEntries
    | AlwaysShowUnreadEntries


type SortBy
    = SortByNewest
    | SortByNewestUnread


type Request
    = Discovery Discovery
    | Addition Addition
    | Removal Removal


type alias Model =
    { apiConfig : Api.Config
    , visibility : Visibility
    , filterBy : FilterBy
    , sortBy : SortBy
    , feeds : Dict Int Feed
    , showOptions : Bool
    , discoveryUrl : String
    , requests : Dict String Request
    }
