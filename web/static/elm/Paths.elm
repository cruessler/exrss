module Paths exposing (candidates, entry)

import Http
import Types.Feed exposing (Entry)


candidates : String -> String
candidates url =
    "/api/v1/feeds/discover?url=" ++ (Http.uriEncode url)


entry : Entry -> String
entry entry =
    "/api/v1/entries/" ++ (toString entry.id)
