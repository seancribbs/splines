//// splines - popular parametric splines for Gleam.
////
//// Splines are often used in graphics, simulations and games. They can be used
//// to approximate curved figures, define paths for objects to move along, or
//// shape the behavior of kinematics.
////
//// `splines` defines several popular spline kinds:
//// * Beziér splines, often used for curved figures
//// * Catmull-Rom splines, often used for smooth paths
////
//// Other splines may be added in the future.

import vec/vec2.{type Vec2}
import vec/vec3.{type Vec3}

/// A useful type alias for 2D-vectors in the `Float` domain
@internal
pub type Vec2f =
  Vec2(Float)

/// A useful type alias for 3D-vectors in the `Float` domain
@internal
pub type Vec3f =
  Vec3(Float)
