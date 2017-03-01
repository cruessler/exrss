module Model.Feed exposing (Feed, Entry)


type alias Feed =
    { id : Int
    , url : String
    , title : String
    , entries : List Entry
    }


type alias Entry =
    { id : Int
    , url : String
    , title : String
    }
