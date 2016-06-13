module Main exposing (main)

import Basics.Extra as Basics
import Html as H exposing (Html, Attribute)
import Html.App as App
import Html.Attributes as HA
import Html.Events as HE
import Json.Decode as Json exposing ((:=))
import Task
import Time exposing (Time)
import WebGL
import Window
import AnimationFrame
import Math.Vector3 as Vec3 exposing (Vec3)


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
    { size : Window.Size
    , camera : Camera
    , triangles : WebGL.Drawable Vertex
    }


type alias Vertex =
    { pos : Vec3, color : Vec3 }


type alias Camera =
    { frustrum : Float
    , distance : Float
    , alpha : Float
    , phi : Float
    }


init : ( Model, Cmd Msg )
init =
    ( { size = Window.Size 0 0
      , camera =
            { frustrum = 10
            , distance = 100
            , alpha = 0
            , phi = 0
            }
      , triangles = triangles
      }
    , Window.size
        |> Task.perform Basics.never Resize
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



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch
        [ AnimationFrame.diffs Animate
        , Window.resizes Resize
        ]



-- UPDATE


type Msg
    = Resize Window.Size
    | Animate Time
    | Zoom Float


update : Msg -> Model -> ( Model, Cmd Msg )
update msg ({ camera } as model) =
    case msg of
        Resize newSize ->
            { model | size = newSize } ! []

        Zoom delta ->
            camera
                |> (\camera -> { camera | distance = camera.distance + 10 * delta |> clamp 0 150 })
                |> (\newCamera -> { model | camera = newCamera } ! [])

        Animate dt ->
            model ! []



-- VIEW


view : Model -> Html Msg
view ({ size, triangles, camera } as model) =
    let
        _ =
            Debug.log "model" model

        uniforms =
            { width = toFloat size.width
            , height = toFloat size.height
            , frustrum = camera.frustrum
            , distance = camera.distance
            , alpha = camera.alpha
            , phi = camera.phi
            }
    in
        WebGL.toHtml
            [ HA.width size.width
            , HA.height size.height
            , HA.style [ (,) "display" "block" ]
            , onWheel (Zoom << (*) 0.1)
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



-- EVENTS


onWheel : (Float -> msg) -> Attribute msg
onWheel f =
    HE.on "wheel"
        ("deltaY" := Json.float |> Json.map f)
