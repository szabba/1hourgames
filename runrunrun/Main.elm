module Main exposing (main)

import Math.Vector3 as Vec3 exposing (Vec3)
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
    { pos : Vec3 }


type alias Camera =
    { zoom : Float }


init : ( Model, Cmd Msg )
init =
    ( { size = Window.Size 0 0
      , camera = { zoom = 1 }
      , hero = hero
      }
    , Window.size
        |> Task.perform (\_ -> Debug.crash "never") Resize
    )


hero : WebGL.Drawable Vertex
hero =
    WebGL.Triangle
        [ ( { pos = Vec3.vec3 0 0 0 }
          , { pos = Vec3.vec3 1 1 0 }
          , { pos = Vec3.vec3 1 -1 0 }
          )
        ]



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
                            camera.zoom
                                + (Debug.log "zoom delta" delta / 100)
                                |> clamp 0.1 1
                    }

                newModel =
                    { model | camera = newCamera }
            in
                newModel ! []

        Animate dt ->
            model ! []



-- VIEW


view : Model -> Html Msg
view { size, hero, camera } =
    WebGL.toHtml
        [ HA.width size.width
        , HA.height size.height
        , HA.style [ (,) "display" "block" ]
        , onWheel Zoom
        ]
        [ WebGL.render vertexShader fragmentShader hero camera ]


vertexShader : WebGL.Shader Vertex { u | zoom : Float } {}
vertexShader =
    [glsl|
        precision mediump float;

        attribute vec3 pos;

        uniform float zoom;

        void main() {
            gl_Position = vec4(zoom * pos, 1);
        } |]


fragmentShader : WebGL.Shader {} u {}
fragmentShader =
    [glsl|
        precision mediump float;

        void main() {
            gl_FragColor = vec4(0, 0, 1, 1);
        } |]



-- EVENTS


onWheel : (Float -> msg) -> Attribute msg
onWheel f =
    HE.on "wheel"
        ("deltaY" := Json.float |> Json.map f)
