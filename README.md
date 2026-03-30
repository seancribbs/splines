# splines

An implementation of popular parametric splines for use in graphics, simulations, and games.

[![Package Version](https://img.shields.io/hexpm/v/splines)](https://hex.pm/packages/splines)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/splines/)

```sh
gleam add splines
```
```gleam
import splines
import vec/vec2.{Vec2}

pub fn main() -> Nil {
  let bezier = splines.bezier_2d([
    Vec2(0.0, 1.0),
    Vec2(0.0, 0.5),
    Vec2(0.5, 0.0),
    Vec2(1.0, 0.0),
  ])
  splines.sample(bezier, 0.5) |> echo
}
```

Further documentation can be found at <https://hexdocs.pm/splines>.
