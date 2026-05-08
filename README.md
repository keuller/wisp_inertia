# Inertia.js adapter for Gleam/Wisp

[![Package Version](https://img.shields.io/hexpm/v/wisp_inertia)](https://hex.pm/packages/wisp_inertia)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/wisp_inertia/)

## Roadmap

This adapter implements Inertia v3 [protocol](https://inertiajs.com/docs/v3/core-concepts/the-protocol). Currently, it is not implementing all features.

- [X] Once Props
- [X] Deferred Props
- [X] Merge Props
- [ ] Scroll Props
- [ ] Flash Data
- [ ] SSR
- [X] Examples

## Installation
```sh
gleam add wisp_inertia
```

## Usage
```sh
mkdir demo && cd demo
gleam new demo --skip-git --skip-github
```

```gleam
// server.gleam file

import inertia

pub fn main() -> Nil {
  wisp.configure_logger()
  inertia.init("demo", "v1")
  let secret_key = wisp.random_string(32)

  let assert Ok(_) =
    wisp_mist.handler(router.handle_request, secret_key)
    |> mist.new
    |> mist.bind("0.0.0.0")
    |> mist.port(4000)
    |> mist.start

  io.println("Server up and running")
  process.sleep_forever()
}
```

```gleam
// middleware.gleam file

import inertia
import wisp.{type Request, type Response}

pub fn register(req: Request, handle_req: fn(Request) -> Response) -> Response {
  let assert Ok(priv_dir) = wisp.priv_directory("demo")

  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes
  use <- wisp.serve_static(req, under: "/static", from: priv_dir <> "/static")
  use req <- wisp.handle_head(req)
  use req <- inertia.handle_request(req)

  handle_req(req)
}
```
> Make sure that you have created a `priv/static` folder for static assets.


```gleam
// router.gleam file
import gleam/json
import inertia
import wisp.{type Request, type Response}

pub fn handle_request(req: Request) -> Response {
  use req <- middleware.register(req)
  let segments = wisp.path_segments(req)

  case segments {
    [] -> handle_index(req)
    _ -> wisp.not_found()
  }
}

fn handle_index(req: wisp.Request) -> wisp.Response {
  inertia.new_page_object(req, "index")
  |> inertia.add_prop("title", json.string("Home Page"))
  |> inertia.render(req)
}
```

## Client 
Inside the `priv` folder, you must to create the following structure for the client.
```sh
priv
├── app
│   ├── pages
│   │   └── index.vue
│   └── shared
└── static
```

* `app` folder is the roo of client assets, and it will contain all you view components (e.g. Vue, Svelte or React files)
* `static` folder will be used as production-ready static assets.
* `shared`folder is optional, but it's recommended to add your shared components there

The root HTML template file must have this content. The special comments `!-- @inertiaHead --` and `!-- @inertia --` will be replaced by the HTML tags for Inertia.

```html
// priv/index.html

<!doctype html>
<html lang="en">
  <head>
      <meta charset="UTF-8" />
      <meta name="viewport" content="width=device-width, initial-scale=1.0" />
      <!-- @inertiaHead -->
  </head>
  <body>
      <!-- @inertia -->
  </body>
</html>

```

```typescript
// priv/app/app.ts file

import { createInertiaApp } from "@inertiajs/vue3";
import "./app.css";

createInertiaApp({
  pages: {
    path: "./pages",
    lazy: true,
  },
});
```

```vue
// priv/pages/index.vue

<script setup lang="ts">
defineProps({
  title: String,
});
</script>

<template>
  <h1>{{ title }}</h1>
</template>
```

Further documentation can be found at <https://hexdocs.pm/wisp_inertia>.

## Development

```sh
gleam run   # Run the project
gleam test  # Run the tests
```

## Examples

- [Demo](examples/demo)
- [Simple Todo](examples/todo_app)

## Other Community Adapters

Full list of community adapters is located on [inertiajs.com](https://inertiajs.com/docs/v3/installation/community-adapters).

## License

`wisp_inertia` is released under the [Apache 2.0] License.
