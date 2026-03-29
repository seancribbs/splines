import gleam/bool
import gleam/dict.{type Dict}
import gleam/float
import gleam/int
import gleam/list
import gleam/option
import gleam/result
import gleam/string
import gleam/string_tree
import lustre/attribute
import lustre/effect
import lustre/element
import savoiardi/geometry
import savoiardi/material.{LineBasicOptions}
import savoiardi/object.{type Object3D}
import tiramisu/dev/extension
import tiramisu/dev/runtime.{type Runtime}
import vec/vec3
import vec/vec3f

pub const tag = "tiramisu-line"

pub const width = attribute.width

pub fn line(
  id: String,
  attributes: List(attribute.Attribute(msg)),
) -> element.Element(msg) {
  element.element(tag, [attribute.id(id), ..attributes], [])
}

pub fn points(p: List(vec3f.Vec3f)) -> attribute.Attribute(a) {
  attribute.attribute(
    "points",
    p
      |> list.map(point_to_string)
      |> string_tree.join(" ")
      |> string_tree.to_string(),
  )
}

fn point_to_string(p: vec3f.Vec3f) -> string_tree.StringTree {
  string_tree.join(
    [
      string_tree.from_string(float.to_string(p.x)),
      string_tree.from_string(float.to_string(p.y)),
      string_tree.from_string(float.to_string(p.z)),
    ],
    ",",
  )
}

pub fn color(c: Int) -> attribute.Attribute(a) {
  attribute.attribute("color", int.to_base16(c))
}

fn create(
  runtime: Runtime,
  id: String,
  parent_id: String,
  attributes: Dict(String, String),
) -> #(Runtime, effect.Effect(extension.Msg)) {
  let #(color, linewidth) = get_material_attributes(attributes)
  let material =
    material.line_basic(
      LineBasicOptions(..material.line_basic_options(), color:, linewidth:),
    )
  let geometry = geometry.line_points(get_points(attributes))
  let object = object.line_segments(geometry, material)

  #(runtime.add_object(runtime, id, object:, parent_id:, tag:), effect.none())
}

fn update(
  ctx: Runtime,
  _id: String,
  _parent_id: String,
  object: option.Option(Object3D),
  attributes: Dict(String, String),
  changed_attributes: extension.AttributeChanges,
) -> #(Runtime, effect.Effect(extension.Msg)) {
  let _ =
    option.map(object, fn(object) {
      apply_geometry(object, attributes, changed_attributes)
      apply_material(object, attributes, changed_attributes)
      object
    })

  #(ctx, effect.none())
}

fn apply_geometry(
  object: Object3D,
  attributes: Dict(String, String),
  changed_attributes: extension.AttributeChanges,
) {
  use <- bool.guard(
    when: !extension.has_change(changed_attributes, "points"),
    return: Nil,
  )
  let geometry = geometry.line_points(get_points(attributes))
  object.set_geometry(object, geometry)
  Nil
}

fn apply_material(
  object: Object3D,
  attributes: Dict(String, String),
  changed_attributes: extension.AttributeChanges,
) {
  use <- bool.guard(
    when: !extension.has_change(changed_attributes, "color")
      && !extension.has_change(changed_attributes, "width"),
    return: Nil,
  )
  let #(color, linewidth) = get_material_attributes(attributes)
  let material =
    material.line_basic(
      LineBasicOptions(..material.line_basic_options(), color:, linewidth:),
    )
  object.set_material(object, material)
  Nil
}

fn remove(
  runtime: Runtime,
  id: String,
  parent_id: String,
  object: Object3D,
) -> #(Runtime, effect.Effect(extension.Msg)) {
  let runtime = runtime.remove_object(runtime, id, parent_id, object)
  #(runtime, effect.none())
}

// Node extension for line segments
pub fn ext() -> extension.Extension {
  let observed_attributes = ["points", "color", "width"]
  extension.node_extension(
    tag:,
    observed_attributes:,
    create:,
    update:,
    remove:,
  )
}

fn get_points(attributes: Dict(String, String)) -> List(vec3f.Vec3f) {
  attributes
  |> dict.get("points")
  |> result.try(point_list_to_vectors)
  |> result.unwrap([])
}

fn get_material_attributes(attributes: Dict(String, String)) -> #(Int, Float) {
  let color = extension.get(attributes, "color", 0, int.base_parse(_, 16))
  let width = extension.get(attributes, "width", 1.0, extension.parse_number)
  #(color, width)
}

fn parse_vector(values: List(Float)) -> Result(vec3f.Vec3f, Nil) {
  case values {
    [x, y, z] -> Ok(vec3.Vec3(x, y, z))
    _ -> Error(Nil)
  }
}

fn point_list_to_vectors(points: String) -> Result(List(vec3f.Vec3f), Nil) {
  points
  |> string.split(" ")
  |> list.try_map(vector_to_numbers)
  |> result.try(list.try_map(_, parse_vector))
  |> result.map(duplicate_inner_points)
}

fn duplicate_inner_points(points: List(vec3f.Vec3f)) -> List(vec3f.Vec3f) {
  points
  |> list.window(2)
  |> list.flatten()
}

fn vector_to_numbers(vector: String) -> Result(List(Float), Nil) {
  vector
  |> string.split(on: ",")
  |> list.map(string.trim)
  |> list.map(extension.parse_number)
  |> result.all
}
