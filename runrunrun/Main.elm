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
        { init = init ! []
        , subscriptions = \_ -> Sub.none
        , update = \_ _ -> init ! []
        , view = view
        }



-- MODEL


type alias Model =
    { hero : Vec2
    , camera : Camera
    }


type alias Camera =
    { center : Vec2
    , phi : Float
    , alpha : Float
    , zoom : Float
    }


init : Model
init =
    { hero = Vec2.vec2 0 0
    , camera = { center = Vec2.vec2 0 0, phi = pi / 4, alpha = 0, zoom = 1 }
    }



-- VIEW


view : Model -> Html msg
view model =
    H.div
        [ HA.style
            [ (,) "border-width" "1px"
            , (,) "border-style" "solid"
            , (,) "border-color" "#000000"
            , (,) "width" "400px"
            , (,) "height" "300px"
            , (,) "margin" "auto"
            ]
        ]
        [ WebGL.toHtml
            [ HA.width 400
            , HA.height 300
            ]
            [ WebGL.render vertexShader fragmentShader (heroVertices model) model.camera ]
        ]


type alias HeroVertex =
    { hero : Vec2
    , vertexDelta : Vec3
    }


heroVertices : Model -> WebGL.Drawable HeroVertex
heroVertices { hero } =
    let
        shiftedBy dx dy dz =
            { hero = hero
            , vertexDelta = Vec3.vec3 dx dy dz
            }
    in
        WebGL.Triangle
            [ ( shiftedBy 0 0 0
              , shiftedBy 1 1 0
              , shiftedBy 1 -1 0
              )
            ]


vertexShader : WebGL.Shader { hero : Vec2, vertexDelta : Vec3 } Camera {}
vertexShader =
    [glsl|
        precision mediump float;

        uniform vec2 center;
        uniform float phi;
        uniform float alpha;
        uniform float zoom;

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
