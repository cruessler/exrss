module Feeds.Model
    exposing
        ( Model
        , Visibility(..)
        , Request(..)
        )

import Api
import Dict exposing (Dict)
import Feeds.Addition exposing (Addition)
import Feeds.Discovery exposing (Discovery)
import Types.Feed exposing (..)


type Visibility
    = ShowAllEntries
    | HideReadEntries


type Request
    = Discovery Discovery
    | Addition Addition


type alias Model =
    { apiConfig : Api.Config
    , visibility : Visibility
    , feeds : Dict Int Feed
    , showOptions : Bool
    , discoveryUrl : String
    , requests : Dict String Request
    }
