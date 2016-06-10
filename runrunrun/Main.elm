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
    , hero : WebGL.Drawable Vertex
    }


type alias Vertex =
    { pos : Vec3, color : Vec3 }


type alias Camera =
    { zoom : Float
    }


init : ( Model, Cmd Msg )
init =
    ( { size = Window.Size 0 0
      , camera = { zoom = 100 }
      , hero = hero
      }
    , Window.size
        |> Task.perform Basics.never Resize
    )


hero : WebGL.Drawable Vertex
hero =
    WebGL.Triangle
        [ ( { pos = Vec3.vec3 0 0 0, color = blue }
          , { pos = Vec3.vec3 0.5 0 1, color = blue }
          , { pos = Vec3.vec3 -0.5 0 1, color = blue }
          )
        ]


ground : WebGL.Drawable Vertex
ground =
    WebGL.Triangle
        [ ( { pos = Vec3.vec3 -3 -3 0, color = yellow }
          , { pos = Vec3.vec3 -3 3 0, color = yellow }
          , { pos = Vec3.vec3 3 -3 0, color = yellow }
          )
        , ( { pos = Vec3.vec3 3 3 0, color = yellow }
          , { pos = Vec3.vec3 -3 3 0, color = yellow }
          , { pos = Vec3.vec3 3 -3 0, color = yellow }
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
update msg model =
    case msg of
        Resize newSize ->
            { model | size = newSize } ! []

        Zoom delta ->
            let
                { camera } =
                    model

                newCamera =
                    { camera
                        | zoom =
                            (camera.zoom + delta / 100)
                                |> clamp 0.1 1
                    }
                        |> Debug.log "new zoom"

                newModel =
                    { model | camera = newCamera }
            in
                newModel ! []

        Animate dt ->
            model ! []



-- VIEW


view : Model -> Html Msg
view { size, hero, camera } =
    let
        uniforms =
            { zoom = camera.zoom
            , width = toFloat size.width
            , height = toFloat size.height
            , phi = pi / 10
            , alpha = pi / 6
            }
    in
        WebGL.toHtml
            [ HA.width size.width
            , HA.height size.height
            , HA.style [ (,) "display" "block" ]
            , onWheel Zoom
            ]
            [ WebGL.render vertexShader fragmentShader hero uniforms
            , WebGL.render vertexShader fragmentShader ground uniforms
            ]


vertexShader : WebGL.Shader Vertex { u | zoom : Float, width : Float, height : Float, phi : Float, alpha : Float } { vcolor : Vec3 }
vertexShader =
    [glsl|
        precision highp float;

        attribute vec3 pos;
        attribute vec3 color;

        uniform float zoom;
        uniform float width;
        uniform float height;
        uniform float alpha;
        uniform float phi;

        varying vec3 vcolor;

        void main() {

            mat4 permuteAxes =
                mat4(
                    1, 0, 0, 0,
                    0, 0, 1, 0,
                    0, 1, 0, 0,
                    0, 0, 0, 1);

            mat4 handleRatio =
                mat4(
                    height / width, 0, 0, 0,
                    0, 1, 0, 0,
                    0, 0, 1, 0,
                    0, 0, 0, 1);

            mat4 applyZoom =
                mat4(
                    zoom, 0, 0, 0,
                    0, zoom, 0, 0,
                    0, 0, zoom, 0,
                    0, 0, 0, 1);

            mat4 rotX =
                mat4(
                    1, 0, 0, 0,
                    0, cos(phi), sin(phi), 0,
                    0, -sin(phi), cos(phi), 0,
                    0, 0, 0, 1);

            mat4 rotZ =
                mat4(
                    cos(alpha), -sin(alpha), 0, 0,
                    sin(alpha), cos(alpha), 0, 0,
                    0, 0, 1, 0,
                    0, 0, 0, 1);

            gl_Position =
                permuteAxes
                * handleRatio
                * applyZoom
                * rotX
                * rotZ
                * vec4(pos, 1);

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
