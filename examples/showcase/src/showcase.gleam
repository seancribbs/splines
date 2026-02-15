import gleam/option
import showcase/bezier
import showcase/catmull_rom
import tiramisu
import tiramisu/camera
import tiramisu/effect
import tiramisu/geometry
import tiramisu/input
import tiramisu/material
import tiramisu/scene
import tiramisu/transform
import vec/vec2
import vec/vec3

pub fn main() {
  let app = tiramisu.application(init:, update:, view:)

  let assert Ok(_) =
    tiramisu.start(
      app,
      "#app",
      tiramisu.Window(vec2.Vec2(600.0, 600.0)),
      option.None,
    )

  Nil
}

pub type Model {
  Bezier
  CatmullRom
}

pub type Msg {
  Tick
  Next
}

fn init(_ctx: tiramisu.Context) {
  #(CatmullRom, effect.dispatch(Tick), option.None)
}

fn update(model: Model, msg: Msg, ctx: tiramisu.Context) {
  case msg {
    Tick -> {
      let eff = case input.is_key_just_pressed(ctx.input, input.Space) {
        True -> effect.dispatch(Next)
        False -> effect.none()
      }
      #(model, effect.batch([eff, effect.dispatch(Tick)]), option.None)
    }
    Next -> {
      let model = case model {
        Bezier -> CatmullRom
        CatmullRom -> Bezier
      }
      #(model, effect.none(), option.None)
    }
  }
}

fn view(model: Model, _ctx: tiramisu.Context) {
  let c = camera.camera_2d(vec2.Vec2(600, 600))
  let assert Ok(bg_geo) = geometry.plane(vec2.Vec2(600.0, 600.0))
  let assert Ok(bg_mat) =
    material.basic(
      color: 0x808080,
      transparent: False,
      opacity: 1.0,
      map: option.None,
      side: material.DoubleSide,
      alpha_test: 1.0,
      depth_write: False,
    )

  let curves = case model {
    Bezier -> bezier.showcase()
    CatmullRom -> catmull_rom.showcase()
  }

  scene.empty(id: "root", transform: transform.identity, children: [
    scene.mesh(
      id: "background",
      geometry: bg_geo,
      material: bg_mat,
      transform: transform.identity,
      physics: option.None,
    ),
    scene.camera(
      id: "camera",
      camera: c,
      transform: transform.at(vec3.Vec3(0.0, 0.0, 5.0)),
      active: True,
      viewport: option.None,
      postprocessing: option.None,
    ),
    ..curves
  ])
}
