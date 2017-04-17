module Paths exposing (entry)

import Types.Feed exposing (Entry)


entry : Entry -> String
entry entry =
    "/api/v1/entries/" ++ (toString entry.id)
