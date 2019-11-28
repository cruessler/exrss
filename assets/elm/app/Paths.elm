module Paths exposing
    ( candidates
    , createFeed
    , entry
    , feed
    , feeds
    , feedsOnlyUnreadEntries
    )

import Url.Builder exposing (absolute, string)
import Types.Feed as Feed exposing (..)


candidates : String -> String
candidates url =
    absolute [ "api", "v1", "feeds", "discover" ] [ string "url" url ]


createFeed : String
createFeed =
    absolute [ "api", "v1", "feeds" ] []


feeds : String
feeds =
    absolute [ "api", "v1", "feeds" ] []


feedsOnlyUnreadEntries : String
feedsOnlyUnreadEntries =
    absolute [ "api", "v1", "feeds", "only_unread_entries"] []


feed : Feed -> String
feed feed_ =
    absolute [ "api", "v1", "feeds", String.fromInt <| Feed.id feed_ ] []


entry : Entry -> String
entry entry_ =
    absolute [ "api", "v1", "entries", String.fromInt entry_.id ] []
