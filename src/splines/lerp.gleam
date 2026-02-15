import gleam/float
import splines.{type Vec2f, type Vec3f}
import vec/vec2f
import vec/vec3f

pub type Interpolator(a) =
  fn(a, a, Float) -> a

pub fn lerper(
  add: fn(a, a) -> a,
  subtract: fn(a, a) -> a,
  scale: fn(a, Float) -> a,
) -> Interpolator(a) {
  fn(i: a, j: a, t: Float) {
    subtract(j, i)
    |> scale(t)
    |> add(i)
  }
}

pub fn lerp1(i: Float, j: Float, t: Float) -> Float {
  float.subtract(j, i)
  |> float.multiply(t)
  |> float.add(i)
}

pub fn lerp2(i: Vec2f, j: Vec2f, t: Float) -> Vec2f {
  vec2f.subtract(j, i)
  |> vec2f.scale(t)
  |> vec2f.add(i)
}

pub fn lerp3(i: Vec3f, j: Vec3f, t: Float) -> Vec3f {
  vec3f.subtract(j, i)
  |> vec3f.scale(t)
  |> vec3f.add(i)
}
