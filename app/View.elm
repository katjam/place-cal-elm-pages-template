module View exposing (View, fontPreload, map)

import Html.Styled exposing (Html, node)
import Html.Styled.Attributes exposing (attribute, href, rel, src)


type alias View msg =
    { title : String
    , body : List (Html msg)
    }


map : (msg1 -> msg2) -> View msg1 -> View msg2
map fn doc =
    { title = doc.title
    , body = List.map (Html.Styled.map fn) doc.body
    }


fontPreload : Html msg
fontPreload =
    node "link"
        [ rel "stylesheet preload"
        , href "https://use.typekit.net/qwi3qrw.css"
        ]
        []
