module Types.Feed exposing
    ( Candidate
    , Entry
    , Feed
    , Frequency
    , Status(..)
    , compareByNewestEntry
    , compareByNewestUnreadEntry
    , compareByPostedAt
    , compareByStatus
    , createWithCounts
    , createWithEntries
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
    , entry
    , hasError
    , id
    , lastSuccessfulUpdateAt
    , markAsRead
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
import Json.Decode as D exposing (bool, field, int, list, map, nullable, string)
import Json.Decode.Pipeline exposing (hardcoded, optional, required)
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
        , lastSuccessfulUpdateAt : Maybe Time.Posix
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
        , lastSuccessfulUpdateAt = lastSuccessfulUpdateAt_
        }


createWithCounts : Int -> String -> String -> Dict Int Entry -> Int -> Int -> Feed
createWithCounts id_ url_ title_ entries_ unreadEntriesCount_ readEntriesCount_ =
    Feed
        { id = id_
        , url = url_
        , title = title_
        , entries = entries_
        , open = False
        , unreadEntriesCount = unreadEntriesCount_
        , readEntriesCount = readEntriesCount_
        , hasError = False
        , lastSuccessfulUpdateAt = Nothing
        }


create : Int -> String -> String -> Dict Int Entry -> Bool -> Int -> Int -> Bool -> Maybe Time.Posix -> Feed
create id_ url_ title_ entries_ open_ unreadEntriesCount_ readEntriesCount_ hasError_ lastSuccessfulUpdateAt_ =
    Feed
        { id = id_
        , url = url_
        , title = title_
        , entries = entries_
        , open = open_
        , unreadEntriesCount = unreadEntriesCount_
        , readEntriesCount = readEntriesCount_
        , hasError = hasError_
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


open : Feed -> Bool
open (Feed feed) =
    feed.open


toggle : Feed -> Feed
toggle (Feed feed) =
    Feed { feed | open = not feed.open }


entries : Feed -> Dict Int Entry
entries (Feed feed) =
    feed.entries


entry : Int -> Dict Int Feed -> Maybe Entry
entry entryId =
    Dict.foldl
        (\_ (Feed f) acc ->
            case acc of
                Nothing ->
                    Dict.get entryId f.entries

                e ->
                    e
        )
        Nothing


unreadEntriesCount : Feed -> Int
unreadEntriesCount (Feed feed) =
    feed.unreadEntriesCount


readEntriesCount : Feed -> Int
readEntriesCount (Feed feed) =
    feed.readEntriesCount


lastSuccessfulUpdateAt : Feed -> Maybe Time.Posix
lastSuccessfulUpdateAt (Feed feed) =
    feed.lastSuccessfulUpdateAt


markAsRead : Entry -> Dict Int Feed -> Dict Int Feed
markAsRead e =
    let
        updateFeed _ (Feed feed) =
            let
                oldEntryWasUnread =
                    Dict.get e.id feed.entries
                        |> Maybe.map (.read >> not)
                        |> Maybe.withDefault False

                newEntries =
                    Dict.update
                        e.id
                        (Maybe.map
                            (\e_ -> { e_ | read = True, status = UpdatePending })
                        )
                        feed.entries
            in
            if oldEntryWasUnread then
                Feed
                    { feed
                        | entries = newEntries
                        , unreadEntriesCount = feed.unreadEntriesCount - 1
                        , readEntriesCount = feed.readEntriesCount + 1
                    }

            else
                Feed
                    { feed | entries = newEntries }
    in
    Dict.map updateFeed


hasError : Feed -> Bool
hasError (Feed feed) =
    feed.hasError


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


compareBy : (Entry -> Bool) -> Feed -> Feed -> Order
compareBy filter a b =
    let
        significantEntry : Feed -> Maybe Entry
        significantEntry (Feed feed) =
            feed.entries
                |> Dict.values
                |> List.filter filter
                |> List.sortWith compareByPostedAt
                |> List.reverse
                |> List.head
    in
    case ( significantEntry a, significantEntry b ) of
        ( Just x, Just y ) ->
            compareByPostedAt x y

        ( Just _, Nothing ) ->
            GT

        ( Nothing, Just _ ) ->
            LT

        _ ->
            EQ


compareByNewestUnreadEntry : Feed -> Feed -> Order
compareByNewestUnreadEntry =
    compareBy (\a -> not a.read)


compareByNewestEntry : Feed -> Feed -> Order
compareByNewestEntry =
    compareBy (always True)


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


decodeFeeds : D.Decoder (List Feed)
decodeFeeds =
    list decodeFeed


decodeFeedsOnlyUnreadEntries : D.Decoder (List Feed)
decodeFeedsOnlyUnreadEntries =
    list decodeFeedOnlyUnreadEntries


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


decodeFeedOnlyUnreadEntries : D.Decoder Feed
decodeFeedOnlyUnreadEntries =
    D.succeed create
        |> required "id" int
        |> required "url" string
        |> optional "title" string ""
        |> required "entries" decodeEntries
        |> hardcoded False
        |> required "unread_entries_count" int
        |> required "read_entries_count" int
        |> required "has_error" bool
        |> required "last_successful_update_at" timestampOrNull


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


encodeEntry : Entry -> E.Value
encodeEntry e =
    E.object
        [ ( "entry"
          , E.object [ ( "read", E.bool e.read ) ]
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
        |> hardcoded NoChange
