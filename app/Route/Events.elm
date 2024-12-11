module Route.Events exposing (Model, Msg, RouteParams, route, Data, ActionData)

{-|

@docs Model, Msg, RouteParams, route, Data, ActionData

-}

import BackendTask
import Browser.Dom
import Copy.Keys exposing (Key(..))
import Copy.Text exposing (t)
import Data.PlaceCal.Events
import Effect
import FatalError
import Head
import Html.Styled
import PagesMsg
import RouteBuilder
import Shared
import Task
import Theme.Page.Events
import Theme.PageTemplate
import Theme.Paginator
import Theme.RegionSelector
import Time
import UrlPath
import View exposing (View)


type alias Model =
    { filterByDate : Theme.Paginator.Filter
    , filterByRegion : Int
    , nowTime : Time.Posix
    , viewportWidth : Float
    }


type alias Msg =
    Theme.Page.Events.Msg


type alias RouteParams =
    {}


init :
    RouteBuilder.App Data ActionData RouteParams
    -> Shared.Model
    -> ( Model, Effect.Effect Msg )
init app shared =
    ( { filterByDate = Theme.Paginator.None
      , filterByRegion = Maybe.withDefault 0 shared.filterParam
      , nowTime = Time.millisToPosix 0
      , viewportWidth = 320
      }
    , Effect.batch
        [ Task.perform Theme.Paginator.GetTime Time.now |> Cmd.map Theme.Page.Events.fromPaginatorMsg |> Effect.fromCmd
        , Task.perform Theme.Paginator.GotViewport Browser.Dom.getViewport |> Cmd.map Theme.Page.Events.fromPaginatorMsg |> Effect.fromCmd
        ]
    )


update :
    RouteBuilder.App Data ActionData RouteParams
    -> Shared.Model
    -> Msg
    -> Model
    -> ( Model, Effect.Effect Msg )
update app _ msg model =
    case msg of
        Theme.Page.Events.PaginatorMsg submsg ->
            case submsg of
                Theme.Paginator.ClickedDay posix ->
                    ( { model
                        | filterByDate =
                            Theme.Paginator.Day posix
                      }
                    , Effect.none
                    )

                Theme.Paginator.ClickedAllPastEvents ->
                    ( { model
                        | filterByDate = Theme.Paginator.Past
                      }
                    , Effect.none
                    )

                Theme.Paginator.ClickedAllFutureEvents ->
                    ( { model
                        | filterByDate = Theme.Paginator.Future
                      }
                    , Effect.none
                    )

                Theme.Paginator.GetTime newTime ->
                    ( { model
                        | filterByDate = Theme.Paginator.Day newTime
                        , nowTime = newTime
                      }
                    , Effect.none
                    )

                Theme.Paginator.ScrollRight ->
                    ( model
                    , Task.attempt (\_ -> Theme.Paginator.NoOp)
                        (Theme.Paginator.scrollPagination Theme.Paginator.Right model.viewportWidth)
                        |> Cmd.map Theme.Page.Events.fromPaginatorMsg
                        |> Effect.fromCmd
                    )

                Theme.Paginator.ScrollLeft ->
                    ( model
                    , Task.attempt (\_ -> Theme.Paginator.NoOp)
                        (Theme.Paginator.scrollPagination Theme.Paginator.Left model.viewportWidth)
                        |> Cmd.map Theme.Page.Events.fromPaginatorMsg
                        |> Effect.fromCmd
                    )

                Theme.Paginator.GotViewport viewport ->
                    ( { model | viewportWidth = Maybe.withDefault model.viewportWidth (Just viewport.scene.width) }, Effect.none )

                Theme.Paginator.NoOp ->
                    ( model, Effect.none )

        Theme.Page.Events.RegionSelectorMsg submsg ->
            case submsg of
                Theme.RegionSelector.ClickedSelector regionId ->
                    ( { model
                        | filterByRegion = regionId
                      }
                    , Effect.none
                    )


subscriptions : RouteParams -> UrlPath.UrlPath -> Shared.Model -> Model -> Sub Msg
subscriptions _ _ _ _ =
    Sub.none


route : RouteBuilder.StatefulRoute RouteParams Data ActionData Model Msg
route =
    RouteBuilder.single
        { data = data, head = head }
        |> RouteBuilder.buildWithLocalState
            { init = init
            , view = view
            , update = update
            , subscriptions = subscriptions
            }


type alias Data =
    ()


type alias ActionData =
    BackendTask.BackendTask FatalError.FatalError (List RouteParams)


data : BackendTask.BackendTask FatalError.FatalError Data
data =
    BackendTask.succeed ()


head : RouteBuilder.App Data ActionData RouteParams -> List Head.Tag
head _ =
    Theme.PageTemplate.pageMetaTags
        { title = EventsTitle
        , description = EventsMetaDescription
        , imageSrc = Nothing
        }


view :
    RouteBuilder.App Data ActionData RouteParams
    -> Shared.Model
    -> Model
    -> View (PagesMsg.PagesMsg Msg)
view app _ model =
    { title = t (PageMetaTitle (t EventsTitle))
    , body =
        [ Theme.PageTemplate.view
            { headerType = Just "pink"
            , title = t EventsTitle
            , bigText = { text = t EventsSummary, node = "h3" }
            , smallText = Nothing
            , innerContent = Just (Theme.Page.Events.viewEvents (Data.PlaceCal.Events.eventsWithPartners app.sharedData.events app.sharedData.partners) model)
            , outerContent = Nothing
            }
            |> Html.Styled.map PagesMsg.fromMsg
        ]
    }
