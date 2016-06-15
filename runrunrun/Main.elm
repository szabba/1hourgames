module Main exposing (main)

import Html as H exposing (Html, Attribute)
import Html.App as App
import Html.Attributes as HA
import Time exposing (Time)
import WebGL
import AnimationFrame
import Math.Vector3 as Vec3 exposing (Vec3)
import Camera


main : Program Never
main =
    App.program
        { init = init
        , subscriptions = subscriptions
        , update = update
        , view = view
        }



-- MODEL


type alias Model =
    { camera : Camera.Model
    , triangles : WebGL.Drawable Vertex
    }


type alias Vertex =
    { pos : Vec3, color : Vec3 }


init : ( Model, Cmd Msg )
init =
    ( { camera = Camera.init
      , triangles = triangles
      }
    , Camera.initCmd |> Cmd.map CameraMsg
    )


triangles : WebGL.Drawable Vertex
triangles =
    WebGL.Triangle
        [ ( { pos = Vec3.vec3 -300 -300 0, color = blue }
          , { pos = Vec3.vec3 -300 300 0, color = blue }
          , { pos = Vec3.vec3 300 300 0, color = blue }
          )
        , ( { pos = Vec3.vec3 -300 -300 0, color = yellow }
          , { pos = Vec3.vec3 300 -300 0, color = yellow }
          , { pos = Vec3.vec3 300 300 0, color = yellow }
          )
        ]


yellow : Vec3
yellow =
    Vec3.vec3 1 0.863 0


blue : Vec3
blue =
    Vec3.vec3 0 0.455 0.851



-- UPDATE


type Msg
    = CameraMsg Camera.Msg
    | Animate Time


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ AnimationFrame.diffs Animate
        , model.camera
            |> Camera.subscriptions
            |> Sub.map CameraMsg
        ]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg ({ camera } as model) =
    case msg of
        CameraMsg msg ->
            { model | camera = model.camera |> Camera.update msg } ! []

        Animate dt ->
            model ! []



-- VIEW


view : Model -> Html Msg
view ({ triangles, camera } as model) =
    let
        uniforms =
            { width = toFloat camera.size.width
            , height = toFloat camera.size.height
            , frustrum = camera.frustrum
            , distance = camera.distance
            , alpha = 0
            , phi = 0
            }
    in
        WebGL.toHtml
            [ HA.width camera.size.width
            , HA.height camera.size.height
            , HA.style [ (,) "display" "block" ]
            , Camera.onZoom CameraMsg
            ]
            [ WebGL.render vertexShader fragmentShader triangles uniforms
            ]


vertexShader :
    WebGL.Shader Vertex
        { u
            | width : Float
            , height : Float
            , frustrum : Float
            , distance : Float
            , alpha : Float
            , phi : Float
        }
        { vcolor : Vec3 }
vertexShader =
    [glsl|
        precision highp float;

        attribute vec3 pos;
        attribute vec3 color;

        uniform float width;
        uniform float height;
        uniform float frustrum;
        uniform float distance;
        uniform float alpha;
        uniform float phi;

        varying vec3 vcolor;

        const float TURN = 3.1415 * 2.0;

        void main() {
            mat4 project =
                mat4(
                    2.0 * frustrum / width, 0, 0, 0,
                    0, 2.0 * frustrum / height, 0, 0,
                    0, 0, -1, -1,
                    0, 0, -frustrum, frustrum);

            mat4 moveAway =
                mat4(
                    1, 0, 0, 0,
                    0, 1, 0, 0,
                    0, 0, 1, 0,
                    0, 0, -distance, 1);

            gl_Position =
                project *
                moveAway *
                vec4(pos, 1);

            vcolor = color;
        } |]


fragmentShader : WebGL.Shader {} u { vcolor : Vec3 }
fragmentShader =
    [glsl|
        precision mediump float;

        varying vec3 vcolor;

        void main() {
            gl_FragColor = vec4(vcolor, 1);
        } |]
