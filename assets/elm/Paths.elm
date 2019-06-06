module Paths
    exposing
        ( candidates
        , createFeed
        , feeds
        , feedsOnlyUnreadEntries
        , feed
        , entry
        )

import Http
import Types.Feed exposing (..)


candidates : String -> String
candidates url =
    "/api/v1/feeds/discover?url=" ++ (Http.encodeUri url)


createFeed : String
createFeed =
    "/api/v1/feeds"


feeds : String
feeds =
    "/api/v1/feeds/"


feedsOnlyUnreadEntries : String
feedsOnlyUnreadEntries =
    "/api/v1/feeds/only_unread_entries"


feed : Feed -> String
feed feed =
    "/api/v1/feeds/" ++ (toString feed.id)


entry : Entry -> String
entry entry =
    "/api/v1/entries/" ++ (toString entry.id)
