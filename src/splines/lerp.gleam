//// Generalized linear interpolation
////
//// Most splines use linear-interpolation ("lerp") in their calculations when sampling points from their curves.
//// This module generalizes lerp into multiple dimensions and provides example lerp functions for 1D, 2D, and 3D domains.

import gleam/float
import splines.{type Vec2f, type Vec3f}
import vec/vec2f
import vec/vec3f

/// The type of a function that can linearly-interpolate over a domain `a`.
pub type Interpolator(a) =
  fn(a, a, Float) -> a

/// Constructs an `Interpolator` function for the domain `a` by providing the
/// functions used in the computation, `add` (`+`), `subtract` (`-`), and scalar
/// multiplication (`*`).
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

/// Interpolates in one-dimension over floats. You can use this function instead of `lerper` when
/// the generic type is `Float`.
pub fn lerp1(i: Float, j: Float, t: Float) -> Float {
  float.subtract(j, i)
  |> float.multiply(t)
  |> float.add(i)
}

/// Interpolates in two-dimensions over vectors. You can use this function instead of `lerper` when
/// the generic type is `vec2.Vec2(Float)`.
pub fn lerp2(i: Vec2f, j: Vec2f, t: Float) -> Vec2f {
  vec2f.subtract(j, i)
  |> vec2f.scale(t)
  |> vec2f.add(i)
}

/// Interpolates in three-dimensions over vectors. You can use this function instead of `lerper` when
/// the generic type is `vec3.Vec3(Float)`.
pub fn lerp3(i: Vec3f, j: Vec3f, t: Float) -> Vec3f {
  vec3f.subtract(j, i)
  |> vec3f.scale(t)
  |> vec3f.add(i)
}
