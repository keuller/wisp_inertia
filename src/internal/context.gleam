import gleam/dict

const inertia_shared_name = "inertia_shared"

/// Erase the value referenced by `key`.
///
/// Returns `True` if there was a value, `False` otherwise.
@external(erlang, "context_ffi", "ctx_erase")
pub fn erase(key: String) -> Bool

/// Retrieve the value referenced by `key`.
@external(erlang, "context_ffi", "ctx_get")
fn get(key: String) -> Result(a, Nil)

/// Stores the `value` as referenced by `key`.
///
/// This returns the stored value.
@external(erlang, "context_ffi", "ctx_add")
fn add(key: String, value: a) -> a

@external(erlang, "context_ffi", "sharedctx_add")
fn shared_add(key: String, value: a) -> a

@external(erlang, "context_ffi", "sharedctx_get")
fn shared_get(key: String) -> Result(a, Nil)

/// Retrieve the value referenced by `key` or `default` if not present.
pub fn get_orelse(key key: String, or default: a) -> a {
  case get(key) {
    Ok(a) -> a
    Error(Nil) -> default
  }
}

/// Stores the `value` as referenced by `key` only if no value is already
/// present.
///
/// This returns the stored value.
pub fn add_entry(key: String, value: a) {
  case get(key) {
    Error(Nil) -> {
      add(key, value)
      Nil
    }
    _ -> Nil
  }
}

/// Adds a value as a share property to Inertia context
///
pub fn shared_add_entry(key: String, value: a) {
  case shared_get(key) {
    Error(Nil) -> {
      let ctx = dict.new()
      let new_ctx = dict.insert(ctx, key, value)
      shared_add(inertia_shared_name, new_ctx)
      Nil
    }
    Ok(shared_ctx) -> {
      case shared_ctx {
        Ok(ctx) -> {
          let new_ctx = dict.insert(ctx, key, value)
          shared_add(inertia_shared_name, new_ctx)
          Nil
        }
        _ -> Nil
      }
    }
  }
}

/// Gets a value of share property from Inertia context, or return a default value
/// if the property does not exists
///
pub fn shared_get_orelse(key key: String, or default: a) -> a {
  case shared_get(inertia_shared_name) {
    Ok(ctx) -> {
      case dict.get(ctx, key) {
        Ok(val) -> val
        Error(_) -> default
      }
    }
    Error(Nil) -> default
  }
}

pub fn shared_get_all() -> dict.Dict(String, String) {
  case shared_get(inertia_shared_name) {
    Ok(ctx) -> ctx
    Error(Nil) -> dict.new()
  }
}
