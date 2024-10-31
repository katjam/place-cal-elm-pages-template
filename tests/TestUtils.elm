module TestUtils exposing (queryFromStyled, queryFromStyledList)

import Html
import Html.Styled as Styled
import Test.Html.Query as Query


{-| The Test suite expects Html, not Styled.Html.
Converts a body of List Styled.Html to a test query div containing Html.
After that we can use the testing libraries on our views.
-}
queryFromStyled : Styled.Html msg -> Query.Single msg
queryFromStyled styledHtml =
    Styled.toUnstyled styledHtml
        |> Query.fromHtml


queryFromStyledList : List (Styled.Html msg) -> Query.Single msg
queryFromStyledList body =
    Html.div [] (List.map (\item -> Styled.toUnstyled item) body)
        |> Query.fromHtml
