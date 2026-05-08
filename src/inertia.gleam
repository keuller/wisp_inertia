import gleam/http.{Delete, Patch, Post, Put}
import gleam/http/request
import gleam/http/response.{Response as HttpResponse}
import gleam/json
import gleam/list
import gleam/option.{type Option, None}
import gleam/result
import gleam/string
import internal/context
import internal/manifest
import internal/props
import internal/template
import wisp.{Text}

const inertia_header: String = "X-Inertia"

const inertia_reset: String = "X-Inertia-Reset"

const inertia_except: String = "X-Inertia-Except-Once-Props"

const inertia_partial: String = "X-Inertia-Partial-Data"

const inertia_component: String = "X-Inertia-Partial-Component"

// default basic error view
const error_view = "
    <html lang='en'>
    <head>
      <title>Inertia Error</title>
    </head>
    <body>
      <h1 style='color:red;padding:4px;font-size:24px'>Error: No root template</h1>
    </body>
    </html>
  "

pub type NextHandle =
  fn(wisp.Request) -> wisp.Response

// When manifest file exists (Production), it will load all entries
fn manifest_entries() -> List(manifest.Entry) {
  let manifest_file = result.unwrap(template.has_manifest(), "")
  case context.get_orelse("manifest_entries", []) {
    [] if manifest_file != "" ->
      case template.read_file_lines(manifest_file) {
        "" -> []
        lines -> {
          let entries = manifest.parse(lines)
          context.add_entry("manifest_entries", entries)
          entries
        }
      }
    [] if manifest_file == "" -> []
    entries -> entries
  }
}

/// Initializes the inertia context
///
pub fn init(app: String, version: String) {
  context.add_entry("app", app)
  context.add_entry("version", version)
}

/// Gets an entry from the inertia context, if it not exists returns an empty String
///
pub fn from_context(name: String) -> String {
  context.get_orelse(name, "")
}

/// Add an entry to the inertia context
///
pub fn add_context(name: String, value: String) {
  context.add_entry(name, value)
}

/// Creates the root view based on index.html file when the request is a full page load.
/// If the index.html file is not found, it will render a default error message
///
pub fn root_view(state: String) -> String {
  let app_name = context.get_orelse("app", "")
  let pdir = result.unwrap(wisp.priv_directory(app_name), "")
  let entries = manifest_entries()

  case template.read_template(pdir) {
    Ok(content) -> template.parse_template(content, state, entries)
    _ -> error_view
  }
}

/// Handle request middleware that manages all Inertia requests
///
pub fn handle_request(req: wisp.Request, next: NextHandle) -> wisp.Response {
  next(req)
  |> wisp.set_header(inertia_header, "true")
  |> wisp.set_header("Vary", inertia_header)
  |> wisp.set_header("X-Inertia-Version", context.get_orelse("version", "v1"))
}

/// Adds a basic property to be injected on the client. The value must be a `json.Json` value
///
pub fn add_prop(
  self: props.PageObject,
  name: String,
  value: json.Json,
) -> props.PageObject {
  let new_props = list.append(self.props, [props.BaseProp(name, value)])
  props.PageObject(..self, props: new_props)
}

/// Adds an error property. The value must be a `json.Json` value
///
pub fn add_error(
  self: props.PageObject,
  name: String,
  value: json.Json,
) -> props.PageObject {
  let new_errors = list.append(self.errors, [props.ErrorProp(name, value)])
  props.PageObject(..self, errors: new_errors)
}

/// Adds an once property. The property value must be a function that returns a `json.Json` value.
///
pub fn add_once(
  self: props.PageObject,
  name: String,
  value: fn() -> json.Json,
) -> props.PageObject {
  let new_props = list.append(self.props, [props.OnceProp(name, value)])
  props.PageObject(..self, props: new_props)
}

/// Adds a deferred property. Usually, a deferred property is a time-consuming function that will take time
/// to generate its outcome. The property value is a function that returns `Result(json.Json, Nil)`
///
pub fn add_defer(
  self: props.PageObject,
  name: String,
  value: fn() -> Result(json.Json, Nil),
  group: Option(String),
) -> props.PageObject {
  let new_props =
    list.append(self.defers, [props.DeferProp(name, value, group)])
  props.PageObject(..self, defers: new_props)
}

/// Adds a Merge property
pub fn add_merge(
  self: props.PageObject,
  name: String,
  value: fn() -> json.Json,
) -> props.PageObject {
  let new_props = list.append(self.props, [props.MergeProp(name, value)])
  props.PageObject(..self, props: new_props)
}

/// Creates a page object that will manage all properties for the current page component.
///
pub fn new_page_object(
  req: wisp.Request,
  component: String,
) -> props.PageObject {
  props.PageObject(
    component:,
    url: req.path,
    props: list.new(),
    errors: list.new(),
    defers: list.new(),
    version: context.get_orelse("version", "v1"),
    clear_history: None,
  )
}

fn new_render_context(req: wisp.Request) -> props.RenderContext {
  let component =
    request.get_header(req, inertia_component) |> result.unwrap("")

  let excepts = case request.get_header(req, inertia_except) {
    Ok(str) -> string.split(str, ",")
    Error(_) -> []
  }

  let partials = case request.get_header(req, inertia_partial) {
    Ok(str) -> string.split(str, ",")
    Error(_) -> []
  }

  let resets = case request.get_header(req, inertia_reset) {
    Ok(str) -> string.split(str, ",")
    Error(_) -> []
  }

  let first_load = case component, partials {
    "", [] -> True
    _, _ -> False
  }
  let version = context.get_orelse("version", "v1")
  props.RenderContext(component, version, first_load, resets, partials, excepts)
}

/// Renders a Inertia component based on the PageObject.
///
/// #Example:
/// ```gleam
/// inertia.new_page_object(req, "index)
/// |> inertia.render(req)
/// ```
///
pub fn render(
  page_object: props.PageObject,
  req: wisp.Request,
) -> wisp.Response {
  let po =
    page_object
    |> props.page_object_to_json(new_render_context(req))
    |> json.to_string

  case request.get_header(req, inertia_header) {
    Ok(_) -> wisp.json_response(po, 200)
    _ -> wisp.ok() |> wisp.html_body(root_view(po))
  }
}

/// Creates a reponse with status code 303 for Post, Patch, Put or Delete request,
/// otherwise the status code is 302
///
/// #Example
/// ```gleam
/// inertia.redirect(req, "/")
/// ```
///
pub fn redirect(req: wisp.Request, path: String) -> wisp.Response {
  case req.method {
    Post | Put | Patch | Delete -> wisp.redirect(path)
    _ -> HttpResponse(302, [#("location", path)], Text(""))
  }
}
