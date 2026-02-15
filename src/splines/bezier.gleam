//// Beziér splines
////
//// [Beziér](https://en.wikipedia.org/wiki/B%C3%A9zier_curve) splines
//// are useful for drawing strokes and shapes and are often the dominant
//// parametric curve exposed by graphical editors.

import gleam/list
import splines.{type Vec2f, type Vec3f}
import splines/lerp.{type Interpolator}

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
/// | 4 | Cubic | 6 steps |
/// | 5 | Quartic | 10 steps |
/// | ... | ... | ... |
pub type Bezier(a) {
  Bezier(points: List(a), interpolator: Interpolator(a))
}

/// Constructs an n-ary Bezier spline in two dimensions.
/// This spline should include at least two points, but that
/// constraint is not checked.
pub fn new_2d(points: List(Vec2f)) -> Bezier(Vec2f) {
  Bezier(points:, interpolator: lerp.lerp2)
}

/// Constructs an n-ary Beziér spline in three dimensions.
/// This spline should include at least two points, but that
/// constraint is not checked.
pub fn new_3d(points: List(Vec3f)) -> Bezier(Vec3f) {
  Bezier(points:, interpolator: lerp.lerp3)
}

/// Samples the Beziér spline at time `t` using the recursive [de Castlejau](https://en.wikipedia.org/wiki/De_Casteljau%27s_algorithm) algorithm.
///
/// Panics if the curve contains no points.
pub fn sample(b: Bezier(a), t: Float) -> a {
  decasteljau(b.points, b.interpolator, t)
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
