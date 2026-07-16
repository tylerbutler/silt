# silt

A **git-object** library for Gleam: content-addressed **blob / tree / commit**
objects with **git-canonical SHA-1** ids, plus the JSON/URL response shapes that
expose those objects as a **git-compatible content-addressable storage REST
API**.

`silt` is **pure logic over content** — it owns no persistence. Your stack keeps
its own store and calls `silt` for hashing, serialization, and response shaping.
Where a response must walk child objects (recursive trees, commit history) the
caller supplies a `fetch` function that closes over its own store.

Pure Gleam (`gleam_stdlib`, `gleam_json`, `gleam_crypto`) — no FFI. Uses
`gleam_crypto` for SHA-1. Runs on **both Gleam targets**: object ids are
byte-identical on Erlang and JavaScript.

## Modules

| Module | Contents |
|--------|----------|
| `silt/object` | Git object model: `Commit` / `TreeEntry` / `Person`, `object_id` (SHA-1), and the `decode_*` body decoders |
| `silt/rest` | REST response shapes exposing objects as content-addressable storage: `object_response`, `commit_history_response`, `ref_response` |
| `silt` | Convenience re-exports of the most-used API |

## Example

```gleam
import silt

// Content-addressed id for a blob body (git-canonical SHA-1).
let assert Ok(sha) =
  silt.object_id("blobs", "{\"content\":\"hello\",\"encoding\":\"utf-8\"}")

// Shape a stored object as a REST response. `fetch` resolves child objects
// from the caller's own store (only used by recursive trees / history).
let fetch = fn(sha) { my_store.get(tenant, sha) }
let response =
  silt.object_response(base_url, tenant, "trees", sha, body, True, fetch)
```
