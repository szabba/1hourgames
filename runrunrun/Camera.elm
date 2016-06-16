module Camera exposing (Model, init, initCmd, Msg, subscriptions, update, onZoom)

import Basics.Extra as Basics
import Html as H exposing (Attribute)
import Html.Events as HE
import Json.Decode as Json exposing ((:=))
import Task
import Window
import Drag


-- MODEL


type alias Model =
    { drag : Drag.Model
    , size : Window.Size
    , frustrum : Float
    , alpha : Float
    }


init : Model
init =
    { drag = Drag.init
    , size = Window.Size 0 0
    , frustrum = 1
    , alpha = pi / 2
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
            { model | drag = model.drag |> Drag.update msg |> fst }

        Resize newSize ->
            { model | size = newSize }

        Zoom delta ->
            { model
                | alpha =
                    (model.alpha + delta / 2000 * pi / 180)
                        |> clamp (pi / 2 * 0.999) (pi / 2 * 0.9995)
            }



-- VIEW


onZoom : (Msg -> msg) -> Attribute msg
onZoom wrapMsg =
    HE.on "wheel" ("deltaY" := Json.float |> Json.map (Zoom >> wrapMsg))
