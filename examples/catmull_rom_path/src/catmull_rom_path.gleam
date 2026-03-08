import gleam/float
import gleam/time/duration
import lustre
import lustre/attribute
import lustre/effect
import lustre/element
import lustre/element/html
import quaternion
import splines
import splines/catmull_rom
import tiramisu/camera
import tiramisu/light
import tiramisu/material
import tiramisu/primitive
import tiramisu/scene
import tiramisu/tick
import tiramisu/transform
import vec/vec2.{Vec2}
import vec/vec2f
import vec/vec3
import vec/vec3f

import tiramisu

pub fn main() {
  let assert Ok(_) = tiramisu.register(tiramisu.builtin_extensions())

  let app = lustre.application(init:, update:, view:)
  let assert Ok(_) = lustre.start(app, "#app", Nil)

  Nil
}

pub type Model {
  Model(
    time: duration.Duration,
    direction: vec2f.Vec2f,
    points: List(vec2f.Vec2f),
    path: splines.Spline(catmull_rom.CatmullRom(vec2f.Vec2f), vec2f.Vec2f),
  )
}

pub type Msg {
  Tick(tick.TickContext)
}

const positive_x = Vec2(1.0, 0.0)

fn init(_flags: Nil) -> #(Model, effect.Effect(Msg)) {
  let points = [
    vec2.Vec2(-250.0, -250.0),
    vec2.Vec2(0.0, -225.0),
    vec2.Vec2(125.0, -200.0),
    vec2.Vec2(200.0, -100.0),
    vec2.Vec2(-0.0, 0.0),
    vec2.Vec2(-100.0, 150.0),
    vec2.Vec2(-175.0, 75.0),
  ]
  let assert Ok(path) = splines.catmull_rom_2d(points)
  let model =
    Model(
      time: duration.milliseconds(0),
      direction: vec2f.direction(
        vec2.Vec2(-250.0, -250.0),
        vec2.Vec2(0.0, -225.0),
      ),
      points:,
      path:,
    )
  #(model, tick.subscribe("main-scene", Tick))
}

fn update(model: Model, msg: Msg) -> #(Model, effect.Effect(Msg)) {
  case msg {
    Tick(t) -> {
      let next_time = duration.add(model.time, t.delta_time)
      let direction =
        vec2f.direction(
          splines.sample(model.path, t_value(model.time)),
          splines.sample(model.path, t_value(next_time)),
        )
      #(Model(..model, time: next_time, direction:), effect.none())
    }
  }
}

fn view(model: Model) -> element.Element(Msg) {
  let camera_position = vec3.Vec3(0.0, 200.0, 300.0)
  let look_at_q =
    quaternion.look_at(
      vec3.Vec3(0.0, 0.0, -1.0),
      vec3f.subtract(vec3f.zero, camera_position),
      vec3.Vec3(0.0, 1.0, 0.0),
    )

  let Vec2(x, z) = splines.sample(model.path, t_value(model.time))
  let object_position = vec3.Vec3(x:, y: 10.0, z:)
  let y_rotation = vec2f.angle(positive_x, model.direction)
  let object_rotation = quaternion.from_euler(vec3.Vec3(0.0, y_rotation, 0.0))
  html.div(
    [
      attribute.class(
        "flex flex-col bg-gray-950 text-white font-sans max-w-full",
      ),
    ],
    [
      tiramisu.scene(
        "main-scene",
        [
          scene.background_color(0x1a1a2e),
          attribute.width(800),
          attribute.height(600),
        ],
        [
          tiramisu.camera(
            "main-camera",
            [
              camera.fov(75.0),
              camera.active(True),
              transform.position(camera_position),
              transform.rotation_quaternion(look_at_q),
            ],
            [],
          ),
          tiramisu.primitive(
            "box",
            [
              material.phong(),
              primitive.box(vec3.Vec3(20.0, 10.0, 14.0)),
              transform.position(object_position),
              transform.rotation_quaternion(object_rotation),
              material.color(0xff0000),
              material.cast_shadow(True),
            ],
            [],
          ),
          tiramisu.primitive(
            "ground",
            [
              primitive.plane(vec2.Vec2(1000.0, 1000.0)),
              transform.position(vec3.Vec3(0.0, 0.0, 0.0)),
              transform.rotation(vec3.Vec3(-1.5708, 0.0, 0.0)),
              material.receive_shadow(True),
              material.color(0x808080),
            ],
            [],
          ),
          tiramisu.light(
            "ambient",
            [
              light.kind(light.Ambient),
              light.color(0xffffff),
              light.intensity(0.4),
            ],
            [],
          ),
          tiramisu.light(
            "sun",
            [
              light.kind(light.Directional),
              light.color(0xffffff),
              light.intensity(1.0),
              light.cast_shadow(True),
              transform.position(vec3.Vec3(5.0, 250.0, 7.0)),
            ],
            [],
          ),
        ],
      ),
    ],
  )
}

fn t_value(duration: duration.Duration) -> Float {
  let assert Ok(t) =
    duration.to_seconds(duration)
    |> float.modulo(4.0)
  t
}
