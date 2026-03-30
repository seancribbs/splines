//// Beziér splines
////
//// [Beziér](https://en.wikipedia.org/wiki/B%C3%A9zier_curve) splines
//// are useful for drawing strokes and shapes and are often the dominant
//// parametric curve exposed by graphical editors.

import gleam/list
import matrix/mat4f.{type Mat4f}
import splines/lerp.{type Interpolator}
import vec/vec2f.{type Vec2f}
import vec/vec3f.{type Vec3f}
import vec/vec4.{type Vec4, Vec4}

const characteristic: Mat4f = Vec4(
  Vec4(1.0, -3.0, 3.0, -1.0),
  Vec4(0.0, 3.0, -6.0, 3.0),
  Vec4(0.0, 0.0, 3.0, -3.0),
  Vec4(0.0, 0.0, 0.0, 1.0),
)

/// A generic n-ary Beziér spline over the domain `a`. Most users will want the simpler versions produced by [`new_2d`](#new_2d) or [`new_3d`](#new_3d).
///
/// If you construct the spline yourself, you must supply an `Interpolator`
/// function for the domain. The number of points in the domain
/// determines both the order and the computational-complexity of
/// [sampling](#sample) the domain using the [de Castlejau](https://en.wikipedia.org/wiki/De_Casteljau%27s_algorithm) algorithm.
///
/// | Number of points | Order | Complexity |
/// |--|--|--|
/// | 2 | Linear | 1 step |
/// | 3 | Quadratic | 3 steps |
/// | 4* | Cubic | 6 steps |
/// | 5 | Quartic | 10 steps |
/// | ... | ... | ... |
///
/// If you use [`new_2d`](#new_2d) or [`new_3d`](#new_3d), and you pass 4 points, this will create instead the `CubicBezier` variant automatically.
/// Sampling of this variant will use the matrix-multiplication formulation instead of de Casteljau's method.
pub type Bezier(a) {
  Bezier(points: List(a), interpolator: Interpolator(a))
  /// Special case of the most common kind of Bezier curve
  CubicBezier(points: Vec4(a), scale: fn(a, Float) -> a, sum: fn(List(a)) -> a)
}

/// Constructs an n-ary Bezier spline in two dimensions.
/// This spline should include at least two points, but that
/// constraint is not checked.
pub fn new_2d(points: List(Vec2f)) -> Bezier(Vec2f) {
  case points {
    [p0, p1, p2, p3] ->
      CubicBezier(
        points: Vec4(p0, p1, p2, p3),
        scale: vec2f.scale,
        sum: vec2f.sum,
      )
    _ -> Bezier(points:, interpolator: lerp.lerp2)
  }
}

/// Constructs an n-ary Beziér spline in three dimensions.
/// This spline should include at least two points, but that
/// constraint is not checked.
pub fn new_3d(points: List(Vec3f)) -> Bezier(Vec3f) {
  case points {
    [p0, p1, p2, p3] ->
      CubicBezier(
        points: Vec4(p0, p1, p2, p3),
        scale: vec3f.scale,
        sum: vec3f.sum,
      )
    _ -> Bezier(points:, interpolator: lerp.lerp3)
  }
}

/// Samples the Beziér spline at time `t` using the recursive [de Castlejau](https://en.wikipedia.org/wiki/De_Casteljau%27s_algorithm) algorithm,
/// or the matrix-multiplication form if it is the `CubicBezier` variant.
///
/// Panics if the curve contains no points.
pub fn sample(b: Bezier(a), t: Float) -> a {
  case b {
    Bezier(points:, interpolator:) -> decasteljau(points, interpolator, t)
    CubicBezier(points:, scale:, sum:) -> {
      Vec4(1.0, t, t *. t, t *. t *. t)
      |> mat4f.mul_transpose_vec4(characteristic, _)
      |> vec4.map2(points, _, scale)
      |> vec4.to_list
      |> sum
    }
  }
}

fn decasteljau(points: List(a), interpolator: Interpolator(a), t: Float) -> a {
  case points {
    [] -> panic as "invalid input"
    [one] -> one
    _ -> {
      points
      |> list.window_by_2()
      |> list.map(fn(pair) { interpolator(pair.0, pair.1, t) })
      |> decasteljau(interpolator, t)
    }
  }
}
