module Main exposing (main)

import Array
import Browser
import Browser.Dom
import Browser.Events
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Json.Decode as D
import Ports
import Random
import Task


type alias Equation =
    { name : String
    , typst : String
    }


type Page
    = Landing
    | App


type alias Model =
    { expression : String
    , userSvg : String
    , goalSvg : String
    , goalEquation : Equation
    , page : Page
    }


type Msg
    = ExpressionChanged String
    | SvgRendered D.Value
    | EquationSelected Int
    | NewEquation
    | StartApp
    | KeyDown String Bool Bool
    | NoOp


equations : Array.Array Equation
equations =
    Array.fromList
        [ { name = "Newton's Gravitaty Equation", typst = "F_g = (G m_1 m_2) / (r^2)" }
        , { name = "Euler's Identity", typst = "e^(i pi) + 1 = 0" }
        , { name = "The Pythagorean Theorem", typst = "a^2 + b^2 = c^2" }
        , { name = "The Quadratic Formula", typst = "x = (-b plus.minus sqrt(b^2 - 4 a c)) / (2 a)" }
        , { name = "Einstein's Mass-Energy", typst = "E = m c^2" }
        , { name = "Maxwell's Equations (Gauss)", typst = "nabla dot bold(E) = rho / epsilon_0" }
        , { name = "Euler's Formula", typst = "e^(i theta) = cos theta + i sin theta" }
        , { name = "The Binomial Theorem", typst = "(x + y)^n = sum_(k=0)^n binom(n, k) x^(n-k) y^k" }
        , { name = "The Fourier Transform", typst = "hat(f)(xi) = integral_(-oo)^oo f(x) e^(-2 pi i x xi) dif x" }
        , { name = "Standard Deviation", typst = "sigma = sqrt(1/N sum_(i=1)^N (x_i - mu)^2), \"where\" mu eq.triple 1/N sum_(i=1)^N x_i" }
        , { name = "Cauchy-Schwarz Inequality", typst = "|chevron.l bold(\"u\"), bold(\"v\") chevron.r|^2 <= chevron.l bold(\"u\"), bold(\"u\") chevron.r dot chevron.l bold(\"v\"), bold(\"v\") chevron.r" }
        , { name = "Calculus", typst = "frac(dif f, dif t) = limits(lim)_(h arrow 0) frac(f(t + h) - f(t), h)" }
        , { name = "Time dependent Schrödinger equation", typst = "i planck frac(dif, dif t) | Psi(t) chevron.r = hat(H) | Psi(t) chevron.r" }
        , { name = "Black-Scholes Equation", typst = "frac(1, 2) sigma^2 S^2 frac(partial^2 V, partial S^2) + r S frac(partial V, partial S) + frac(partial V, partial t) - r V = 0" }
        , { name = "Bayes' Theorem", typst = "P(A|B) = frac(P(B|A) dot P(A), P(B))" }
        ]


init : () -> ( Model, Cmd Msg )
init _ =
    ( { expression = ""
      , userSvg = ""
      , goalSvg = ""
      , goalEquation = { name = "", typst = "" }
      , page = Landing
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

        NewEquation ->
            ( { model | expression = "", userSvg = "" }
            , Cmd.batch
                [ Random.generate EquationSelected (Random.int 0 (Array.length equations - 1))
                , Ports.renderMath { expression = "", target = "user" }
                ]
            )

        StartApp ->
            ( { model | page = App }
            , Task.attempt (\_ -> NoOp) (Browser.Dom.focus "typst-input")
            )

        KeyDown key ctrl meta ->
            if model.page == Landing && key == "Enter" then
                update StartApp model

            else if (ctrl || meta) && key == "Enter" then
                update NewEquation model

            else
                ( model, Cmd.none )

        NoOp ->
            ( model, Cmd.none )


isCorrect : Model -> Bool
isCorrect model =
    not (String.isEmpty model.userSvg)
        && not (String.isEmpty model.goalSvg)
        && model.userSvg
        == model.goalSvg


onKeyDown : Html.Attribute Msg
onKeyDown =
    Html.Events.on "keydown"
        (D.map3 KeyDown
            (D.field "key" D.string)
            (D.field "ctrlKey" D.bool)
            (D.field "metaKey" D.bool)
        )


view : Model -> Html Msg
view model =
    div []
        [ viewLanding model
        , viewApp model
        ]


viewLanding : Model -> Html Msg
viewLanding model =
    let
        overlayClass =
            if model.page == Landing then
                "landing-overlay"

            else
                "landing-overlay hidden"
    in
    div [ class overlayClass ]
        [ h1
            [ style "font-size" "3rem"
            , style "font-weight" "500"
            , style "margin" "0 0 0.5rem 0"
            , style "color" "var(--text-primary)"
            ]
            [ text "typcraft" ]
        , p
            [ style "font-size" "1.1rem"
            , style "color" "var(--text-secondary)"
            , style "margin" "0 0 2rem 0"
            ]
            [ text "Use typst right in your browser!" ]
        , button
            [ class "btn-primary"
            , onClick StartApp
            , style "padding" "0.75rem 2rem"
            , style "font-size" "1rem"
            , style "display" "flex"
            , style "flex-direction" "column"
            , style "align-items" "center"
            ]
            [ text "Start"
            ]
        ]


viewFooter : Html Msg
viewFooter =
    div
        [ style "position" "fixed"
        , style "bottom" "1rem"
        , style "left" "1.5rem"
        , style "right" "1.5rem"
        , style "display" "flex"
        , style "justify-content" "space-between"
        , style "align-items" "center"
        , style "pointer-events" "none"
        ]
        [ span
            [ style "font-size" "2rem"
            , style "font-weight" "500"
            , style "color" "var(--text-primary)"
            , style "opacity" "0.15"
            ]
            [ text "typcraft" ]
        , span
            [ style "font-size" "1.1rem"
            , style "font-weight" "300"
            , style "color" "var(--text-primary)"
            , style "opacity" "0.35"
            ]
            [ text "Stuck? Try these resources:" ]
        , a
            [ href "https://typst.app/docs/reference/"
            , target "_blank"
            , class "github-link"
            , style "pointer-events" "auto"
            , style "color" "var(--text-muted)"
            , style "text-decoration" "none"
            , style "font-size" "0.85rem"
            ]
            [ text "typst official reference manual" ]
        , a
            [ href "https://detypify.quarticcat.com/"
            , target "_blank"
            , class "github-link"
            , style "pointer-events" "auto"
            , style "color" "var(--text-muted)"
            , style "text-decoration" "none"
            , style "font-size" "0.85rem"
            ]
            [ text "typst symbol fuzzy search" ]
        , a
            [ href "https://github.com/arjdroid/typcraft"
            , target "_blank"
            , class "github-link"
            , style "pointer-events" "auto"
            , style "color" "var(--text-muted)"
            , style "text-decoration" "none"
            , style "font-size" "0.85rem"
            ]
            [ text "fork me on GitHub!" ]
        ]


viewSvgBox : String -> String -> Html Msg
viewSvgBox boxId borderColor =
    div
        [ id boxId
        , class "svg-output-box"
        , style "height" "120px"
        , style "background" "var(--bg-surface)"
        , style "border-radius" "8px"
        , style "border" ("1px solid " ++ borderColor)
        , style "display" "flex"
        , style "align-items" "center"
        , style "justify-content" "center"
        , style "padding" "1rem"
        ]
        []


viewFeedback : Model -> Html Msg
viewFeedback model =
    div
        [ style "height" "3rem"
        , style "display" "flex"
        , style "align-items" "center"
        ]
        [ if String.isEmpty model.userSvg then
            text ""

          else if isCorrect model then
            span
                [ style "color" "var(--border-correct)"
                , style "font-weight" "500"
                ]
                [ text "Correct!" ]

          else
            span
                [ style "color" "var(--text-muted)"
                ]
                [ text "Not quite..." ]
        ]


viewLabel : String -> Html Msg
viewLabel labelText =
    label
        [ style "display" "block"
        , style "margin-bottom" "0.5rem"
        , style "font-size" "1rem"
        , style "text-transform" "capitalize"
        , style "letter-spacing" "0.05em"
        , style "color" "var(--text-muted)"
        ]
        [ text labelText ]


viewApp : Model -> Html Msg
viewApp model =
    let
        userBorderColor =
            if isCorrect model then
                "var(--border-correct)"

            else
                "var(--border-color)"
    in
    div
        [ style "max-width" "700px"
        , style "margin" "3rem auto"
        , style "padding" "0 1.5rem"
        ]
        [ div [ style "margin-bottom" "1.5rem" ]
            [ viewLabel ("Goal: typeset " ++ model.goalEquation.name)
            , viewSvgBox "svg-output-goal" "var(--border-color)"
            ]
        , div [ style "margin-bottom" "1.5rem" ]
            [ viewLabel "Your output"
            , viewSvgBox "svg-output-user" userBorderColor
            ]
        , div [ style "margin-bottom" "1rem" ]
            [ viewLabel "Your typst code"
            , input
                [ type_ "text"
                , id "typst-input"
                , value model.expression
                , onInput ExpressionChanged
                , onKeyDown
                , Html.Attributes.autofocus True
                , style "width" "100%"
                , style "padding" "0.75rem 1rem"
                , style "font-size" "0.95rem"
                , style "font-family" "var(--font-code)"
                , style "border-radius" "6px"
                , style "color" "var(--text-primary)"
                ]
                []
            ]
        , viewFeedback model
        , button
            [ class "btn-primary"
            , onClick NewEquation
            , style "padding" "0.6rem 1.25rem"
            , style "font-size" "0.9rem"
            ]
            [ text "New Equation "
            , span
                [ style "opacity" "0.6"
                , style "font-size" "0.8rem"
                ]
                [ text "(cmd+return)" ]
            ]
        , viewFooter
        ]


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Ports.mathRendered SvgRendered
        , if model.page == Landing then
            Browser.Events.onKeyDown
                (D.map3 KeyDown
                    (D.field "key" D.string)
                    (D.field "ctrlKey" D.bool)
                    (D.field "metaKey" D.bool)
                )

          else
            Sub.none
        ]


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }
