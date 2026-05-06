import gleam/dynamic/decode
import gleam/json

pub type Task {
  Task(id: String, title: String, completed: Bool)
}

pub type TaskInput {
  TaskInput(title: String)
}

pub fn task_decoder() -> decode.Decoder(Task) {
  use id <- decode.field("id", decode.string)
  use title <- decode.field("title", decode.string)
  use completed <- decode.field("completed", decode.bool)
  decode.success(Task(id:, title:, completed:))
}

pub fn task_input_decoder() -> decode.Decoder(TaskInput) {
  use title <- decode.field("title", decode.string)
  decode.success(TaskInput(title:))
}

pub fn task_json(t: Task) -> json.Json {
  json.object([
    #("id", json.string(t.id)),
    #("title", json.string(t.title)),
    #("completed", json.bool(t.completed)),
  ])
}
