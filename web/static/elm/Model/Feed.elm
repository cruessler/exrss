module Model.Feed exposing (Feed, Entry, Status(..), decodeFeeds)

import Dict exposing (Dict)
import Json.Decode exposing (..)


type alias Feed =
    { id : Int
    , url : String
    , title : String
    , entries : Dict Int Entry
    , open : Bool
    }


type Status
    = NoChange
    | UpdatePending


type alias Entry =
    { id : Int
    , url : String
    , title : String
    , read : Bool
    , status : Status
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
        ("entries" := decodeEntries)
        (succeed False)


decodeEntries : Json.Decode.Decoder (Dict Int Entry)
decodeEntries =
    let
        toDict list =
            List.map (\f -> ( f.id, f )) list
                |> Dict.fromList
    in
        list decodeEntry
            |> map toDict


decodeEntry : Json.Decode.Decoder Entry
decodeEntry =
    object5 Entry
        ("id" := int)
        ("url" := string)
        ("title" := string)
        ("read" := bool)
        (succeed NoChange)
