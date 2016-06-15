module Camera exposing (Model, init, initCmd, Msg, subscriptions, update, onZoom)

import Basics.Extra as Basics
import Html as H exposing (Attribute)
import Html.Events as HE
import Json.Decode as Json exposing ((:=))
import Task
import Window
import Math.Vector2 as Vec2
import Drag


-- MODEL


type alias Model =
    { drag : Drag.Model
    , size : Window.Size
    , frustrum : Float
    , distance : Float
    , alpha : Float
    , phi : Float
    }


init : Model
init =
    { drag = Drag.init
    , size = Window.Size 0 0
    , frustrum = 1
    , distance = 100
    , alpha = 0
    , phi = 0
    }


initCmd : Cmd Msg
initCmd =
    Window.size
        |> Task.perform Basics.never Resize



-- UPDATE


type Msg
    = DragMsg Drag.Msg
    | Resize Window.Size
    | Zoom Float


subscriptions : Model -> Sub Msg
subscriptions model =
    [ Window.resizes Resize
    , model.drag
        |> Drag.subscriptions
        |> Sub.map DragMsg
    ]
        |> Sub.batch


update : Msg -> Model -> Model
update msg model =
    case msg of
        DragMsg msg ->
            let
                ( newDrag, delta ) =
                    model.drag
                        |> Drag.update msg
            in
                { model
                    | drag = newDrag
                    , alpha = model.alpha + (Vec2.getX delta) * pi / 180
                    , phi = model.phi + (Vec2.getY delta) * pi / 180 |> clamp 0 (pi / 2)
                }

        Resize newSize ->
            { model | size = newSize }

        Zoom delta ->
            { model | distance = model.distance + 10 * delta }



-- VIEW


onZoom : (Msg -> msg) -> Attribute msg
onZoom wrapMsg =
    HE.on "wheel" ("deltaY" := Json.float |> Json.map (Zoom >> wrapMsg))
