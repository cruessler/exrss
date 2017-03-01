module App.Feeds exposing (..)

import Model.Feed exposing (Feed)
import Html exposing (Html, ul, li, text)
import Html.App as Html


main =
    Html.programWithFlags
        { init = init
        , update = update
        , view = view
        , subscriptions = (\_ -> Sub.none)
        }


type alias Flags =
    List Feed


type alias Model =
    { feeds : List Feed }


type alias Msg =
    ()


init : Flags -> ( Model, Cmd Msg )
init flags =
    ( { feeds = flags }, Cmd.none )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    ( model, Cmd.none )


view : Model -> Html Msg
view model =
    let
        feeds =
            List.map (\f -> li [] [ text f.title ]) model.feeds
    in
        ul [] feeds
