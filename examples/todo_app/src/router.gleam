import gleam/dynamic/decode
import gleam/http.{Delete, Get, Post}
import gleam/json
import inertia
import middleware
import sqlight
import task/repo
import task/task
import wisp.{type Request, type Response}

pub fn handle_request(conn: sqlight.Connection) -> fn(Request) -> Response {
  fn(req: Request) -> Response {
    use req <- middleware.register(req)
    let segments = wisp.path_segments(req)

    case req.method, segments {
      Get, [] -> handle_index(req, conn)
      Post, [] -> handle_add_task(req, conn)
      Delete, [id] -> handle_delete_task(req, conn, id)
      _, _ -> wisp.not_found()
    }
  }
}

fn handle_index(req: wisp.Request, conn: sqlight.Connection) -> wisp.Response {
  let assert Ok(tasks) = repo.get_all(conn)
  inertia.new_page_object(req, "index")
  |> inertia.add_prop("tasks", json.array(tasks, task.task_json))
  |> inertia.render(req)
}

fn handle_add_task(
  req: wisp.Request,
  conn: sqlight.Connection,
) -> wisp.Response {
  use json_data <- wisp.require_json(req)

  case decode.run(json_data, task.task_input_decoder()) {
    Ok(t) -> {
      echo "Title: " <> t.title
      repo.add_task(conn, task.Task(id: "", title: t.title, completed: False))
      inertia.redirect(req, "/")
    }
    Error(errs) -> {
      echo errs
      wisp.unprocessable_content()
    }
  }
}

fn handle_delete_task(
  req: wisp.Request,
  conn: sqlight.Connection,
  id: String,
) -> wisp.Response {
  repo.delete_task(conn, id)
  inertia.redirect(req, "/")
}
