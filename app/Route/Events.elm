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
    , visibleEvents : List Data.PlaceCal.Events.Event
    , nowTime : Time.Posix
    , viewportWidth : Float
    }


type Msg
    = PaginatorMsg Theme.Paginator.Msg
    | RegionSelectorMsg Theme.RegionSelector.Msg


type alias RouteParams =
    {}


init :
    RouteBuilder.App Data ActionData RouteParams
    -> Shared.Model
    -> ( Model, Effect.Effect Msg )
init app _ =
    ( { filterByDate = Theme.Paginator.None
      , filterByRegion = 0
      , visibleEvents = Data.PlaceCal.Events.eventsWithPartners app.sharedData.events app.sharedData.partners
      , nowTime = Time.millisToPosix 0
      , viewportWidth = 320
      }
    , Effect.batch
        [ Task.perform Theme.Paginator.GetTime Time.now |> Cmd.map fromPaginatorMsg |> Effect.fromCmd
        , Task.perform Theme.Paginator.GotViewport Browser.Dom.getViewport |> Cmd.map fromPaginatorMsg |> Effect.fromCmd
        ]
    )


fromPaginatorMsg : Theme.Paginator.Msg -> Msg
fromPaginatorMsg msg =
    PaginatorMsg msg


fromRegionSelectorMsg : Theme.RegionSelector.Msg -> Msg
fromRegionSelectorMsg msg =
    RegionSelectorMsg msg


update :
    RouteBuilder.App Data ActionData RouteParams
    -> Shared.Model
    -> Msg
    -> Model
    -> ( Model, Effect.Effect Msg )
update app _ msg model =
    case msg of
        PaginatorMsg submsg ->
            case submsg of
                Theme.Paginator.ClickedDay posix ->
                    ( { model
                        | filterByDate = Theme.Paginator.Day posix
                        , visibleEvents =
                            Data.PlaceCal.Events.eventsWithPartners (Data.PlaceCal.Events.eventsFromDate app.sharedData.events posix) app.sharedData.partners
                      }
                    , Effect.none
                    )

                Theme.Paginator.ClickedAllPastEvents ->
                    ( { model
                        | filterByDate = Theme.Paginator.Past
                        , visibleEvents = Data.PlaceCal.Events.eventsWithPartners (List.reverse (Data.PlaceCal.Events.onOrBeforeDate app.sharedData.events model.nowTime)) app.sharedData.partners
                      }
                    , Effect.none
                    )

                Theme.Paginator.ClickedAllFutureEvents ->
                    ( { model
                        | filterByDate = Theme.Paginator.Future
                        , visibleEvents = Data.PlaceCal.Events.eventsWithPartners (Data.PlaceCal.Events.afterDate app.sharedData.events model.nowTime) app.sharedData.partners
                      }
                    , Effect.none
                    )

                Theme.Paginator.GetTime newTime ->
                    ( { model
                        | filterByDate = Theme.Paginator.Day newTime
                        , nowTime = newTime
                        , visibleEvents =
                            Data.PlaceCal.Events.eventsWithPartners (Data.PlaceCal.Events.eventsFromDate app.sharedData.events newTime) app.sharedData.partners
                      }
                    , Effect.none
                    )

                Theme.Paginator.ScrollRight ->
                    ( model
                    , Task.attempt (\_ -> Theme.Paginator.NoOp)
                        (Theme.Paginator.scrollPagination Theme.Paginator.Right model.viewportWidth)
                        |> Cmd.map fromPaginatorMsg
                        |> Effect.fromCmd
                    )

                Theme.Paginator.ScrollLeft ->
                    ( model
                    , Task.attempt (\_ -> Theme.Paginator.NoOp)
                        (Theme.Paginator.scrollPagination Theme.Paginator.Left model.viewportWidth)
                        |> Cmd.map fromPaginatorMsg
                        |> Effect.fromCmd
                    )

                Theme.Paginator.GotViewport viewport ->
                    ( { model | viewportWidth = Maybe.withDefault model.viewportWidth (Just viewport.scene.width) }, Effect.none )

                Theme.Paginator.NoOp ->
                    ( model, Effect.none )

        RegionSelectorMsg submsg ->
            case submsg of
                Theme.RegionSelector.ClickedSelector regionId ->
                    ( model, Effect.none )


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
view _ _ model =
    { title = t (PageMetaTitle (t EventsTitle))
    , body =
        [ Theme.PageTemplate.view
            { headerType = Just "pink"
            , title = t EventsTitle
            , bigText = { text = t EventsSummary, node = "h3" }
            , smallText = Nothing
            , innerContent = Just (Theme.Page.Events.viewEvents model)
            , outerContent = Nothing
            }
            |> Html.Styled.map fromPaginatorMsg
            |> Html.Styled.map PagesMsg.fromMsg
        ]
    }
