module Feeds.Model exposing
    ( Model
    , Request(..)
    )

import Api
import Dict exposing (Dict)
import Feeds.Addition exposing (Addition)
import Feeds.Discovery exposing (Discovery)


type Request
    = Discovery Discovery
    | Addition Addition


type alias Model =
    { apiConfig : Api.Config
    , showOptions : Bool
    , discoveryUrl : String
    , requests : Dict String Request
    }
