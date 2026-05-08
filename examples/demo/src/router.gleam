import gleam/erlang/process
import gleam/json
import gleam/option
import gleam/time/calendar
import gleam/time/timestamp
import inertia
import middleware
import wisp.{type Request, type Response}

pub type Message {
  Message(text: String, created_on: String)
}

pub type Contact {
  Contact(id: String, name: String, email: String)
}

fn new_message() -> Message {
  let date_time =
    timestamp.system_time() |> timestamp.to_rfc3339(calendar.utc_offset)
  Message("Message...", date_time)
}

fn message_to_json(msg: Message) -> json.Json {
  json.object([
    #("text", json.string(msg.text)),
    #("created_on", json.string(msg.created_on)),
  ])
}

fn get_contacts() -> List(Contact) {
  process.sleep(1000)
  [
    Contact("12345", "Sheldon Cooper", "sheldon.cooper@caltech.co"),
    Contact("13579", "Leonard Hofstadter", "leonard.hofstadter@caltech.co"),
    Contact("54321", "Howard Wolowitz", "howard.wolowitz@mit.co"),
    Contact("24680", "Rajesh Kootrapalli", "rajesh.kootrapalli@caltech.co"),
  ]
}

fn contact_to_json(contact: Contact) -> json.Json {
  json.object([
    #("id", json.string(contact.id)),
    #("name", json.string(contact.name)),
    #("email", json.string(contact.email)),
  ])
}

pub fn handle_request(req: Request) -> Response {
  use req <- middleware.register(req)
  let segments = wisp.path_segments(req)

  case segments {
    [] -> handle_index(req)
    _ -> wisp.not_found()
  }
}

fn handle_index(req: wisp.Request) -> wisp.Response {
  let gen = fn() { json.array([new_message()], of: message_to_json) }

  inertia.new_page_object(req, "index")
  |> inertia.add_prop("title", json.string("Simple Demo"))
  |> inertia.add_merge("messages", gen)
  |> inertia.add_defer(
    "contacts",
    fn() { Ok(json.array(get_contacts(), of: contact_to_json)) },
    option.None,
  )
  |> inertia.render(req)
}
