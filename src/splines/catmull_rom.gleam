//// Centripetal Catmull-Rom splines
////
//// Catmull-Rom splines are useful for paths of objects because they
//// preserve velocity through points on the path and ensure that all
//// points are passed through with exception of the first and last.
//// This implementation uses the ["centripetal" formulation](https://en.wikipedia.org/wiki/Centripetal_Catmull%E2%80%93Rom_spline)
//// that requires 4 control points, with the curve spanning the two central points.

import matrix/mat4f.{type Mat4f}
import vec/vec2f.{type Vec2f}
import vec/vec3f.{type Vec3f}
import vec/vec4.{type Vec4, Vec4}
import vec/vec4f

const characteristic: Mat4f = Vec4(
  Vec4(0.0, -1.0, 2.0, -1.0),
  Vec4(2.0, 0.0, -5.0, 3.0),
  Vec4(0.0, 1.0, 4.0, -3.0),
  Vec4(0.0, 0.0, -1.0, 1.0),
)

/// A centripetal Catmull-Rom spline over a generic domain.
/// See [`new_2d`](#new_2d) and [`new_3d`](#new_3d) to construct one.
pub type CatmullRom(a) {
  CatmullRom(points: Vec4(a), scale: fn(a, Float) -> a, sum: fn(List(a)) -> a)
}

/// Constructs a 2d Catmull-Rom spline, given the four control-points as `Vec2f`s.
pub fn new_2d(p0: Vec2f, p1: Vec2f, p2: Vec2f, p3: Vec2f) -> CatmullRom(Vec2f) {
  let points = Vec4(p0, p1, p2, p3)
  CatmullRom(points:, scale: vec2f.scale, sum: vec2f.sum)
}

/// Constructs a 3d Catmull-Rom spline, given the four control-points as `Vec3f`s.
pub fn new_3d(p0: Vec3f, p1: Vec3f, p2: Vec3f, p3: Vec3f) -> CatmullRom(Vec3f) {
  let points = Vec4(p0, p1, p2, p3)
  CatmullRom(points:, scale: vec3f.scale, sum: vec3f.sum)
}

/// Samples any Catmull-Rom spline at time `t`, where `0.0 <= t <= 1.0` (usually).
pub fn sample(curve: CatmullRom(a), t: Float) -> a {
  Vec4(1.0, t, t *. t, t *. t *. t)
  |> vec4f.scale(0.5)
  |> mat4f.mul_transpose_vec4(characteristic, _)
  |> vec4.map2(curve.points, _, curve.scale)
  |> vec4.to_list
  |> curve.sum
}
