module Model.Feed exposing (Feed, Entry, decodeFeeds)

import Json.Decode exposing (..)


type alias Feed =
    { id : Int
    , url : String
    , title : String
    , entries : List Entry
    , open : Bool
    }


type alias Entry =
    { id : Int
    , url : String
    , title : String
    }


decodeFeeds : Json.Decode.Decoder (List Feed)
decodeFeeds =
    list decodeFeed


decodeFeed : Json.Decode.Decoder Feed
decodeFeed =
    object5 Feed
        ("id" := int)
        ("url" := string)
        ("title" := string)
        ("entries" := list decodeEntry)
        (succeed False)


decodeEntry : Json.Decode.Decoder Entry
decodeEntry =
    object3 Entry
        ("id" := int)
        ("url" := string)
        ("title" := string)
