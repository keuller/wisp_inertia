import gleam/erlang/process
import gleam/io
import inertia
import mist
import router
import wisp
import wisp/wisp_mist

pub fn main() -> Nil {
  wisp.configure_logger()
  inertia.init("demo", "v1")
  let secret_key = wisp.random_string(32)

  inertia.shared_add("test", "Share message")

  let assert Ok(_) =
    wisp_mist.handler(router.handle_request, secret_key)
    |> mist.new
    |> mist.bind("0.0.0.0")
    |> mist.port(4000)
    |> mist.start

  io.println("Server up and running")
  process.sleep_forever()
}
