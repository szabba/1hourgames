module Main exposing (main)

import Math.Vector3 as Vec3 exposing (Vec3)
import Html as H exposing (Html)
import Html.App as App
import Html.Attributes as HA
import WebGL


main : Program Never
main =
    App.program
        { init = () ! []
        , subscriptions = \_ -> Sub.none
        , update = \_ _ -> () ! []
        , view = view
        }


view : a -> Html msg
view model =
    WebGL.toHtml
        [ HA.width 400
        , HA.height 300
        ]
        [ WebGL.render vertexShader fragmentShader heroVertices {} ]


type alias Vertex =
    { pos : Vec3 }


heroVertices : WebGL.Drawable Vertex
heroVertices =
    WebGL.Triangle
        [ ( { pos = Vec3.vec3 0 0 0 }
          , { pos = Vec3.vec3 1 1 0 }
          , { pos = Vec3.vec3 1 -1 0 }
          )
        ]


vertexShader : WebGL.Shader Vertex {} {}
vertexShader =
    [glsl|
        precision mediump float;

        attribute vec3 pos;

        void main() {
            gl_Position = vec4(pos, 1);
        } |]


fragmentShader : WebGL.Shader {} {} {}
fragmentShader =
    [glsl|
        precision mediump float;

        void main() {
            gl_FragColor = vec4(0, 0, 1, 1);
        } |]
