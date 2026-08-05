import gleam/dict
import gleam/json
import gleam/list
import gleam/string
import silt
import silt/object.{Commit, Person, TreeEntry}
import silt/rest
import startest
import startest/expect

pub fn main() -> Nil {
  startest.run(startest.default_config())
}

/// A `fetch` backed by an in-memory dict, for exercising the recursive
/// REST response shapes without a real store.
fn dict_fetch(objects: dict.Dict(String, String)) -> rest.Fetch {
  fn(sha) {
    case dict.get(objects, sha) {
      Ok(body) -> Ok(body)
      Error(_) -> Error(Nil)
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Object ids (git-canonical SHA-1)
// ─────────────────────────────────────────────────────────────────────────────

pub fn blob_object_id_matches_git_test() {
  // `printf 'blob 5\0hello' | sha1sum` — real git object id.
  silt.object_id("blobs", "{\"content\":\"hello\",\"encoding\":\"utf-8\"}")
  |> expect.to_equal(Ok("b6fc4c620b67d95f953a5c1c1230aaab5db5a1b0"))
}

pub fn blob_id_from_bytes_matches_git_test() {
  // Same real git object id, computed straight from the content bytes.
  object.blob_id(<<"hello">>)
  |> expect.to_equal("b6fc4c620b67d95f953a5c1c1230aaab5db5a1b0")
}

pub fn blob_object_id_base64_matches_utf8_test() {
  // "hello" base64-encoded frames to the same bytes, so the same id.
  silt.object_id("blobs", "{\"content\":\"aGVsbG8=\",\"encoding\":\"base64\"}")
  |> expect.to_equal(Ok("b6fc4c620b67d95f953a5c1c1230aaab5db5a1b0"))
}

pub fn tree_object_id_is_deterministic_test() {
  let body = "{\"tree\":[]}"
  let id = silt.object_id("trees", body)
  id |> expect.to_be_ok()
  silt.object_id("trees", body) |> expect.to_equal(id)
}

pub fn object_id_rejects_unknown_kind_test() {
  silt.object_id("tags", "{}") |> expect.to_equal(Error(Nil))
}

// ─────────────────────────────────────────────────────────────────────────────
// Decoders
// ─────────────────────────────────────────────────────────────────────────────

pub fn decode_blob_test() {
  object.decode_blob("{\"content\":\"hi\",\"encoding\":\"utf-8\"}")
  |> expect.to_equal(Ok(#("hi", "utf-8")))
}

pub fn decode_blob_defaults_encoding_test() {
  object.decode_blob("{\"content\":\"hi\"}")
  |> expect.to_equal(Ok(#("hi", "utf-8")))
}

pub fn decode_tree_test() {
  object.decode_tree(
    "{\"tree\":[{\"path\":\"a.txt\",\"type\":\"blob\",\"sha\":\"s1\"}]}",
  )
  |> expect.to_equal(Ok([TreeEntry("a.txt", "100644", "blob", 0, "s1")]))
}

pub fn decode_commit_defaults_committer_to_author_test() {
  let body =
    "{\"tree\":\"t1\",\"author\":{\"name\":\"Ada\",\"email\":\"a@x\",\"date\":\"now\"}}"
  object.decode_commit(body)
  |> expect.to_equal(
    Ok(Commit(
      "t1",
      [],
      "",
      Person("Ada", "a@x", "now"),
      Person("Ada", "a@x", "now"),
    )),
  )
}

/// The Historian `ICreateCommitParams` types `date` as a string, but real
/// callers send Unix seconds — levee's GitController passes the field through
/// untouched, so a numeric date round-trips there. Accept either and normalise
/// to a string rather than rejecting a commit that could have been stored.
pub fn decode_commit_accepts_numeric_author_date_test() {
  let body =
    "{\"tree\":\"t1\",\"author\":{\"name\":\"Ada\",\"email\":\"a@x\",\"date\":1767225600}}"
  object.decode_commit(body)
  |> expect.to_equal(
    Ok(Commit(
      "t1",
      [],
      "",
      Person("Ada", "a@x", "1767225600"),
      Person("Ada", "a@x", "1767225600"),
    )),
  )
}

pub fn decode_ref_test() {
  silt.decode_ref("{\"ref\":\"refs/heads/main\",\"sha\":\"abc\"}")
  |> expect.to_equal(Ok(#("refs/heads/main", "abc")))
}

// ─────────────────────────────────────────────────────────────────────────────
// REST response shapes
// ─────────────────────────────────────────────────────────────────────────────

pub fn normalize_ref_qualifies_bare_refs_test() {
  rest.normalize_ref("heads/main")
  |> expect.to_equal("refs/heads/main")
  rest.normalize_ref("refs/heads/main")
  |> expect.to_equal("refs/heads/main")
}

pub fn ref_response_shape_test() {
  silt.ref_response("http://h", "t", "heads/main", "abc")
  |> json.to_string
  |> expect.to_equal(
    "{\"ref\":\"refs/heads/main\","
    <> "\"url\":\"http://h/repos/t/git/refs/heads/main\","
    <> "\"object\":{\"type\":\"commit\",\"sha\":\"abc\","
    <> "\"url\":\"http://h/repos/t/git/commits/abc\"}}",
  )
}

pub fn blob_object_response_shape_test() {
  let response =
    silt.object_response(
      "http://h",
      "t",
      "blobs",
      "s1",
      "{\"content\":\"hi\",\"encoding\":\"utf-8\"}",
      False,
      dict_fetch(dict.new()),
    )
  case response {
    Ok(body) ->
      json.to_string(body)
      |> expect.to_equal(
        "{\"sha\":\"s1\",\"size\":2,\"content\":\"hi\","
        <> "\"encoding\":\"utf-8\",\"url\":\"http://h/repos/t/git/blobs/s1\"}",
      )
    Error(_) -> panic as "expected Ok blob response"
  }
}

pub fn recursive_tree_response_flattens_children_test() {
  let child =
    "{\"tree\":[{\"path\":\"b.txt\",\"type\":\"blob\",\"sha\":\"bsha\"}]}"
  let root =
    "{\"tree\":["
    <> "{\"path\":\"dir\",\"type\":\"tree\",\"sha\":\"child\"},"
    <> "{\"path\":\"a.txt\",\"type\":\"blob\",\"sha\":\"asha\"}]}"
  let fetch = dict_fetch(dict.from_list([#("child", child)]))
  let response =
    silt.object_response("http://h", "t", "trees", "root", root, True, fetch)
  case response {
    // The nested entry is emitted with a prefixed path.
    Ok(body) ->
      json.to_string(body)
      |> string.contains("\"path\":\"dir/b.txt\"")
      |> expect.to_be_true()
    Error(_) -> panic as "expected Ok tree response"
  }
}

pub fn commit_history_walks_parents_test() {
  let c1 = "{\"tree\":\"t1\",\"author\":{\"name\":\"Ada\"}}"
  let c2 =
    "{\"tree\":\"t2\",\"parents\":[\"c1\"],\"author\":{\"name\":\"Ada\"}}"
  let fetch = dict_fetch(dict.from_list([#("c1", c1), #("c2", c2)]))
  rest.commit_history_response("http://h", "t", "c2", 10, fetch)
  |> list.length
  |> expect.to_equal(2)
}

pub fn commit_history_respects_count_test() {
  let c1 = "{\"tree\":\"t1\",\"author\":{\"name\":\"Ada\"}}"
  let c2 =
    "{\"tree\":\"t2\",\"parents\":[\"c1\"],\"author\":{\"name\":\"Ada\"}}"
  let fetch = dict_fetch(dict.from_list([#("c1", c1), #("c2", c2)]))
  rest.commit_history_response("http://h", "t", "c2", 1, fetch)
  |> list.length
  |> expect.to_equal(1)
}
