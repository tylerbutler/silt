# Product

## Register

brand

## Platform

web

## Users
Gleam developers who land cold — most have never heard of silt. Some arrive from the Fluid Framework family of projects (Levee, Floodgate) and already know why byte-exact git object ids matter; most do not. The site is designed for the cold reader first: someone comfortable with Gleam and with git as a tool, but who needs to understand *what content-addressed git objects are* and *why an exact-match implementation is worth pinning* before the API means anything. Their context is evaluation — a browser tab open beside their editor, deciding in a couple of minutes whether this belongs in their `gleam.toml`.

## Product Purpose
silt is a pure-Gleam library that turns content into byte-exact, content-addressed git objects — blob, tree, and commit values whose SHA-1 ids match real git, exactly — and provides the response shapes for a REST API that exposes those objects as git-compatible content-addressable storage. It owns no persistence: callers keep their own store and hand silt a `fetch` function when a response must walk child objects. Success is a Gleam developer understanding the shape and the guarantees in under two minutes and adding the git dependency with confidence that the ids will match everywhere.

## Positioning
Byte-exact git object ids and the response shapes for a git-compatible content-addressable storage REST API — pure Gleam, owns no store.

## Conversion & proof
- Primary CTA: copy the `gleam.toml` git-dependency line (the repo is the product — silt ships as a pinned git dependency, not on Hex).
- Secondary CTA: read the API reference (`silt/object`, `silt/historian`).
- The line a visitor remembers after 10 seconds: "Byte-exact git object ids, in pure Gleam."
- Belief ladder: (1) I understand what a content-addressed git object is → (2) silt's ids match *real git*, exactly → (3) it's pure logic with no persistence, so it drops cleanly into my stack → (4) here is the one-line git dependency and the API surface → act.
- Proof on hand: the guarantees are self-evident from the code and are demonstrable — the hero shows a real body → real SHA-1 the visitor can reproduce with `git hash-object`. No testimonials or logos; credibility is carried by exactness, not endorsement.

## Brand Personality
Precise, elemental, unshowy. The voice is that of infrastructure that is sure of itself: it states the guarantee plainly and lets the exactness do the persuading. Confident without hype, technical without costume. The one indulgence is the governing metaphor — silt is the fine sediment that settles out of moving water — used as a genuine lens on content-addressing (content settles into deterministic layers and a stable id), never as decoration for its own sake.

## Anti-references
Not a SaaS-cream warm-neutral landing page. Not a generic dev-tool dark mode with a neon-purple gradient and a hero-metric template (big number / small label / supporting stats). Not an editorial display-serif-and-italic magazine. Not crypto/web3 hash-mysticism — the hashes here are plumbing, not spectacle.

## Design Principles
Byte-exact honesty: show the real bytes, the real hash, the real signatures; never decorate what is fundamentally exact, and never fake an output the library wouldn't produce.
Plumbing, proudly: infrastructure doesn't need to shout — earn trust through precision and restraint, not through volume.
The metaphor earns its keep: sediment and deposition are a lens on real properties (content-addressing, layering, determinism); every motif must map to something the library actually does, or it's cut.
Cold-reader clarity: a Gleam developer who has never heard of the Fluid family must understand the shape and the guarantee in under two minutes.

## Accessibility & Inclusion
WCAG 2.1 AA. Body text verified at ≥4.5:1 against its background, large text ≥3:1. Color is never the sole information channel — the strata motif distinguishes layers by position and label as well as hue. Full keyboard operability with a visible focus style. A complete `prefers-reduced-motion` alternative for the settle/deposition motion (crossfade or instant, no motion-gated content).
