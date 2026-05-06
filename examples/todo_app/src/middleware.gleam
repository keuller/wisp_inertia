import inertia
import wisp.{type Request, type Response}

pub fn register(req: Request, handle_req: fn(Request) -> Response) -> Response {
  let assert Ok(priv_dir) = wisp.priv_directory("todo_app")

  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes
  use <- wisp.serve_static(req, under: "/static", from: priv_dir <> "/static")
  use req <- wisp.handle_head(req)
  use req <- inertia.handle_request(req)

  handle_req(req)
}
