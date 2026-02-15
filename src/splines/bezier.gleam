import gleam/list
import splines.{type Vec2f, type Vec3f}
import splines/lerp.{type Interpolator}

pub type Bezier(a) {
  Bezier(points: List(a), interpolator: Interpolator(a))
}

pub fn new_2d(points: List(Vec2f)) -> Bezier(Vec2f) {
  Bezier(points:, interpolator: lerp.lerp2)
}

pub fn new_3d(points: List(Vec3f)) -> Bezier(Vec3f) {
  Bezier(points:, interpolator: lerp.lerp3)
}

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
