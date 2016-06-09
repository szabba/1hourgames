module Main exposing (main)

import Math.Vector2 as Vec2 exposing (Vec2)
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


type alias HeroVertex =
    { hero : Vec2
    , vertexDelta : Vec3
    }


heroVertices : WebGL.Drawable HeroVertex
heroVertices =
    [ ( { hero = Vec2.vec2 0 0, vertexDelta = Vec3.vec3 0 0 0 }
      , { hero = Vec2.vec2 0 0, vertexDelta = Vec3.vec3 1 1 0 }
      , { hero = Vec2.vec2 0 0, vertexDelta = Vec3.vec3 1 -1 0 }
      )
    ]
        |> WebGL.Triangle


vertexShader : WebGL.Shader HeroVertex {} {}
vertexShader =
    [glsl|
        precision mediump float;

        attribute vec2 hero;
        attribute vec3 vertexDelta;

        void main() {
            gl_Position =
                vec4(hero, 0, 1) + vec4(vertexDelta, 1);
        } |]


fragmentShader : WebGL.Shader a b {}
fragmentShader =
    [glsl|
        precision mediump float;

        void main() {
            gl_FragColor = vec4(0, 0, 1, 1);
        } |]
