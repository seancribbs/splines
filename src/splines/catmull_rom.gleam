import gleam/float
import splines.{type Vec2f, type Vec3f}
import splines/lerp
import vec/vec2f
import vec/vec3f

pub opaque type CatmullRom(a) {
  CatmullRom(
    knots: #(Float, Float, Float, Float),
    points: #(a, a, a, a),
    interpolator: lerp.Interpolator(a),
  )
}

pub fn new_2d(p0: Vec2f, p1: Vec2f, p2: Vec2f, p3: Vec2f) -> CatmullRom(Vec2f) {
  let points = #(p0, p1, p2, p3)
  let k1 = {
    let assert Ok(t) = vec2f.distance(p0, p1) |> float.square_root()
    t
  }
  let k2 = {
    let assert Ok(t) = vec2f.distance(p1, p2) |> float.square_root()
    k1 +. t
  }
  let k3 = {
    let assert Ok(t) = vec2f.distance(p2, p3) |> float.square_root()
    k2 +. t
  }
  CatmullRom(knots: #(0.0, k1, k2, k3), points:, interpolator: lerp.lerp2)
}

pub fn sample(curve: CatmullRom(a), t: Float) -> a {
  let #(k0, k1, k2, k3) = curve.knots
  let #(p0, p1, p2, p3) = curve.points
  let u = k1 +. t *. { k2 -. k1 }
  let a1 = remap(k0, k1, p0, p1, u, curve.interpolator)
  let a2 = remap(k1, k2, p1, p2, u, curve.interpolator)
  let a3 = remap(k2, k3, p2, p3, u, curve.interpolator)
  let b1 = remap(k0, k2, a1, a2, u, curve.interpolator)
  let b2 = remap(k1, k3, a2, a3, u, curve.interpolator)
  remap(k1, k2, b1, b2, u, curve.interpolator)
}

fn remap(
  a: Float,
  b: Float,
  c: a,
  d: a,
  u: Float,
  interpolator: lerp.Interpolator(a),
) -> a {
  interpolator(c, d, { u -. a } /. { b -. a })
}

pub fn new_3d(p0: Vec3f, p1: Vec3f, p2: Vec3f, p3: Vec3f) -> CatmullRom(Vec3f) {
  let points = #(p0, p1, p2, p3)
  let k1 = {
    let assert Ok(t) = vec3f.distance(p0, p1) |> float.square_root()
    t
  }
  let k2 = {
    let assert Ok(t) = vec3f.distance(p1, p2) |> float.square_root()
    k1 +. t
  }
  let k3 = {
    let assert Ok(t) = vec3f.distance(p2, p3) |> float.square_root()
    k2 +. t
  }
  CatmullRom(knots: #(0.0, k1, k2, k3), points:, interpolator: lerp.lerp3)
}
