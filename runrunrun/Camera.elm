module Camera exposing (Model, init, initCmd, Msg, subscriptions, update, onZoom)

import Basics.Extra as Basics
import Html as H exposing (Attribute)
import Html.Events as HE
import Json.Decode as Json exposing ((:=))
import Task
import Window


-- MODEL


type alias Model =
    { size : Window.Size
    , frustrum : Float
    , distance : Float
    }


init : Model
init =
    { size = Window.Size 0 0
    , frustrum = 10
    , distance = 100
    }


initCmd : Cmd Msg
initCmd =
    Window.size
        |> Task.perform Basics.never Resize



-- UPDATE


type Msg
    = Resize Window.Size
    | Zoom Float


subscriptions : Model -> Sub Msg
subscriptions _ =
    Window.resizes Resize


update : Msg -> Model -> Model
update msg model =
    case msg of
        Resize newSize ->
            { model | size = newSize }

        Zoom delta ->
            { model | distance = model.distance + 10 * delta |> clamp 0 150 }



-- VIEW


onZoom : (Msg -> msg) -> Attribute msg
onZoom wrapMsg =
    HE.on "wheel" ("deltaY" := Json.float |> Json.map (Zoom >> wrapMsg))
