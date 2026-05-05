import gleam/list
import gleeunit
import manifest

pub fn main() -> Nil {
  gleeunit.main()
}

pub fn parse_manifest_test() {
  let json =
    "{
      \"priv/app/app.ts\": {
        \"file\": \"assets/app-B3wvL0Rb.js\",
        \"name\": \"app\",
        \"isEntry\": true,
        \"css\": [
          \"assets/app-BnC28llm.css\"
        ]
      },
      \"priv/app/pages/about.vue\": {
        \"file\": \"assets/about-DT8H2rhZ.js\",
        \"name\": \"about\",
        \"isDynamicEntry\": true
      }
    }"

  let entries = manifest.parse(json)
  assert list.is_empty(entries) == False
  let assert Ok(e) = list.first(entries)
  assert e.name == "app"
  let assert Ok(c) = list.first(e.css)
  assert c != ""
}
