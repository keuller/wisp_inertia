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
