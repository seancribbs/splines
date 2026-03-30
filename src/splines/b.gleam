//// B-splines
////
//// [B-splines](https://en.wikipedia.org/wiki/B-spline#) (short for basis splines)
//// are useful most for the continuity of their derivatives, making them an excellent choice
//// for camera and object movement where smoothness across knots is paramount but exact position is less
//// important.

import matrix/mat4f.{type Mat4f}
import vec/vec2f.{type Vec2f}
import vec/vec3f.{type Vec3f}
import vec/vec4.{type Vec4, Vec4}
import vec/vec4f

const characteristic: Mat4f = Vec4(
  Vec4(1.0, -3.0, 3.0, -1.0),
  Vec4(4.0, 0.0, -6.0, 3.0),
  Vec4(1.0, 3.0, 3.0, -3.0),
  Vec4(0.0, 0.0, 0.0, 1.0),
)

pub type BSpline(a) {
  BSpline(points: Vec4(a), scale: fn(a, Float) -> a, sum: fn(List(a)) -> a)
}

/// Constructs a 2d B-spline, given the four control-points as `Vec2f`s.
pub fn new_2d(p0: Vec2f, p1: Vec2f, p2: Vec2f, p3: Vec2f) -> BSpline(Vec2f) {
  let points = Vec4(p0, p1, p2, p3)
  BSpline(points:, scale: vec2f.scale, sum: vec2f.sum)
}

/// Constructs a 3d B-spline, given the four control-points as `Vec3f`s.
pub fn new_3d(p0: Vec3f, p1: Vec3f, p2: Vec3f, p3: Vec3f) -> BSpline(Vec3f) {
  let points = Vec4(p0, p1, p2, p3)
  BSpline(points:, scale: vec3f.scale, sum: vec3f.sum)
}

/// Samples any B-spline at time `t`, where `0.0 <= t <= 1.0` (usually).
pub fn sample(curve: BSpline(a), t: Float) -> a {
  Vec4(1.0, t, t *. t, t *. t *. t)
  |> vec4f.scale(1.0 /. 6.0)
  |> mat4f.mul_transpose_vec4(characteristic, _)
  |> vec4.map2(curve.points, _, curve.scale)
  |> vec4.to_list
  |> curve.sum
}
