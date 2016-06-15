module Drag exposing (Model, init, Msg, subscriptions, update)

import Mouse
import Math.Vector2 as Vec2 exposing (Vec2)


-- MODEL


type alias Model =
    { isDown : Bool
    , lastPosition : Vec2
    }


init : Model
init =
    { isDown = False
    , lastPosition = zero
    }



-- UPDATE


type Msg
    = Up
    | Down
    | Move Mouse.Position


subscriptions : Model -> Sub Msg
subscriptions _ =
    [ Mouse.downs (always Down)
    , Mouse.ups (always Up)
    , Mouse.moves Move
    ]
        |> Sub.batch


update : Msg -> Model -> ( Model, Vec2 )
update msg model =
    case msg of
        Up ->
            ( { model | isDown = False }, zero )

        Down ->
            ( { model | isDown = True }, zero )

        Move { x, y } ->
            let
                newPosition =
                    Vec2.vec2 (toFloat x) (toFloat y)
            in
                ( { model | lastPosition = newPosition }
                , if model.isDown then
                    Vec2.sub newPosition model.lastPosition
                  else
                    zero
                )


zero : Vec2
zero =
    Vec2.vec2 0 0
