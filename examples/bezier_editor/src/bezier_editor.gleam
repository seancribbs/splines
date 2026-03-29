import bezier_editor/line
import gleam/dynamic/decode
import gleam/float
import gleam/int
import gleam/list
import gleam/option
import gleam/result
import gleam_community/colour
import lustre
import lustre/attribute
import lustre/effect
import lustre/element
import lustre/element/html
import lustre/event
import quaternion
import splines
import tiramisu/camera
import tiramisu/light
import tiramisu/renderer
import tiramisu/transform
import vec/vec2
import vec/vec2f
import vec/vec2i
import vec/vec3
import vec/vec3f

import tiramisu

pub fn main() {
  let assert Ok(_) =
    tiramisu.register([line.ext(), ..tiramisu.builtin_extensions()])

  let app = lustre.application(init:, update:, view:)
  let assert Ok(_) = lustre.start(app, "#app", Nil)

  Nil
}

pub type Model {
  Model(
    canvas_size: vec2i.Vec2i,
    points: List(vec2f.Vec2f),
    selected: option.Option(Int),
    pointer_down: Bool,
    spline: option.Option(splines.Bezier2D),
    num_samples: Int,
    color: colour.Color,
    line_width: Int,
  )
}

pub type Msg {
  Tick(renderer.Tick)
  PointerMove(vec2f.Vec2f)
  PointerDown(position: vec2f.Vec2f)
  PointerUp
  ChangeSamples(String)
  ChangeColor(String)
  ChangeWidth(String)
}

fn init(_flags: Nil) -> #(Model, effect.Effect(Msg)) {
  #(
    Model(
      canvas_size: vec2.splat(600),
      points: [],
      selected: option.None,
      pointer_down: False,
      spline: option.None,
      num_samples: 10,
      color: colour.white,
      line_width: 1,
    ),
    effect.none(),
  )
}

fn update(model: Model, msg: Msg) -> #(Model, effect.Effect(Msg)) {
  case msg {
    Tick(_) -> #(cache_spline(model), effect.none())
    PointerMove(pos) ->
      case model.pointer_down {
        False -> #(model, effect.none())
        True -> #(move_selected_point(model, pos), effect.none())
      }
    PointerDown(pos) -> #(pick(model, pos), effect.none())
    PointerUp -> #(Model(..model, pointer_down: False), effect.none())
    ChangeSamples(s) -> #(
      Model(..model, num_samples: s |> int.parse |> result.unwrap(25)),
      effect.none(),
    )
    ChangeColor(s) -> {
      #(
        Model(
          ..model,
          color: s
            |> colour.from_rgb_hex_string
            |> result.unwrap(colour.white),
        ),
        effect.none(),
      )
    }
    ChangeWidth(s) -> {
      #(
        Model(..model, line_width: s |> int.parse |> result.unwrap(1)),
        effect.none(),
      )
    }
  }
}

fn view(model: Model) -> element.Element(Msg) {
  let canvas_size = vec2.map(model.canvas_size, int.to_float)
  let camera_position = vec3.Vec3(0.0, 0.0, 100.0)
  let camera_rotation = quaternion.Quaternion(0.0, 0.0, 0.0, 1.0)
  //   quaternion.look_at(
  //     vec3.Vec3(0.0, 0.0, -1.0),
  //     vec3f.normalize(vec3f.subtract(vec3f.zero, camera_position)),
  //     vec3.Vec3(0.0, 1.0, 0.0),
  //   )
  html.div(
    [
      attribute.class(
        "flex flex-row bg-gray-950 text-white font-sans max-w-full gap-2",
      ),
    ],
    [
      tiramisu.renderer(
        "renderer",
        [
          renderer.height(model.canvas_size.y),
          renderer.width(model.canvas_size.x),
          event.on("pointerdown", pointer_event_decoder(PointerDown)),
          event.on("pointermove", pointer_event_decoder(PointerMove)),
          event.on("pointerup", decode.success(PointerUp)),
          attribute.class("flex-none"),
          renderer.on_tick(Tick),
        ],
        [
          tiramisu.scene("main-scene", [], [
            tiramisu.camera(
              "main-camera",
              [
                camera.active(True),
                camera.orthographic(),
                camera.left(canvas_size.x /. -2.0),
                camera.right(canvas_size.x /. 2.0),
                camera.top(canvas_size.y /. 2.0),
                camera.bottom(canvas_size.y /. -2.0),
                camera.near(100.0),
                camera.far(-100.0),
                transform.position(camera_position),
                transform.rotation_quaternion(camera_rotation),
              ],
              [],
            ),
            line.line("spline", [
              line.points(
                option.unwrap(
                  option.map(model.spline, sample_spline(_, model.num_samples)),
                  [],
                ),
              ),
              line.color(colour.to_rgb_hex(model.color)),
              line.width(model.line_width),
            ]),
            tiramisu.light(
              "ambient",
              [
                light.ambient(),
                light.color(0xffffff),
                light.intensity(1.0),
              ],
              [],
            ),
          ]),
        ],
      ),
      html.div([attribute.class("flex-1 min-w-32 px-2")], [
        html.div([], [
          html.label([], [
            html.text("Samples: " <> int.to_string(model.num_samples)),
            html.input([
              attribute.type_("range"),
              attribute.min("1"),
              attribute.max("100"),
              attribute.value(int.to_string(model.num_samples)),
              event.on_change(ChangeSamples),
            ]),
          ]),
        ]),
        html.div([], [
          html.label([], [
            html.text("Color"),
            html.input([
              attribute.type_("color"),
              attribute.value("#" <> colour.to_rgb_hex_string(model.color)),
              event.on_change(ChangeColor),
            ]),
          ]),
        ]),

        // NOTE: Changing this on the material seems not to make a difference.
        // html.div([], [
        //   html.label([], [
        //     html.text("Line Width: " <> int.to_string(model.line_width)),
        //     html.input([
        //       attribute.type_("range"),
        //       attribute.min("1"),
        //       attribute.max("50"),
        //       attribute.value(int.to_string(model.line_width)),
        //       event.on_change(ChangeWidth),
        //     ]),
        //   ]),
        // ]),
        //
        html.ol(
          [
            attribute.class("list-none overflow-y-auto mt-2"),
          ],
          list.map(model.points, fn(p) {
            html.li([], [
              html.text(
                float.to_string(float.to_precision(p.x, 1))
                <> ", "
                <> float.to_string(float.to_precision(p.y, 1)),
              ),
            ])
          }),
        ),
      ]),
    ],
  )
}

fn sample_spline(spline: splines.Bezier2D, samples: Int) -> List(vec3f.Vec3f) {
  let samples_f = int.to_float(samples)
  int.range(
    from: 0,
    // We want to include the last point
    to: { samples * splines.length(spline) } + 1,
    with: [],
    run: fn(acc, counter) {
      [splines.sample(spline, int.to_float(counter) /. samples_f), ..acc]
    },
  )
  |> points_to_3d(0.0)
  |> list.reverse()
}

fn cache_spline(model: Model) -> Model {
  let spline = {
    use <- option.lazy_or(model.spline)

    case list.length(model.points) {
      n if n >= 4 -> {
        model.points
        // 4, 7, 10, 13, ...
        |> list.take(n - { { n - 4 } % 3 })
        |> splines.bezier_2d()
        |> option.from_result
      }
      _ -> option.None
    }
  }
  Model(..model, spline:)
}

fn pick(model: Model, pos: vec2f.Vec2f) -> Model {
  // For now, this only adds points to the model, it does not let you select an
  // existing point in the spline.
  let selected = option.Some(list.length(model.points))
  let points =
    list.append(model.points, [screen_to_world(model.canvas_size, pos)])
  Model(..model, points:, selected:, spline: option.None, pointer_down: True)
}

fn move_selected_point(model: Model, pos: vec2f.Vec2f) -> Model {
  case model.selected {
    option.Some(idx) -> {
      let points =
        model.points
        |> list.index_map(fn(p, i) {
          case i == idx {
            False -> p
            True -> screen_to_world(model.canvas_size, pos)
          }
        })

      Model(..model, points:, spline: option.None)
    }
    option.None -> model
  }
}

fn screen_to_world(
  canvas_size: vec2.Vec2(Int),
  pos: vec2f.Vec2f,
) -> vec2.Vec2(Float) {
  // For now, we directly translate TL-pixels centered worldspace in a 1:1 ratio.
  // (0,0)
  // +-----|-----+
  // |     |     |
  // +-----+-----+
  // |     |     |
  // +-----|-----+ (canvas_size)
  //
  // (-canvas_size.x / 2, canvas_size.y / 2)
  // +-----|-----+
  // |     |     |
  // +-----+-----+
  // |     |     |
  // +-----|-----+ (canvas_size.x / 2, -canvas_size.y / 2)
  let float_size = vec2.map(canvas_size, int.to_float)

  vec2.Vec2(pos.x -. { float_size.x /. 2.0 }, { float_size.y /. 2.0 } -. pos.y)
}

fn pointer_event_decoder(m: fn(vec2f.Vec2f) -> Msg) -> decode.Decoder(Msg) {
  use x <- decode.field("offsetX", decode.float)
  use y <- decode.field("offsetY", decode.float)
  let msg = m(vec2.Vec2(x, y))
  decode.success(msg)
}

fn points_to_3d(points: List(vec2f.Vec2f), z: Float) -> List(vec3f.Vec3f) {
  list.map(points, fn(p) { vec3.Vec3(p.x, p.y, z) })
}
