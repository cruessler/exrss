module Feeds.Model exposing (Model, Visibility(..))

import Api
import Dict exposing (Dict)
import Feeds.Discovery exposing (Discovery)
import Types.Feed exposing (..)


type Visibility
    = ShowAllEntries
    | HideReadEntries


type alias Model =
    { apiConfig : Api.Config
    , visibility : Visibility
    , feeds : Dict Int Feed
    , showOptions : Bool
    , discoveryUrl : String
    , discoveryRequests : Dict String Discovery
    }
