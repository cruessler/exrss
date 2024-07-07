module Feeds.Icons exposing (arrowTopRightOnSquareSolid, bookmarkSlashSolid)

{-| This module contains icons that come from
<https://jasonliang.js.org/heroicons-for-elm/>, but are not available in
`jasonliang-dev/elm-heroicons` 1.1.0, the version installed by `elm install`.
There are later versions on <https://package.elm-lang.org/>, but those are not
installed by `elm install`.
-}

import Html exposing (Html)
import Svg exposing (..)
import Svg.Attributes exposing (..)


arrowTopRightOnSquareSolid : Html msg
arrowTopRightOnSquareSolid =
    svg [ fill "none", viewBox "0 0 24 24", strokeWidth "1.5", stroke "currentColor" ]
        [ Svg.path
            [ strokeLinecap "round"
            , strokeLinejoin "round"
            , d "M13.5 6H5.25A2.25 2.25 0 0 0 3 8.25v10.5A2.25 2.25 0 0 0 5.25 21h10.5A2.25 2.25 0 0 0 18 18.75V10.5m-10.5 6L21 3m0 0h-5.25M21 3v5.25"
            ]
            []
        ]


bookmarkSlashSolid : Html msg
bookmarkSlashSolid =
    svg [ viewBox "0 0 24 24", fill "currentColor" ]
        [ Svg.path
            [ d "M3.53 2.47a.75.75 0 0 0-1.06 1.06l18 18a.75.75 0 1 0 1.06-1.06l-18-18ZM20.25 5.507v11.561L5.853 2.671c.15-.043.306-.075.467-.094a49.255 49.255 0 0 1 11.36 0c1.497.174 2.57 1.46 2.57 2.93ZM3.75 21V6.932l14.063 14.063L12 18.088l-7.165 3.583A.75.75 0 0 1 3.75 21Z"
            ]
            []
        ]
