//// REST response shapes that expose git objects as git-compatible
//// content-addressable storage: the JSON and URL builders for blob, tree,
//// commit, ref, and commit-history responses.
////
//// Like `silt/object`, this module owns no persistence. Where a response must
//// walk child objects (recursive trees, commit history) the caller supplies a
//// `fetch` function — `fn(sha) -> Result(String, Nil)` — closing over its own
//// store and tenant.

import gleam/bit_array
import gleam/json
import gleam/list
import gleam/string
import silt/object.{type Commit, type Person, type TreeEntry, TreeEntry}

/// Resolve an object body by SHA. Supplied by the caller so response shaping
/// stays backend-agnostic.
pub type Fetch =
  fn(String) -> Result(String, Nil)

/// Build the REST response for a stored object of `kind`
/// (`"blobs"` | `"trees"` | `"commits"`). Recursive trees use `fetch` to walk
/// children.
pub fn object_response(
  base_url: String,
  tenant: String,
  kind: String,
  sha: String,
  body: String,
  recursive: Bool,
  fetch: Fetch,
) -> Result(json.Json, Nil) {
  case kind {
    "blobs" -> blob_response(base_url, tenant, sha, body)
    "trees" -> tree_response(base_url, tenant, sha, body, recursive, fetch)
    "commits" -> commit_response(base_url, tenant, sha, body)
    _ -> Error(Nil)
  }
}

/// Build the detailed commit response for a single commit body.
pub fn commit_details_response(
  base_url: String,
  tenant: String,
  sha: String,
  body: String,
) -> Result(json.Json, Nil) {
  case object.decode_commit(body) {
    Ok(commit) -> Ok(commit_details_json(base_url, tenant, sha, commit))
    Error(_) -> Error(Nil)
  }
}

/// Build the commit-history response, walking first parents up to `count`
/// commits via `fetch`.
pub fn commit_history_response(
  base_url: String,
  tenant: String,
  sha: String,
  count: Int,
  fetch: Fetch,
) -> List(json.Json) {
  collect_commit_history(base_url, tenant, sha, count, fetch)
}

/// Build a ref response for `ref` pointing at commit `sha`.
pub fn ref_response(
  base_url: String,
  tenant: String,
  ref: String,
  sha: String,
) -> json.Json {
  let ref = normalize_ref(ref)
  json.object([
    #("ref", json.string(ref)),
    #(
      "url",
      json.string(
        base_url
        <> "/repos/"
        <> tenant
        <> "/git/refs/"
        <> string.drop_start(ref, 5),
      ),
    ),
    #(
      "object",
      json.object([
        #("type", json.string("commit")),
        #("sha", json.string(sha)),
        #("url", json.string(object_url(base_url, tenant, "commits", sha))),
      ]),
    ),
  ])
}

/// Normalize a ref to its fully-qualified `refs/...` form.
pub fn normalize_ref(ref: String) -> String {
  case string.starts_with(ref, "refs/") {
    True -> ref
    False -> "refs/" <> ref
  }
}

fn blob_response(
  base_url: String,
  tenant: String,
  sha: String,
  body: String,
) -> Result(json.Json, Nil) {
  case object.decode_blob(body) {
    Error(_) -> Error(Nil)
    Ok(#(content, encoding)) ->
      case object.blob_content(content, encoding) {
        Error(_) -> Error(Nil)
        Ok(bytes) ->
          Ok(
            json.object([
              #("sha", json.string(sha)),
              #("size", json.int(bit_array.byte_size(bytes))),
              #("content", json.string(content)),
              #("encoding", json.string(encoding)),
              #("url", json.string(object_url(base_url, tenant, "blobs", sha))),
            ]),
          )
      }
  }
}

fn tree_response(
  base_url: String,
  tenant: String,
  sha: String,
  body: String,
  recursive: Bool,
  fetch: Fetch,
) -> Result(json.Json, Nil) {
  case object.decode_tree(body) {
    Error(_) -> Error(Nil)
    Ok(entries) -> {
      let entries = case recursive {
        True -> flatten_tree(fetch, "", entries, 64)
        False -> entries
      }
      Ok(
        json.object([
          #("sha", json.string(sha)),
          #("url", json.string(object_url(base_url, tenant, "trees", sha))),
          #(
            "tree",
            json.preprocessed_array(
              list.map(entries, fn(entry) {
                json.object([
                  #("path", json.string(entry.path)),
                  #("mode", json.string(entry.mode)),
                  #("type", json.string(entry.kind)),
                  #("size", json.int(entry.size)),
                  #("sha", json.string(entry.sha)),
                  #(
                    "url",
                    json.string(object_url(
                      base_url,
                      tenant,
                      entry.kind <> "s",
                      entry.sha,
                    )),
                  ),
                ])
              }),
            ),
          ),
        ]),
      )
    }
  }
}

fn flatten_tree(
  fetch: Fetch,
  prefix: String,
  entries: List(TreeEntry),
  depth: Int,
) -> List(TreeEntry) {
  list.flat_map(entries, fn(entry) {
    let path = case prefix {
      "" -> entry.path
      _ -> prefix <> "/" <> entry.path
    }
    let current = TreeEntry(..entry, path: path)
    case entry.kind, depth > 0 {
      "tree", True ->
        case fetch(entry.sha) {
          Ok(body) ->
            case object.decode_tree(body) {
              Ok(children) -> [
                current,
                ..flatten_tree(fetch, path, children, depth - 1)
              ]
              Error(_) -> [current]
            }
          Error(_) -> [current]
        }
      _, _ -> [current]
    }
  })
}

fn commit_response(
  base_url: String,
  tenant: String,
  sha: String,
  body: String,
) -> Result(json.Json, Nil) {
  case object.decode_commit(body) {
    Error(_) -> Error(Nil)
    Ok(commit) ->
      Ok(
        json.object([
          #("sha", json.string(sha)),
          #("url", json.string(object_url(base_url, tenant, "commits", sha))),
          #("author", person_json(commit.author)),
          #("committer", person_json(commit.committer)),
          #("message", json.string(commit.message)),
          #("tree", commit_hash_json(base_url, tenant, "trees", commit.tree)),
          #(
            "parents",
            json.preprocessed_array(
              list.map(commit.parents, commit_hash_json(
                base_url,
                tenant,
                "commits",
                _,
              )),
            ),
          ),
        ]),
      )
  }
}

fn collect_commit_history(
  base_url: String,
  tenant: String,
  sha: String,
  remaining: Int,
  fetch: Fetch,
) -> List(json.Json) {
  case remaining > 0, fetch(sha) {
    False, _ -> []
    _, Error(_) -> []
    True, Ok(body) ->
      case object.decode_commit(body) {
        Error(_) -> []
        Ok(commit) -> [
          commit_details_json(base_url, tenant, sha, commit),
          ..case commit.parents {
            [parent, ..] ->
              collect_commit_history(
                base_url,
                tenant,
                parent,
                remaining - 1,
                fetch,
              )
            [] -> []
          }
        ]
      }
  }
}

fn commit_details_json(
  base_url: String,
  tenant: String,
  sha: String,
  commit: Commit,
) -> json.Json {
  let commit_url = object_url(base_url, tenant, "commits", sha)
  json.object([
    #("sha", json.string(sha)),
    #("url", json.string(commit_url)),
    #(
      "commit",
      json.object([
        #("url", json.string(commit_url)),
        #("author", person_json(commit.author)),
        #("committer", person_json(commit.committer)),
        #("message", json.string(commit.message)),
        #("tree", commit_hash_json(base_url, tenant, "trees", commit.tree)),
      ]),
    ),
    #(
      "parents",
      json.preprocessed_array(
        list.map(commit.parents, commit_hash_json(
          base_url,
          tenant,
          "commits",
          _,
        )),
      ),
    ),
  ])
}

fn person_json(person: Person) -> json.Json {
  json.object([
    #("name", json.string(person.name)),
    #("email", json.string(person.email)),
    #("date", json.string(person.date)),
  ])
}

fn commit_hash_json(
  base_url: String,
  tenant: String,
  kind: String,
  sha: String,
) -> json.Json {
  json.object([
    #("sha", json.string(sha)),
    #("url", json.string(object_url(base_url, tenant, kind, sha))),
  ])
}

fn object_url(
  base_url: String,
  tenant: String,
  kind: String,
  sha: String,
) -> String {
  base_url <> "/repos/" <> tenant <> "/git/" <> kind <> "/" <> sha
}
