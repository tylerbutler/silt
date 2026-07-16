//// silt — a shared git-object + Historian library.
////
//// Convenience re-exports of the most-used API. The full surface lives in
//// `silt/object` (the content-addressed git object model + SHA-1 ids) and
//// `silt/historian` (the Routerlicious-compatible response shapes).

import gleam/json
import silt/historian
import silt/object

pub type Commit =
  object.Commit

pub type TreeEntry =
  object.TreeEntry

pub type Person =
  object.Person

/// A `fn(sha) -> Result(body, Nil)` supplied by callers so Historian shaping
/// stays backend-agnostic.
pub type Fetch =
  historian.Fetch

/// Compute the content-addressed id for an object body of the given kind
/// (`"blobs"` | `"trees"` | `"commits"`). Blobs use git-canonical framing.
pub fn object_id(kind: String, body: String) -> Result(String, Nil) {
  object.object_id(kind, body)
}

/// Build the Historian response for a stored object. Recursive trees walk
/// children via `fetch`.
pub fn object_response(
  base_url: String,
  tenant: String,
  kind: String,
  sha: String,
  body: String,
  recursive: Bool,
  fetch: Fetch,
) -> Result(json.Json, Nil) {
  historian.object_response(base_url, tenant, kind, sha, body, recursive, fetch)
}

/// Build a ref response for `ref` pointing at commit `sha`.
pub fn ref_response(
  base_url: String,
  tenant: String,
  ref: String,
  sha: String,
) -> json.Json {
  historian.ref_response(base_url, tenant, ref, sha)
}

/// Decode a ref-update body into `#(ref, sha)`.
pub fn decode_ref(body: String) -> Result(#(String, String), Nil) {
  object.decode_ref(body)
}
