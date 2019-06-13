module Types.Feed exposing
    ( Candidate
    , Entry
    , Feed
    , Frequency
    , Status(..)
    , compareByNewestEntry
    , compareByPostedAt
    , compareByStatus
    , decodeCandidate
    , decodeCandidates
    , decodeEntry
    , decodeFeed
    , decodeFeedOnlyUnreadEntries
    , decodeFeeds
    , decodeFeedsOnlyUnreadEntries
    , encodeCandidate
    , encodeEntry
    , entries
    , id
    , open
    , readEntriesCount
    , title
    , toggle
    , unreadEntriesCount
    , updateEntries
    , updateEntry
    , url
    )

import Dict exposing (Dict)
import Iso8601
import Json.Decode as Decode exposing (..)
import Json.Encode as Encode
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
        }


type Status
    = NoChange
    | UpdatePending


type alias Entry =
    { id : Int
    , url : String
    , title : Maybe String
    , read : Bool
    , postedAt : Maybe Time.Posix
    , status : Status
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


id : Feed -> Int
id (Feed feed) =
    feed.id


url : Feed -> String
url (Feed feed) =
    feed.url


title : Feed -> String
title (Feed feed) =
    feed.title


open : Feed -> Bool
open (Feed feed) =
    feed.open


toggle : Feed -> Feed
toggle (Feed feed) =
    Feed { feed | open = not feed.open }


entries : Feed -> Dict Int Entry
entries (Feed feed) =
    feed.entries


unreadEntriesCount : Feed -> Int
unreadEntriesCount (Feed feed) =
    feed.unreadEntriesCount


readEntriesCount : Feed -> Int
readEntriesCount (Feed feed) =
    feed.readEntriesCount


updateEntry : Int -> (Entry -> Entry) -> Dict Int Feed -> Dict Int Feed
updateEntry id_ f =
    let
        updateEntry_ _ (Feed feed) =
            { feed
                | entries =
                    Dict.update
                        id_
                        (Maybe.map f)
                        feed.entries
            }
                |> Feed
    in
    Dict.map updateEntry_


updateEntries : Feed -> Dict Int Entry -> Feed
updateEntries (Feed feed) newEntries =
    Feed { feed | entries = newEntries }


compareByNewestEntry : Feed -> Feed -> Order
compareByNewestEntry a b =
    let
        flip : Order -> Order
        flip o =
            case o of
                LT ->
                    GT

                EQ ->
                    EQ

                GT ->
                    LT

        newestOf : Feed -> Maybe Entry
        newestOf (Feed feed) =
            feed.entries
                |> Dict.values
                |> List.sortWith (\x y -> compareByPostedAt x y |> flip)
                |> List.head
    in
    case ( newestOf a, newestOf b ) of
        ( Just x, Just y ) ->
            compareByPostedAt x y

        _ ->
            EQ


compareByStatus : Feed -> Feed -> Order
compareByStatus (Feed a) (Feed b) =
    let
        anyUnread : Dict Int Entry -> Bool
        anyUnread =
            Dict.foldl (\_ v acc -> acc || not v.read) False
    in
    case ( anyUnread a.entries, anyUnread b.entries ) of
        ( True, False ) ->
            LT

        ( False, True ) ->
            GT

        _ ->
            EQ


compareByPostedAt : Entry -> Entry -> Order
compareByPostedAt a b =
    case ( a.postedAt, b.postedAt ) of
        ( Just x, Just y ) ->
            compare (Time.posixToMillis x) (Time.posixToMillis y)

        ( Just _, Nothing ) ->
            GT

        ( Nothing, Just _ ) ->
            LT

        _ ->
            EQ


decodeFeeds : Decode.Decoder (List Feed)
decodeFeeds =
    list decodeFeed


decodeFeedsOnlyUnreadEntries : Decode.Decoder (List Feed)
decodeFeedsOnlyUnreadEntries =
    list decodeFeedOnlyUnreadEntries


countEntries : Dict Int Entry -> Decode.Decoder Feed
countEntries entries_ =
    map7 (\a b c d e f g -> Feed { id = a, url = b, title = c, entries = d, open = e, unreadEntriesCount = f, readEntriesCount = g })
        (field "id" int)
        (field "url" string)
        (oneOf [ null "", field "title" string ])
        (succeed entries_)
        (succeed False)
        (succeed <| numberOfUnreadEntries entries_)
        (succeed <| numberOfReadEntries entries_)


numberOfUnreadEntries : Dict Int Entry -> Int
numberOfUnreadEntries entries_ =
    Dict.foldl
        (\k v acc ->
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
        (\k v acc ->
            if v.read then
                acc + 1

            else
                acc
        )
        0
        entries_


decodeFeed : Decode.Decoder Feed
decodeFeed =
    field "entries" decodeEntries
        |> andThen countEntries


decodeFeedOnlyUnreadEntries : Decode.Decoder Feed
decodeFeedOnlyUnreadEntries =
    map7 (\a b c d e f g -> Feed { id = a, url = b, title = c, entries = d, open = e, unreadEntriesCount = f, readEntriesCount = g })
        (field "id" int)
        (field "url" string)
        (oneOf [ null "", field "title" string ])
        (field "entries" decodeEntries)
        (succeed False)
        (field "unread_entries_count" int)
        (field "read_entries_count" int)


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
    map4 Candidate
        (field "url" string)
        (field "title" string)
        (field "href" string)
        (field "frequency" <| nullable decodeFrequency)


decodeFrequency : Decode.Decoder Frequency
decodeFrequency =
    map2 Frequency (field "posts" int) (field "seconds" int)


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


decodePostedAt : Decode.Decoder (Maybe Time.Posix)
decodePostedAt =
    let
        parseDate =
            Iso8601.toTime
                >> Result.toMaybe

        date =
            oneOf [ null Nothing, string |> Decode.map parseDate ]
    in
    field "posted_at" date


decodeEntry : Decode.Decoder Entry
decodeEntry =
    map6 Entry
        (field "id" int)
        (field "url" string)
        (field "title" <| nullable string)
        (field "read" bool)
        decodePostedAt
        (succeed NoChange)
