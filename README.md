# splines

An implementation of popular parametric splines for use in graphics, simulations, and games.

[![Package Version](https://img.shields.io/hexpm/v/splines)](https://hex.pm/packages/splines)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/splines/)

```sh
gleam add splines@1
```
```gleam
import splines/bezier
import vec/vec2.{type Vec2}

pub fn main() -> Nil {
  let quadratic_curve = bezier.new_2d([
    Vec2(0.0, 1.0),
    Vec2(0.0, 0.0),
    Vec2(1.0, 0.0),
  ])
  bezier.sample(quadratic_curve, 0.5) |> echo
}
```

Further documentation can be found at <https://hexdocs.pm/splines>.
