import gleam/dict
import gleam/dynamic/decode
import gleam/json

pub type Entry {
  Entry(
    name: String,
    file: String,
    css: List(String),
    is_entry: Bool,
    is_dynamic: Bool,
  )
}

// Entry decoder
pub fn entry_decoder() -> decode.Decoder(Entry) {
  use name <- decode.field("name", decode.string)
  use file <- decode.field("file", decode.string)
  use is_entry <- decode.optional_field("isEntry", False, decode.bool)
  use is_dynamic <- decode.optional_field("isDynamicEntry", False, decode.bool)
  use css <- decode.optional_field("css", [], decode.list(of: decode.string))
  decode.success(Entry(name:, file:, css:, is_entry:, is_dynamic:))
}

pub fn parse(value: String) -> List(Entry) {
  case json.parse(value, decode.dict(decode.string, entry_decoder())) {
    Ok(e) -> dict.values(e)
    _ -> []
  }
}
