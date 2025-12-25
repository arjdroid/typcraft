module Main exposing (main)

import Array
import Browser
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onInput)
import Json.Decode as D
import Json.Encode
import Ports
import Random


type alias Equation =
    { name : String
    , typst : String
    }


type alias Model =
    { expression : String
    , userSvg : String
    , goalSvg : String
    , goalEquation : Equation
    }


type Msg
    = ExpressionChanged String
    | SvgRendered D.Value
    | EquationSelected Int


equations : Array.Array Equation
equations =
    Array.fromList
        [ { name = "Newton's Gravitation", typst = "F_g = (G m_1 m_2) / (r^2)" }
        , { name = "Euler's Identity", typst = "e^(i pi) + 1 = 0" }
        , { name = "Pythagorean Theorem", typst = "a^2 + b^2 = c^2" }
        , { name = "Quadratic Formula", typst = "x = (-b plus.minus sqrt(b^2 - 4 a c)) / (2 a)" }
        , { name = "Einstein's Mass-Energy", typst = "E = m c^2" }
        , { name = "Schrödinger Equation", typst = "i hbar (diff Psi) / (diff t) = hat(H) Psi" }
        , { name = "Maxwell's Equations (Gauss)", typst = "nabla dot bold(E) = rho / epsilon_0" }
        , { name = "Euler's Formula", typst = "e^(i theta) = cos theta + i sin theta" }
        , { name = "Binomial Theorem", typst = "(x + y)^n = sum_(k=0)^n binom(n, k) x^(n-k) y^k" }
        , { name = "Fourier Transform", typst = "hat(f)(xi) = integral_(-oo)^oo f(x) e^(-2 pi i x xi) dif x" }
        ]


init : () -> ( Model, Cmd Msg )
init _ =
    ( { expression = ""
      , userSvg = ""
      , goalSvg = ""
      , goalEquation = { name = "", typst = "" }
      }
    , Random.generate EquationSelected (Random.int 0 (Array.length equations - 1))
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

        EquationSelected index ->
            case Array.get index equations of
                Just equation ->
                    ( { model | goalEquation = equation }
                    , Ports.renderMath { expression = equation.typst, target = "goal" }
                    )

                Nothing ->
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
                [ text ("Goal: " ++ model.goalEquation.name) ]
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
        , viewResult model
        ]


viewResult : Model -> Html Msg
viewResult model =
    if String.isEmpty model.userSvg || String.isEmpty model.goalSvg then
        text ""

    else if model.userSvg == model.goalSvg then
        div
            [ style "margin-top" "1rem"
            , style "padding" "0.5rem"
            , style "color" "green"
            , style "font-weight" "bold"
            ]
            [ text "Correct!" ]

    else
        div
            [ style "margin-top" "1rem"
            , style "padding" "0.5rem"
            , style "color" "gray"
            ]
            [ text "Not quite..." ]


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
