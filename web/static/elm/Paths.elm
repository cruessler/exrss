module Paths exposing (candidates, createFeed, entry)

import Http
import Types.Feed exposing (..)


candidates : String -> String
candidates url =
    "/api/v1/feeds/discover?url=" ++ (Http.encodeUri url)


createFeed : String
createFeed =
    "/api/v1/feeds"


entry : Entry -> String
entry entry =
    "/api/v1/entries/" ++ (toString entry.id)
