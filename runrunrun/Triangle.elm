module Triangle exposing (..)

import Math.Vector3 as Vec3 exposing (Vec3)
import Math.Matrix4 as Mat4 exposing (Mat4)
import WebGL
import Html exposing (Html)
import Html.App as App
import Html.Attributes as HA
import AnimationFrame


-- Create a mesh with two triangles


type alias Vertex =
    { position : Vec3 }


mesh : WebGL.Drawable Vertex
mesh =
    WebGL.Triangle
        [ ( Vertex (Vec3.vec3 0 0 0)
          , Vertex (Vec3.vec3 1 1 0)
          , Vertex (Vec3.vec3 1 -1 0)
          )
        ]


main : Program Never
main =
    App.program
        { init = ( 0, Cmd.none )
        , view = view
        , subscriptions = (\model -> AnimationFrame.diffs Basics.identity)
        , update = (\elapsed currentTime -> ( elapsed + currentTime, Cmd.none ))
        }


view : Float -> Html msg
view t =
    WebGL.toHtml [ HA.width 400, HA.height 400 ]
        [ WebGL.render vertexShader fragmentShader mesh {} ]


perspective : Float -> Mat4
perspective t =
    Mat4.makeScale (Vec3.vec3 1 1 1)



-- Shaders


vertexShader : WebGL.Shader { attr | position : Vec3 } unif {}
vertexShader =
    [glsl|

attribute vec3 position;

void main () {
    gl_Position = vec4(position, 1.0);
}

|]


fragmentShader : WebGL.Shader {} u {}
fragmentShader =
    [glsl|

precision mediump float;

void main () {
    gl_FragColor = vec4(0, 0, 1, 1.0);
}

|]
