module Request exposing (Request(..))


type Request a b c
    = InProgress a
    | Done (Result b c)
