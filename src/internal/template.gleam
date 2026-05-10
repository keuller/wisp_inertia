import file_streams/file_stream
import file_streams/file_stream_error
import gleam/erlang/application
import gleam/list
import gleam/result
import gleam/string
import globlin
import globlin_fs
import internal/context
import internal/errors
import internal/manifest
import simplifile

pub fn exist_template() -> Result(Bool, errors.InertiaError) {
  let assert Ok(pattern) = globlin.new_pattern("**/index.html")
  let files =
    globlin_fs.glob(pattern, returning: globlin_fs.RegularFiles)
    |> result.map_error(fn(_) { errors.FileError })

  case files {
    Ok([_]) -> Ok(True)
    _ -> Error(errors.TemplateNotFound)
  }
}

pub fn has_manifest() -> Result(String, errors.InertiaError) {
  let app_name = context.get_orelse("app", "")
  let assert Ok(app) = application.priv_directory(app_name)

  let assert Ok(pattern) = globlin.new_pattern("**/manifest.json")
  let files =
    globlin_fs.glob(pattern, returning: globlin_fs.RegularFiles)
    |> result.map_error(fn(_) { errors.FileError })

  case files {
    Ok([f]) -> Ok(f)
    _ ->
      case simplifile.is_file(app <> "/static/.vite/manifest.json") {
        Ok(True) -> Ok(app <> "/static/.vite/manifest.json")
        _ -> Error(errors.ManifestNotFound)
      }
  }
}

pub fn read_template(pdir: String) -> Result(String, errors.InertiaError) {
  case context.get_orelse("root_template", "") {
    "" -> {
      let tmpl = read_file_lines(pdir <> "/index.html")
      context.add_entry("root_template", tmpl)
      Ok(tmpl)
    }
    content -> Ok(content)
  }
}

pub fn read_file_lines(filename: String) -> String {
  let assert Ok(stream) = file_stream.open_read(filename)
  read_line(stream, []) |> string.join("")
}

fn read_line(
  stream: file_stream.FileStream,
  lines: List(String),
) -> List(String) {
  case file_stream.read_line(stream) {
    Ok(line) -> {
      read_line(stream, list.append(lines, [line]))
    }
    Error(file_stream_error.Eof) -> lines
    _ -> lines
  }
}

pub fn parse_template(
  tmpl: String,
  state: String,
  entries: List(manifest.Entry),
) -> String {
  let body_content =
    case entries {
      [] -> [
        "<script data-page=\"app\" type=\"application/json\">",
        state,
        "</script>",
        "<div id='app'></div>",
        "<script type=\"module\" src=\"//localhost:5173/priv/app/app.ts\"></script>",
      ]
      _ -> [
        "<script data-page=\"app\" type=\"application/json\">",
        state,
        "</script>",
        "<div id=\"app\"></div>",
        generate_app_entry(entries),
      ]
    }
    |> string.join("\n")

  string.replace(
    string.replace(tmpl, "<!-- @inertiaHead -->", head_tags(entries)),
    "<!-- @inertia -->",
    body_content,
  )
}

fn head_tags(entries: List(manifest.Entry)) -> String {
  case entries {
    [] ->
      [
        "<script type=\"module\" src='//localhost:5173/@vite/client'></script>",
      ]
      |> string.join("\n")
    _ -> generate_head_entries(entries)
  }
}

fn generate_head_entries(entries: List(manifest.Entry)) -> String {
  entries
  |> list.map(fn(e: manifest.Entry) {
    case e.is_dynamic {
      True -> generate_preload_tag(e.file)
      False ->
        case e.css {
          [] -> ""
          [css] -> generate_css_tag(css)
          _ ->
            list.map(e.css, generate_css_tag)
            |> string.join("\n")
        }
    }
  })
  |> string.join("\n")
}

fn generate_css_tag(file: String) -> String {
  "<link rel=\"stylesheet\" href=\"/static/" <> file <> "\" />"
}

fn generate_preload_tag(file: String) -> String {
  "<link rel=\"modulepreload\" as=\"script\" href=\"/static/" <> file <> "\" />"
}

fn generate_app_entry(entries: List(manifest.Entry)) -> String {
  entries
  |> list.filter(fn(e: manifest.Entry) { e.is_entry })
  |> list.map(fn(e: manifest.Entry) {
    "<script type=\"module\" src=\"/static/" <> e.file <> "\"></script>"
  })
  |> string.join("\n")
}
