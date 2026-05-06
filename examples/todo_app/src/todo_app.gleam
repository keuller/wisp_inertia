import gleam/erlang/process
import gleam/io
import inertia
import mist
import router
import sqlight
import task/repo
import wisp
import wisp/wisp_mist

@target(erlang)
pub fn main() -> Nil {
  use conn <- sqlight.with_connection("./todos.db")
  wisp.configure_logger()
  let assert Ok(Nil) = repo.init(conn)

  inertia.init("todo_app", "v1")

  let secret_key = wisp.random_string(32)

  let assert Ok(_) =
    wisp_mist.handler(router.handle_request(conn), secret_key)
    |> mist.new
    |> mist.bind("0.0.0.0")
    |> mist.port(4000)
    |> mist.start

  io.println("Server up and running")
  process.sleep_forever()
  // let assert Ok(_) = sqlight.close(conn)
}
