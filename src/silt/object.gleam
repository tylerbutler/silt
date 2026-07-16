//// The git object model: content-addressed blob / tree / commit values with
//// **git-canonical SHA-1** ids and their JSON (de)serialization.
////
//// This module is pure logic over content — given a body it computes the
//// object id and decodes it into typed values. It owns **no** persistence;
//// callers keep their own store and use `object_id` for hashing and the
//// `decode_*` helpers for reading bodies back. Consolidated from
//// `floodgate/git` and Levee's `levee_storage` SHA schemes — see Levee ADR-006.

import gleam/bit_array
import gleam/crypto
import gleam/dynamic/decode
import gleam/int
import gleam/json
import gleam/result
import gleam/string

/// A commit author / committer identity.
pub type Person {
  Person(name: String, email: String, date: String)
}

/// A single entry within a tree object.
pub type TreeEntry {
  TreeEntry(path: String, mode: String, kind: String, size: Int, sha: String)
}

/// A decoded commit object.
pub type Commit {
  Commit(
    tree: String,
    parents: List(String),
    message: String,
    author: Person,
    committer: Person,
  )
}

/// Compute the content-addressed id for an object body of the given `kind`.
///
/// `kind` is the plural REST form: `"blobs"`, `"trees"`, or `"commits"`.
/// Blobs use git-canonical framing (`"blob " <len> \0 <content>`) so ids match
/// real git object ids; trees and commits hash their serialized body directly
/// (the direct-body scheme). Any other kind is an `Error(Nil)`.
pub fn object_id(kind: String, body: String) -> Result(String, Nil) {
  case kind {
    "blobs" -> blob_sha(body)
    "trees" | "commits" -> Ok(sha1(bit_array.from_string(body)))
    _ -> Error(Nil)
  }
}

/// Lowercase hex SHA-1 of the given bytes.
pub fn sha1(body: BitArray) -> String {
  crypto.hash(crypto.Sha1, body)
  |> bit_array.base16_encode
  |> string.lowercase
}

/// Git-canonical SHA-1 id for a blob's raw content bytes
/// (`sha1("blob " <len> \0 <content>)`) — a real git object id. Use this when
/// you already hold the content bytes; use `object_id("blobs", ...)` when you
/// hold a `{content, encoding}` JSON body.
pub fn blob_id(content: BitArray) -> String {
  let header_text =
    "blob " <> int.to_string(bit_array.byte_size(content)) <> "\u{0000}"
  let header = bit_array.from_string(header_text)
  sha1(bit_array.concat([header, content]))
}

/// Git-canonical SHA-1 of a blob body (a `{content, encoding}` JSON payload).
fn blob_sha(body: String) -> Result(String, Nil) {
  use #(content, encoding) <- result.try(decode_blob(body))
  use bytes <- result.try(blob_content(content, encoding))
  Ok(blob_id(bytes))
}

/// Decode the raw bytes carried by a blob body given its declared encoding
/// (`"utf-8"` or `"base64"`).
pub fn blob_content(content: String, encoding: String) -> Result(BitArray, Nil) {
  case encoding {
    "base64" -> bit_array.base64_decode(content)
    "utf-8" -> Ok(bit_array.from_string(content))
    _ -> Error(Nil)
  }
}

/// Decode a blob body into its `#(content, encoding)`.
pub fn decode_blob(body: String) -> Result(#(String, String), Nil) {
  let decoder = {
    use content <- decode.field("content", decode.string)
    use encoding <- decode.optional_field("encoding", "utf-8", decode.string)
    decode.success(#(content, encoding))
  }
  json.parse(body, decoder) |> result.replace_error(Nil)
}

/// Decode a tree body into its entries.
pub fn decode_tree(body: String) -> Result(List(TreeEntry), Nil) {
  let decoder = {
    use entries <- decode.field("tree", decode.list(tree_entry_decoder()))
    decode.success(entries)
  }
  json.parse(body, decoder) |> result.replace_error(Nil)
}

/// Decode a commit body.
pub fn decode_commit(body: String) -> Result(Commit, Nil) {
  let decoder = {
    use tree <- decode.field("tree", decode.string)
    use parents <- decode.optional_field(
      "parents",
      [],
      decode.list(decode.string),
    )
    use message <- decode.optional_field("message", "", decode.string)
    use author <- decode.field("author", person_decoder())
    use committer <- decode.optional_field(
      "committer",
      author,
      person_decoder(),
    )
    decode.success(Commit(tree, parents, message, author, committer))
  }
  json.parse(body, decoder) |> result.replace_error(Nil)
}

/// Decode a ref-update body into `#(ref, sha)`.
pub fn decode_ref(body: String) -> Result(#(String, String), Nil) {
  let decoder = {
    use ref <- decode.field("ref", decode.string)
    use sha <- decode.field("sha", decode.string)
    decode.success(#(ref, sha))
  }
  json.parse(body, decoder) |> result.replace_error(Nil)
}

fn tree_entry_decoder() {
  use path <- decode.field("path", decode.string)
  use mode <- decode.optional_field("mode", "100644", decode.string)
  use kind <- decode.optional_field("type", "blob", decode.string)
  use size <- decode.optional_field("size", 0, decode.int)
  use sha <- decode.field("sha", decode.string)
  decode.success(TreeEntry(path, mode, kind, size, sha))
}

fn person_decoder() {
  use name <- decode.optional_field("name", "", decode.string)
  use email <- decode.optional_field("email", "", decode.string)
  use date <- decode.optional_field("date", "", decode.string)
  decode.success(Person(name, email, date))
}
