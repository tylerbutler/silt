# Design

Visual system for the silt website. Governing concept: **deposition** — silt is
the fine sediment that settles out of moving water, and the library settles
content into deterministic, byte-exact ids. The surface is deep water above,
settled strata below. The SHA-1 hex string is treated as hero material, because
emitting exact hashes is literally what the library does.

Register: brand. Platform: web. Built with Astro.

## Theme

Dark, committed, two-element. A single deep-water canvas carries the whole
surface (Committed color strategy, not restrained). Warmth is carried by the
**silt** accent and by typography — never by a warm-tinted background, which is
the warm-neutral AI default this design deliberately avoids. Light mode is not
offered; the scene is water, and water is dark.

## Color

OKLCH throughout. Contrast verified in-browser (body ≥4.5:1, large text ≥3:1).

### Core
- `--bg` deep water — `oklch(0.19 0.028 218)`
- `--bg-deep` wells / footer — `oklch(0.155 0.026 220)`
- `--surface` raised panels — `oklch(0.235 0.030 216)`
- `--surface-2` insets / code wells — `oklch(0.275 0.032 214)`
- `--hairline` 1px borders — `oklch(0.36 0.028 214)`

### Ink
- `--ink` primary text — `oklch(0.95 0.008 210)`
- `--ink-muted` secondary text — `oklch(0.74 0.020 210)`
- `--ink-faint` metadata (large/secondary only) — `oklch(0.62 0.020 212)`

### Accents (the water + silt duality)
- `--silt` sediment / primary CTA fill — `oklch(0.72 0.110 68)` (muted clay-ochre)
- `--silt-bright` CTA hover — `oklch(0.80 0.100 72)`
- `--aqua` links / active / interactive — `oklch(0.80 0.100 205)` (glacial aqua)
- `--aqua-dim` visited / muted interactive — `oklch(0.68 0.080 205)`

### Strata ramp (motif only, never text)
A water→silt sequence used for the sediment bands and the "core sample":
`oklch(0.50 0.07 210)` → `oklch(0.55 0.06 190)` → `oklch(0.62 0.06 150)` →
`oklch(0.68 0.09 100)` → `oklch(0.72 0.11 68)` → `oklch(0.60 0.10 52)`.

Rule: silt (warm) is reserved for sediment, emphasis, and the primary action.
Aqua (cool) is reserved for interactive text. They do not swap roles.

## Typography

Two voices: a wide industrial grotesque for display/UI, and an honest monospace
for the hashes, code, and technical labels (honest because the library's output
*is* hex and code — mono here is not costume).

- Display / UI / body: **Archivo** (variable; uses weight 400–800 and the width
  axis toward expanded for hero and section headings). Off the reflex-reject list.
- Mono: **Spline Sans Mono** — hashes, code blocks, signatures, small technical
  metadata labels.

Scale is fluid with `clamp()`, ratio ≥1.25:
- Wordmark / hero display: `clamp(3.5rem, 8vw, 6rem)`, weight 800, expanded, tracking `-0.02em`
- Section h2: `clamp(2rem, 4vw, 3rem)`
- Sub h3: `clamp(1.35rem, 2.4vw, 1.75rem)`
- Body: `1.0625rem` / line-height `1.65`, measure capped 68ch
- Mono label: `0.8125rem`, tracking `0.02em`, uppercase reserved for genuine labels

`text-wrap: balance` on headings; `text-wrap: pretty` on prose.

## Spacing & layout

Content column max `72rem`; prose measure `68ch`. Fluid section rhythm with
`clamp()` — generous separation between sections (`clamp(5rem, 12vh, 9rem)`),
tight grouping within. Thin **strata dividers** (layered hairline bands) mark
section boundaries instead of plain rules. Flexbox for 1D, Grid for 2D;
breakpoint-free card rows use `repeat(auto-fit, minmax(min(100%, 18rem), 1fr))`.
Radii are small and precise: `4px` insets, `8px` panels, `10px` CTA.

Semantic z-index scale: `--z-sticky: 100`, `--z-header: 200`, `--z-overlay:
300`. No arbitrary 999s.

## Signature motif — strata / core sample

Thin layered horizontal bands, water-toned at the top grading to silt-toned at
the bottom, drawn as real SVG. Two uses:
1. **Ambient strata** behind the hero and as section dividers.
2. **Core sample** — a vertical column of labeled layers that visualizes
   content-addressing: a body of content settles into layers and resolves to a
   single hash printed at the base. Layers are distinguished by position and
   label as well as hue (accessibility: not hue alone).

## Motion

One orchestrated page-load: the hero strata **settle** into place (staggered
`translateY` + `opacity`), and the hero hash **resolves** — scrambled hex
characters settling to the final SHA-1. Easing is ease-out-expo
`cubic-bezier(0.16, 1, 0.3, 1)`; durations 500–900ms with small stagger. No
bounce, no elastic, no fade-on-scroll on every section. Reveals enhance
already-visible content (no visibility gated on a transition class).

`prefers-reduced-motion: reduce`: strata appear in place, the hash renders final
immediately, transitions collapse to instant or a short crossfade.

## Components

- **CTA (primary)**: silt fill, `--bg` text, `10px` radius, subtle inset on
  active. **CTA (secondary)**: hairline outline, ink text, aqua on hover.
- **Code block**: `--surface-2` well, `8px` radius, Spline Sans Mono, Gleam
  syntax coloring drawn from the accent ramp (keywords aqua, strings silt-dim,
  comments ink-faint), copy affordance, scrolls horizontally in its own
  container.
- **Signature / API row**: monospace signature line + prose description; full
  hairline separators, never side-stripe borders.
- **Strata divider**: layered hairline bands between major sections.

## Bans honored
No side-stripe borders, no gradient text, no decorative glassmorphism, no
hero-metric template, no identical icon-card grids, no per-section uppercase
eyebrows, no numbered section scaffolding. Warmth via accent + type, never a
warm-neutral background.
