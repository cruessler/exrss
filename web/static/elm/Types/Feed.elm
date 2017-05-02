module Types.Feed
    exposing
        ( Feed
        , Entry
        , Status(..)
        , Candidate
        , decodeFeeds
        , decodeEntry
        , decodeCandidates
        , encodeCandidate
        , encodeEntry
        )

import Date
import Dict exposing (Dict)
import Json.Decode as Decode exposing (..)
import Json.Encode as Encode
import Time exposing (Time)


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
    , postedAt : Maybe Time
    , status : Status
    }


type alias Candidate =
    { url : String
    , title : String
    , href : String
    }


decodeFeeds : Decode.Decoder (List Feed)
decodeFeeds =
    list decodeFeed


decodeFeed : Decode.Decoder Feed
decodeFeed =
    map5 Feed
        (field "id" int)
        (field "url" string)
        (field "title" string)
        (field "entries" decodeEntries)
        (succeed False)


decodeEntries : Decode.Decoder (Dict Int Entry)
decodeEntries =
    let
        toDict list =
            List.map (\f -> ( f.id, f )) list
                |> Dict.fromList
    in
        list decodeEntry
            |> map toDict


decodeCandidates : Decode.Decoder (List Candidate)
decodeCandidates =
    list decodeCandidate


decodeCandidate : Decode.Decoder Candidate
decodeCandidate =
    map3 Candidate
        (field "url" string)
        (field "title" string)
        (field "href" string)


encodeCandidate : Candidate -> Encode.Value
encodeCandidate candidate =
    Encode.object
        [ ( "feed"
          , Encode.object
                [ ( "title", Encode.string candidate.title )
                , ( "url", Encode.string candidate.url )
                ]
          )
        ]


encodeEntry : Entry -> Encode.Value
encodeEntry entry =
    Encode.object
        [ ( "entry"
          , Encode.object [ ( "read", Encode.bool entry.read ) ]
          )
        ]


decodePostedAt : Decode.Decoder (Maybe Time)
decodePostedAt =
    let
        parseDate =
            Date.fromString
                >> (Result.map Date.toTime)
                >> Result.toMaybe

        date =
            string |> Decode.map parseDate
    in
        field "posted_at" <| oneOf [ null Nothing, date ]


decodeEntry : Decode.Decoder Entry
decodeEntry =
    map6 Entry
        (field "id" int)
        (field "url" string)
        (field "title" string)
        (field "read" bool)
        decodePostedAt
        (succeed NoChange)
