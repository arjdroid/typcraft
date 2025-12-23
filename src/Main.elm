module Main exposing (main)

import Browser
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onInput)
import Json.Decode as D
import Json.Encode
import Ports


type alias Model =
    { expression : String
    , userSvg : String
    , goalSvg : String
    , goalExpression : String
    }


type Msg
    = ExpressionChanged String
    | SvgRendered D.Value


goalExpression : String
goalExpression =
    "F_g = (G m_1 m_2) / (r^2)"


init : () -> ( Model, Cmd Msg )
init _ =
    ( { expression = ""
      , userSvg = ""
      , goalSvg = ""
      , goalExpression = goalExpression
      }
    , Ports.renderMath { expression = goalExpression, target = "goal" }
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ExpressionChanged newExpr ->
            ( { model | expression = newExpr }
            , Ports.renderMath { expression = newExpr, target = "user" }
            )

        SvgRendered jsonValue ->
            let
                decoder =
                    D.map2 Tuple.pair
                        (D.field "target" D.string)
                        (D.field "svg" D.string)
            in
            case D.decodeValue decoder jsonValue of
                Ok ( "user", svg ) ->
                    ( { model | userSvg = svg }, Cmd.none )

                Ok ( "goal", svg ) ->
                    ( { model | goalSvg = svg }, Cmd.none )

                _ ->
                    ( model, Cmd.none )


view : Model -> Html Msg
view model =
    div
        [ style "font-family" "system-ui, sans-serif"
        , style "max-width" "800px"
        , style "margin" "2rem auto"
        , style "padding" "1rem"
        ]
        [ h1 [ style "margin-bottom" "1rem" ] [ text "typcraft" ]
        , div [ style "margin-bottom" "1rem" ]
            [ label [ style "display" "block", style "margin-bottom" "0.5rem" ]
                [ text "Typst math expression:" ]
            , input
                [ type_ "text"
                , value model.expression
                , onInput ExpressionChanged
                , style "width" "100%"
                , style "padding" "0.5rem"
                , style "font-size" "1rem"
                , style "font-family" "monospace"
                , style "box-sizing" "border-box"
                ]
                []
            ]
        , div [ style "margin-top" "1rem" ]
            [ label [ style "display" "block", style "margin-bottom" "0.5rem" ]
                [ text "Rendered output:" ]
            , div
                [ style "border" "1px solid #000"
                , style "padding" "1rem"
                , style "min-height" "100px"
                , style "background" "#ffffff"
                , style "display" "flex"
                , style "align-items" "center"
                , style "justify-content" "center"
                , id "svg-output-user"
                ]
                []
            ]
        , div [ style "margin-top" "1rem" ]
            [ label [ style "display" "block", style "margin-bottom" "0.5rem" ]
                [ text "Goal:" ]
            , div
                [ style "border" "1px solid #000"
                , style "padding" "1rem"
                , style "min-height" "100px"
                , style "background" "#ffffff"
                , style "display" "flex"
                , style "align-items" "center"
                , style "justify-content" "center"
                , id "svg-output-goal"
                ]
                []
            ]
        ]


subscriptions : Model -> Sub Msg
subscriptions _ =
    Ports.mathRendered SvgRendered


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }
