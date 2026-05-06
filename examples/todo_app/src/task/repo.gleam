import glanoid
import gleam/dynamic/decode
import sqlight
import task/task

fn new_id() -> String {
  let assert Ok(nanoid) = glanoid.make_generator("1234567ABCDEFGHIJKXQW")
  nanoid(5)
}

pub fn init(conn: sqlight.Connection) {
  let stmt =
    "
  CREATE TABLE IF NOT EXISTS tasks (
    id CHAR(5) NOT NULL PRIMARY KEY,
    title VARCHAR(50) NOT NULL,
    completed INT DEFAULT 0
  );
  "
  let assert Ok(Nil) = sqlight.exec(stmt, conn)
}

pub fn get_all(conn: sqlight.Connection) {
  let sql = "SELECT id, title, completed FROM tasks ORDER BY title"
  sqlight.query(sql, on: conn, with: [], expecting: task_decoder())
}

pub fn add_task(on: sqlight.Connection, t: task.Task) {
  let sql = "INSERT INTO tasks (id, title, completed) VALUES (?, ?, ?)"
  let with = [
    sqlight.text(new_id()),
    sqlight.text(t.title),
    sqlight.bool(t.completed),
  ]
  case sqlight.query(sql, on:, with:, expecting: none_result()) {
    Ok(_) -> True
    _ -> False
  }
}

pub fn delete_task(on: sqlight.Connection, id: String) {
  let sql = "DELETE FROM tasks WHERE id=?"
  case
    sqlight.query(sql, on:, with: [sqlight.text(id)], expecting: none_result())
  {
    Ok(_) -> True
    _ -> False
  }
}

fn none_result() -> decode.Decoder(Nil) {
  decode.success(Nil)
}

fn task_decoder() -> decode.Decoder(task.Task) {
  use id <- decode.field(0, decode.string)
  use title <- decode.field(1, decode.string)
  use completed <- decode.field(2, sqlight.decode_bool())
  decode.success(task.Task(id:, title:, completed:))
}
