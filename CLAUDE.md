# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

silt is a pure-Gleam library of Fluid Framework git-object primitives — content-addressed blob/tree/commit objects with git-canonical SHA-1 ids, plus the REST response shapes that expose those objects as git-compatible content-addressable storage. Source in `src/silt/`, tests in `test/`. Consumed as a git-commit dependency (pinned `ref` in `gleam.toml`); **not published to Hex**.

## Design invariants

- **Byte-exact object ids.** Object ids depend on the exact serialization bytes. Blobs use git-canonical framing (`"blob " <len> \0 <content>`) so ids match real git; trees and commits hash their serialized body directly (the direct-body scheme). Do **not** change framing, header text, or hashing without recomputing every downstream id — a silent change breaks conformance.
- **No persistence.** `silt` is pure logic over content; it owns no store. Anything that must walk child objects (recursive trees, commit history) takes a caller-supplied `fetch: fn(sha) -> Result(body, Nil)`. Keep it that way (Levee ADR-005 / ADR-006).

## Layout

| Module | Contents |
|--------|----------|
| `silt/object` | Git object model + `object_id` (SHA-1) + `decode_*` body decoders |
| `silt/rest` | REST content-addressable storage response shapes (`object_response`, `commit_history_response`, `ref_response`) |
| `silt` | Convenience re-exports |

## Commands

```bash
gleam test     # startest suite
gleam check    # type-check
gleam format   # format
```

## Testing

Uses **startest** (not gleeunit). Gotcha: `let assert Pattern = expr` inside a startest test wraps the value in `Ok()` via startest's rescue mechanism — use a `case` expression to destructure `Result`/error variants instead.
