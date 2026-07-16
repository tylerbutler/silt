# silt

A shared **git-object + Historian** library for Gleam: content-addressed
**blob / tree / commit** objects with **git-canonical SHA-1** ids, and the
**Routerlicious-compatible Historian** JSON/URL response shapes that expose
those objects as document summaries/snapshots.

`silt` is the shared object domain consolidated out of two duplicate — and
drifted — implementations: Floodgate's `floodgate/git` (SHA-1, git-canonical
framing) and Levee's `levee_storage` / `git_controller` (SHA-256 of JSON). Both
server stacks now compute the **same, git-compatible object ids** and produce
the **same Historian responses** against one codebase. See Levee ADR-006.

`silt` is **pure logic over content** — it owns no persistence. Each stack keeps
its own store and calls `silt` for hashing, serialization, and response shaping
(per Levee ADR-005). Where a response must walk child objects (recursive trees,
commit history) the caller supplies a `fetch` function that closes over its own
store.

Pure Gleam (`gleam_stdlib`, `gleam_json`, `gleam_crypto`) — no FFI. Uses
`gleam_crypto` for SHA-1.

## Modules

| Module | Contents |
|--------|----------|
| `silt/object` | Git object model: `Commit` / `TreeEntry` / `Person`, `object_id` (SHA-1), and the `decode_*` body decoders |
| `silt/historian` | Routerlicious Historian response shapes: `object_response`, `commit_history_response`, `ref_response`, `decode_ref` |
| `silt` | Convenience re-exports of the most-used API |

## Example

```gleam
import silt
import silt/historian

// Content-addressed id for a blob body (git-canonical SHA-1).
let assert Ok(sha) =
  silt.object_id("blobs", "{\"content\":\"hello\",\"encoding\":\"utf-8\"}")

// Shape a stored object as a Historian response. `fetch` resolves child
// objects from the caller's own store (only used by recursive trees / history).
let fetch = fn(sha) { my_store.get(tenant, sha) }
let response =
  silt.object_response(base_url, tenant, "trees", sha, body, True, fetch)
```
