import gleam/dict
import gleam/json
import gleam/list
import gleam/option
import gleam/result

pub type PageProp {
  ErrorProp(name: String, value: json.Json)
  BaseProp(name: String, value: json.Json)
  OnceProp(name: String, value: fn() -> json.Json)
  SharedProp(name: String, value: json.Json)
  DeferProp(
    name: String,
    value: fn() -> Result(json.Json, Nil),
    group: option.Option(String),
  )
}

pub type RenderContext {
  RenderContext(
    component: String,
    version: String,
    first_load: Bool,
    partials: List(String),
    excepts: List(String),
  )
}

pub type PageObject {
  PageObject(
    component: String,
    url: String,
    props: List(PageProp),
    errors: List(PageProp),
    defers: List(PageProp),
    version: String,
    clear_history: option.Option(Bool),
  )
}

pub fn page_object_to_json(po: PageObject, ctx: RenderContext) -> json.Json {
  let view_props = case ctx.first_load {
    True ->
      resolve_props(ctx, po.props)
      |> list.append([#("errors", json.object(resolve_props(ctx, po.errors)))])
      |> list.append(resolve_props(ctx, po.props))
      |> json.object
    False ->
      resolve_props(ctx, po.props)
      |> list.append([#("errors", json.object(resolve_props(ctx, po.errors)))])
      |> list.append(resolve_props(ctx, po.props))
      |> list.append(resolve_props(ctx, po.defers))
      |> json.object
  }

  let base_items = [
    #("component", json.string(po.component)),
    #("url", json.string(po.url)),
    #("props", view_props),
    #("version", json.string(po.version)),
    #("clearHistory", json.bool(False)),
  ]

  let once_resolved = case resolve_once_props(po.props) {
    option.None -> base_items
    option.Some(once) -> list.append(base_items, [once])
  }

  let defer_resolved = case ctx.first_load {
    False -> once_resolved
    True ->
      case resolve_defer_prop(po.defers) {
        option.None -> once_resolved
        option.Some(defers) -> list.append(once_resolved, [defers])
      }
  }

  json.object(defer_resolved)
}

fn resolve_props(
  ctx: RenderContext,
  props: List(PageProp),
) -> List(#(String, json.Json)) {
  list.filter(props, fn(p: PageProp) {
    let include = list.contains(ctx.partials, p.name)
    let exclude = list.contains(ctx.excepts, p.name)
    include || !exclude
  })
  |> list.map(resolve_map_prop)
}

fn resolve_once_props(
  props: List(PageProp),
) -> option.Option(#(String, json.Json)) {
  let once =
    props
    |> list.filter(fn(p: PageProp) {
      case p {
        OnceProp(_, _) -> True
        _ -> False
      }
    })
    |> list.map(fn(p: PageProp) {
      let value =
        json.object([
          #("prop", json.string(p.name)),
          #("expiresAt", json.null()),
        ])
      #(p.name, value)
    })

  case once {
    [] -> option.None
    _ -> option.Some(#("onceProps", json.object(once)))
  }
}

fn resolve_defer_prop(
  props: List(PageProp),
) -> option.Option(#(String, json.Json)) {
  let groups =
    props
    |> list.group(fn(p: PageProp) {
      case p {
        DeferProp(_, _, g) -> option.unwrap(g, "default")
        _ -> ""
      }
    })

  let items =
    dict.keys(groups)
    |> list.filter(fn(key: String) { key != "" })
    |> list.map(fn(k: String) {
      let values =
        dict.get(groups, k)
        |> result.unwrap([])
        |> list.map(fn(p: PageProp) { p.name })
      #(k, json.array(values, of: json.string))
    })

  case items {
    [] -> option.None
    _ -> option.Some(#("deferredProps", json.object(items)))
  }
}

fn resolve_map_prop(p: PageProp) -> #(String, json.Json) {
  case p {
    OnceProp(name, fun) -> #(name, fun())
    BaseProp(name, value) -> #(name, value)
    SharedProp(name, value) -> #(name, value)
    DeferProp(name, fun, _) -> {
      case fun() {
        Ok(val) -> #(name, val)
        _ -> #(name, json.null())
      }
    }
    ErrorProp(name, value) -> #("errors", json.object([#(name, value)]))
  }
}
