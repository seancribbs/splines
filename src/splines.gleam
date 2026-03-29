//// splines - popular parametric splines for Gleam.
////
//// Splines are often used in graphics, simulations and games. They can be used
//// to approximate curved figures, define paths for objects to move along, or
//// shape the behavior of kinematics.
////
//// `splines` defines several popular spline kinds:
//// * B-splines, often used for smooth paths that require strong continuity
//// * Beziér splines, often used for curved figures
//// * Catmull-Rom splines, often used for smooth paths that pass through the knots
////
//// Other splines may be added in the future.

import gleam/float
import gleam/int
import gleam/list
import splines/b.{type BSpline}
import splines/bezier
import splines/catmull_rom.{type CatmullRom}
import vec/vec2f.{type Vec2f}
import vec/vec3f.{type Vec3f}

pub type Spline(a, p) {
  UniformSpline(curves: List(a), sample: fn(a, Float) -> p)
  // NonUniformSpline(curves: List(#(Float, a)), sample: fn(a, Float) -> p)
}

/// Returns the number of individual curves composing the spline.
pub fn length(spline: Spline(a, p)) -> Int {
  case spline {
    UniformSpline(curves:, sample: _) -> list.length(curves)
  }
}

/// Samples a generic spline at time `t`. How `t` gets applied to the contained
/// curve definitions depends on whether the spline is uniform or not.
pub fn sample(spline: Spline(a, p), t: Float) -> p {
  case spline {
    UniformSpline(curves:, sample:) -> {
      let index = float.truncate(t)
      let length = list.length(curves)
      case index {
        // Before the beginning of the spline
        neg if neg < 0 -> {
          let assert Ok(curve) = list.first(curves)
          sample(curve, t)
        }
        // After the end of the spline
        oob if oob >= length -> {
          let assert Ok(curve) = list.last(curves)
          sample(curve, t -. int.to_float(length - 1))
        }
        _ -> {
          let assert [curve, ..] = list.drop(curves, index)
          sample(curve, t -. int.to_float(index))
        }
      }
    }
  }
}

/// A uniform cubic 2D B-Spline.
pub type BSpline2D =
  Spline(BSpline(Vec2f), Vec2f)

/// Constructs a sequence of cubic B-spline curves in 2d.
///
/// The list of points must be at least of length 4.
pub fn basis_2d(
  points: List(vec2f.Vec2f),
) -> Result(Spline(BSpline(Vec2f), Vec2f), Nil) {
  case list.length(points) < 4 {
    True -> Error(Nil)
    False -> {
      let curves =
        points
        |> list.window(4)
        |> list.map(fn(w) {
          let assert [p0, p1, p2, p3] = w
          b.new_2d(p0, p1, p2, p3)
        })
      Ok(UniformSpline(curves:, sample: b.sample))
    }
  }
}

/// A uniform cubic 3D B-Spline.
pub type BSpline3D =
  Spline(BSpline(Vec3f), Vec3f)

/// Constructs a sequence of cubic B-spline curves in 3d.
///
/// The list of points must be at least of length 4.
pub fn basis_3d(
  points: List(Vec3f),
) -> Result(Spline(BSpline(Vec3f), Vec3f), Nil) {
  case list.length(points) < 4 {
    True -> Error(Nil)
    False -> {
      let curves =
        points
        |> list.window(4)
        |> list.map(fn(w) {
          let assert [p0, p1, p2, p3] = w
          b.new_3d(p0, p1, p2, p3)
        })
      Ok(UniformSpline(curves:, sample: b.sample))
    }
  }
}

/// A uniform cubic 2D Beziér Spline.
pub type Bezier2D =
  Spline(bezier.Bezier(Vec2f), Vec2f)

/// Constructs a sequence of cubic Beziér curves in 3d, where every segment has two
/// control points and the curves are C0 continuous (share knots).
///
/// The list of points must be at least of length 4, and have multiples of 3 beyond the
/// first 4.
pub fn bezier_2d(
  points: List(Vec2f),
) -> Result(Spline(bezier.Bezier(Vec2f), Vec2f), Nil) {
  case list.length(points) < 4 || { list.length(points) - 4 } % 3 != 0 {
    True -> Error(Nil)
    False -> {
      let curves =
        points
        |> list.window(4)
        |> list.index_fold([], fn(acc, w, idx) {
          case idx % 3 {
            0 -> [bezier.new_2d(w), ..acc]
            _ -> acc
          }
        })
        |> list.reverse()
      Ok(UniformSpline(curves:, sample: bezier.sample))
    }
  }
}

/// A uniform cubic 3D Beziér Spline.
pub type Bezier3D =
  Spline(bezier.Bezier(Vec3f), Vec3f)

/// Constructs a sequence of cubic Beziér curves in 3d, where every segment has two
/// control points and the curves are C0 continuous (share knots).
///
/// The list of points must be at least of length 4, and have multiples of 3 beyond the
/// first 4.
pub fn bezier_3d(
  points: List(Vec3f),
) -> Result(Spline(bezier.Bezier(Vec3f), Vec3f), Nil) {
  case list.length(points) < 4 || { list.length(points) - 4 } % 3 != 0 {
    True -> Error(Nil)
    False -> {
      let curves =
        points
        |> list.window(4)
        |> list.index_fold([], fn(acc, w, idx) {
          case idx % 3 {
            0 -> [bezier.new_3d(w), ..acc]
            _ -> acc
          }
        })
        |> list.reverse()
      Ok(UniformSpline(curves:, sample: bezier.sample))
    }
  }
}

/// A uniform cubic 2D Catmull-Rom Spline.
pub type CatmullRom2D =
  Spline(CatmullRom(Vec2f), Vec2f)

/// Constructs a sequence of Catmull-Rom curves in 2d, where the curve passes through all but the first and
/// last points in the sequence.
///
/// The list of points must be at least of length 4.
pub fn catmull_rom_2d(
  points: List(vec2f.Vec2f),
) -> Result(Spline(CatmullRom(Vec2f), Vec2f), Nil) {
  case list.length(points) < 4 {
    True -> Error(Nil)
    False -> {
      let curves =
        points
        |> list.window(4)
        |> list.map(fn(w) {
          let assert [p0, p1, p2, p3] = w
          catmull_rom.new_2d(p0, p1, p2, p3)
        })
      Ok(UniformSpline(curves:, sample: catmull_rom.sample))
    }
  }
}

/// A uniform cubic 3D Catmull-Rom Spline.
pub type CatmullRom3D =
  Spline(CatmullRom(Vec3f), Vec3f)

/// Constructs a sequence of Catmull-Rom curves in 3d, where the curve passes through all but the first and
/// last points in the sequence.
///
/// The list of points must be at least of length 4.
pub fn catmull_rom_3d(
  points: List(Vec3f),
) -> Result(Spline(CatmullRom(Vec3f), Vec3f), Nil) {
  case list.length(points) < 4 {
    True -> Error(Nil)
    False -> {
      let curves =
        points
        |> list.window(4)
        |> list.map(fn(w) {
          let assert [p0, p1, p2, p3] = w
          catmull_rom.new_3d(p0, p1, p2, p3)
        })
      Ok(UniformSpline(curves:, sample: catmull_rom.sample))
    }
  }
}
