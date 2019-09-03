module Tests exposing (suite)

import Dict exposing (Dict)
import Expect exposing (Expectation)
import Fuzz exposing (Fuzzer, int, list, string)
import Test exposing (..)
import Types.Feed as Feed exposing (Entry, Feed, Status(..))


entries : Dict Int Entry
entries =
    [ Entry 0 "http://example.com/0" (Just "First title") False Nothing NoChange
    , Entry 1 "http://example.com/1" (Just "Second title") True Nothing NoChange
    ]
        |> List.map (\f -> ( f.id, f ))
        |> Dict.fromList


suite : Test
suite =
    describe "Feed"
        [ test "createWithEntries counts given entries" <|
            \_ ->
                let
                    feed =
                        Feed.createWithEntries 0 "https://example.com" "Title" entries
                in
                Expect.all
                    [ Feed.unreadEntriesCount >> Expect.equal 1
                    , Feed.readEntriesCount >> Expect.equal 1
                    ]
                    feed
        ]
