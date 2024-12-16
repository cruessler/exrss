module Types.Feed exposing
    ( Candidate
    , Entry
    , Feed
    , Frequency
    , decodeCandidate
    , decodeCandidates
    , decodeFeed
    , encodeCandidate
    , id
    , title
    , url
    )

import Dict exposing (Dict)
import Iso8601
import Json.Decode as D exposing (bool, field, int, list, map, nullable, string)
import Json.Decode.Pipeline exposing (optional, required)
import Json.Encode as E
import Time


type Feed
    = Feed
        { id : Int
        , url : String
        , title : String
        , entries : Dict Int Entry
        , open : Bool
        , unreadEntriesCount : Int
        , readEntriesCount : Int
        , hasError : Bool
        , position : Maybe Int
        , lastSuccessfulUpdateAt : Maybe Time.Posix
        }


type alias Entry =
    { id : Int
    , url : String
    , title : Maybe String
    , read : Bool
    , postedAt : Maybe Time.Posix
    }


type alias Frequency =
    { posts : Int
    , seconds : Int
    }


type alias Candidate =
    { url : String
    , title : String
    , href : String
    , frequency : Maybe Frequency
    }


createWithEntries : Int -> String -> String -> Bool -> Maybe Time.Posix -> Dict Int Entry -> Feed
createWithEntries id_ url_ title_ hasError_ lastSuccessfulUpdateAt_ entries_ =
    Feed
        { id = id_
        , url = url_
        , title = title_
        , entries = entries_
        , open = False
        , unreadEntriesCount = numberOfUnreadEntries entries_
        , readEntriesCount = numberOfReadEntries entries_
        , hasError = hasError_
        , position = Nothing
        , lastSuccessfulUpdateAt = lastSuccessfulUpdateAt_
        }


id : Feed -> Int
id (Feed feed) =
    feed.id


url : Feed -> String
url (Feed feed) =
    feed.url


title : Feed -> String
title (Feed feed) =
    feed.title


countEntries : Dict Int Entry -> D.Decoder Feed
countEntries entries_ =
    D.succeed createWithEntries
        |> required "id" int
        |> required "url" string
        |> optional "title" string ""
        |> required "has_error" bool
        |> required "last_successful_update_at" timestampOrNull
        |> D.map (\f -> f entries_)


numberOfUnreadEntries : Dict Int Entry -> Int
numberOfUnreadEntries entries_ =
    Dict.foldl
        (\_ v acc ->
            if v.read then
                acc

            else
                acc + 1
        )
        0
        entries_


numberOfReadEntries : Dict Int Entry -> Int
numberOfReadEntries entries_ =
    Dict.foldl
        (\_ v acc ->
            if v.read then
                acc + 1

            else
                acc
        )
        0
        entries_


{-| This has to be manually kept in sync with `ExRssWeb.Api.V1.FeedController`
as long as there is no automated process.
-}
decodeFeed : D.Decoder Feed
decodeFeed =
    field "entries" decodeEntries
        |> D.andThen countEntries


decodeEntries : D.Decoder (Dict Int Entry)
decodeEntries =
    let
        toDict list =
            List.map (\f -> ( f.id, f )) list
                |> Dict.fromList
    in
    list decodeEntry
        |> map toDict


decodeCandidates : D.Decoder (List Candidate)
decodeCandidates =
    list decodeCandidate


decodeCandidate : D.Decoder Candidate
decodeCandidate =
    D.succeed Candidate
        |> required "url" string
        |> required "title" string
        |> required "href" string
        |> required "frequency" (nullable decodeFrequency)


decodeFrequency : D.Decoder Frequency
decodeFrequency =
    D.succeed Frequency
        |> required "posts" int
        |> required "seconds" int


encodeCandidate : Candidate -> E.Value
encodeCandidate candidate =
    E.object
        [ ( "feed"
          , E.object
                [ ( "title", E.string candidate.title )
                , ( "url", E.string candidate.url )
                ]
          )
        ]


timestampOrNull : D.Decoder (Maybe Time.Posix)
timestampOrNull =
    let
        parseDate : Maybe String -> Maybe Time.Posix
        parseDate =
            Maybe.andThen (Iso8601.toTime >> Result.toMaybe)
    in
    nullable string |> D.map parseDate


decodeEntry : D.Decoder Entry
decodeEntry =
    D.succeed Entry
        |> required "id" int
        |> required "url" string
        |> required "title" (nullable string)
        |> required "read" bool
        |> required "posted_at" timestampOrNull
