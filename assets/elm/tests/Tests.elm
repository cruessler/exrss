module Tests exposing (suite)

import Dict exposing (Dict)
import Expect exposing (Expectation)
import Fuzz exposing (Fuzzer, int, list, string)
import Test exposing (..)
import Types.Feed as Feed exposing (Entry, Feed, Status(..))


firstEntry : Entry
firstEntry =
    Entry 0 "http://example.com/0" (Just "First title") False Nothing NoChange


entries : Dict Int Entry
entries =
    [ firstEntry
    , Entry 1 "http://example.com/1" (Just "Second title") True Nothing NoChange
    ]
        |> List.map (\f -> ( f.id, f ))
        |> Dict.fromList


firstUnreadEntry : Entry
firstUnreadEntry =
    Entry 0 "http://example.com/0" (Just "First title") False Nothing NoChange


unreadEntries : Dict Int Entry
unreadEntries =
    [ firstUnreadEntry
    , Entry 1 "http://example.com/1" (Just "Second title") False Nothing NoChange
    ]
        |> List.map (\f -> ( f.id, f ))
        |> Dict.fromList


feed : Feed
feed =
    Feed.createWithEntries 0 "https://example.com" "Title" entries


feedWithCounts : Feed
feedWithCounts =
    Feed.createWithCounts 0 "https://example.com" "Title" unreadEntries 2 3


feeds : Dict Int Feed
feeds =
    [ ( 0, feed ), ( 1, feedWithCounts ) ]
        |> Dict.fromList


suite : Test
suite =
    describe "Feed"
        [ test "createWithEntries counts given entries" <|
            \_ ->
                Expect.all
                    [ Feed.unreadEntriesCount >> Expect.equal 1
                    , Feed.readEntriesCount >> Expect.equal 1
                    ]
                    feed
        , test "markAsRead updates counts" <|
            \_ ->
                let
                    newFeeds =
                        Feed.markAsRead firstEntry feeds

                    newFeed =
                        Dict.get 0 newFeeds
                            |> Maybe.withDefault feed
                in
                Expect.all
                    [ Feed.unreadEntriesCount >> Expect.equal 0
                    , Feed.readEntriesCount >> Expect.equal 2
                    ]
                    newFeed
        , test "markAsRead updates counts if feed was created with counts" <|
            \_ ->
                let
                    newFeeds =
                        Feed.markAsRead firstUnreadEntry feeds

                    newFeed =
                        Dict.get 1 newFeeds
                            |> Maybe.withDefault feedWithCounts
                in
                Expect.all
                    [ Feed.unreadEntriesCount >> Expect.equal 1
                    , Feed.readEntriesCount >> Expect.equal 4
                    ]
                    newFeed
        ]
