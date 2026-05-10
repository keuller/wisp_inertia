import gleam/dict
import gleam/dynamic/decode
import gleam/http/request
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import wisp.{type Request}

pub const inertia_flash_name = "inertia_flash"

pub type FlashProp {
  FlashProp(key: String, value: String)
}

fn flash_encode(prop: FlashProp) -> String {
  json.object([#(prop.key, json.string(prop.value))])
  |> json.to_string
}

fn set_cookie(value: String, req: Request) -> Request {
  request.Request(..req, headers: [#(inertia_flash_name, value), ..req.headers])
}

pub fn set_flash_message(req: Request, key: String, msg: String) -> Request {
  FlashProp(key, msg) |> flash_encode |> set_cookie(req)
}

pub fn set_flash_messages(req: Request, messages: List(FlashProp)) -> Request {
  messages
  |> list.map(fn(fp: FlashProp) { #(fp.key, json.string(fp.value)) })
  |> json.object
  |> json.to_string
  |> set_cookie(req)
}

pub fn get_flash(req: Request) -> Option(dict.Dict(String, String)) {
  case wisp.get_cookie(req, inertia_flash_name, wisp.PlainText) {
    Ok(res) -> {
      let dec = decode.dict(decode.string, decode.string)
      case json.parse(res, dec) {
        Ok(obj) -> Some(obj)
        Error(_) -> None
      }
    }
    Error(_) -> None
  }
}
