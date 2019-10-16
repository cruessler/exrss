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


feed : Feed
feed =
    Feed.createWithEntries 0 "https://example.com" "Title" entries


feeds : Dict Int Feed
feeds =
    [ ( 0, feed ) ]
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
        ]
