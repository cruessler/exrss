module App.NewFeed exposing (main)

import Api
import Browser
import Feeds.Addition as Addition
import Feeds.Options.Addition
import Feeds.Options.Discovery
import Html as H exposing (Html)
import Html.Attributes as A
import Json.Decode as Decode
import Request exposing (Request(..))
import Types.Feed exposing (Candidate)


type alias Flags =
    { url : String
    , candidate : Decode.Value
    , apiToken : String
    }


type alias Model =
    { url : String
    , candidate : Maybe Candidate
    , apiConfig : Api.Config
    , request : Maybe Request
    }


type Request
    = Addition Addition.Addition


type Msg
    = AddFeed Candidate
    | FeedAdded (Result Addition.Error Addition.Success)
    | RemoveRequest


main : Program Flags Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , view = view
        , subscriptions = \_ -> Sub.none
        }


init : Flags -> ( Model, Cmd Msg )
init flags =
    let
        apiConfig =
            Api.configFromToken flags.apiToken

        result =
            Decode.decodeValue Types.Feed.decodeCandidate flags.candidate
    in
    ( { url = flags.url
      , apiConfig = apiConfig
      , candidate = Result.toMaybe result
      , request = Nothing
      }
    , Cmd.none
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        AddFeed candidate ->
            let
                request =
                    Addition <| Request.InProgress candidate
            in
            ( { model | request = Just request }
            , Addition.post model.apiConfig candidate FeedAdded
            )

        FeedAdded result ->
            let
                request =
                    Addition <| Done result
            in
            ( { model | request = Just request }, Cmd.none )

        RemoveRequest ->
            ( { model | request = Nothing }, Cmd.none )


addFeedFieldset : Model -> Html Msg
addFeedFieldset { url, candidate } =
    case candidate of
        Just c ->
            H.fieldset [ A.class "border-2 p-2" ]
                [ H.legend [] [ H.text "This feed can be added" ]
                , H.ul []
                    [ Feeds.Options.Discovery.addableFeed
                        { onAdd = AddFeed }
                        c
                    ]
                ]

        Nothing ->
            H.fieldset [ A.class "border-2 p-2" ]
                [ H.legend [] [ H.text "No feed found" ]
                , H.p []
                    [ H.text "The page at "
                    , H.code [] [ H.text url ]
                    , H.text " does not contain any feed."
                    ]
                ]


view : Model -> Html Msg
view model =
    H.div []
        [ addFeedFieldset model
        , case model.request of
            Just (Addition addition) ->
                Feeds.Options.Addition.requestFieldset
                    { onAdd = AddFeed, onRemove = always RemoveRequest }
                    addition

            _ ->
                H.text ""
        ]
