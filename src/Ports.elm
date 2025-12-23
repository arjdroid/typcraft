port module Ports exposing (mathRendered, renderMath)

import Json.Encode as E


-- Send math expression to JS for rendering with target identifier
port renderMathInternal : E.Value -> Cmd msg


renderMath : { expression : String, target : String } -> Cmd msg
renderMath { expression, target } =
    renderMathInternal
        (E.object
            [ ( "expression", E.string expression )
            , ( "target", E.string target )
            ]
        )


-- Receive SVG result from JS with target identifier (JSON: { target, svg })
port mathRendered : (E.Value -> msg) -> Sub msg
