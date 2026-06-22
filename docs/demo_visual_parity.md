# Demo visual parity after the size→bounds change

## Why this branch exists

The UE-parity fix on `main` (commit `03c2826`, *"generators record extent as
bounds, not scale"*) made the size→bounds samplers output **unit scale** and move
the sampling extent into the `bounds_min`/`bounds_max` streams. That is the
UE-correct behavior (a point's bounds are metadata; a static-mesh spawner places
meshes at their natural size).

Side effect: the demo graphs were authored *before* that change and relied on the
old behavior where the sampler wrote `size = extent`, which the spawners apply as
a Transform **scale**. With unit scale, spawned meshes grew by `1 / former_extent`
and the demos no longer looked the way they used to (e.g. the colonnade's airy
spiral collapsed into a solid drum).

## The fix: an opt-in legacy bridge (no undoing of UE-correctness)

`feat(pcg): opt-in legacy_scale_from_extent bridge` adds one setting to each
size→bounds generator:

```
legacy_scale_from_extent : bool = false   # default = UE-correct unit scale
```

When **true**, the generator *also* writes the extent into the `size` stream as
before (bounds are still recorded too). Default **false** keeps the UE-correct
behavior, so `main`'s tests and any new graphs are unaffected (full suite stays
green, 1359 cases on Godot 4.6 + 4.7).

Generators with the toggle: Sample Spline, Sample Points (grid + blue-noise),
Split Splines, Subdivide Segment, Create Surface From Spline, Create Surface From
Polygon.

## Per-demo changes

Each affected demo simply flips the toggle on its generator(s) — **one boolean per
generator, no other graph edits**. Restores the exact former look because
`legacy size = former extent`.

| Demo | Generator(s) toggled | Former extent (for reference) |
|------|----------------------|-------------------------------|
| `demos/demo_flashy_colonnade.tscn` | Sample Spline | interval 0.6 |
| `demos/demo_bridge.tscn` | Sample Spline ×2 | interval 2.0 / 0.795 |
| `demos/demo_path_over_region.tscn` | Sample Spline ×2 | interval 0.18 / 2.22 |
| `demos/demo_random_subscenes.tscn` | Sample Spline | interval 2.0 |
| `demos/demo_match_and_set.tscn` | Sample Points | cell 0.2 × 0.67 = 0.134 |
| `demos/demo_relax.tscn` | Sample Spline + Sample Points | interval 0.445 / cell 0.131 |
| `demos/demo_grammar.tscn` | Subdivide Segment ×2 | cross-section 0.5 + per-segment length |
| `graph01.tres` | Sample Spline | interval 0.94 |
| `graph02_curves.tres` | Sample Spline | interval 1.94 |

`demos/demo_fallguys.tscn` was **not** changed: its Sample Spline interval was
already 1.0, so `1.0 × scale == 1.0 × scale` — no visual difference.

## How it was verified

Rendered each demo in the Godot 4.7 editor (via the MCP bridge) with the toggle
on and compared against the pre-change look. The colonnade was confirmed pixel-
for-pixel against a reference captured by temporarily reverting the addon to the
parent of the size→bounds commit. Bridge, match_and_set, and the others were
spot-checked and render coherently.

## Notes for review

- This branch contains **only** the generator toggle (code + one parity test) and
  the per-demo toggle flips. It does **not** touch `project.godot`, `.gitignore`,
  or add the local `addons/godot_mcp` tooling.
- Long term, re-authoring the demos to the UE-correct convention (e.g. a Bounds-
  Modifier `SymmetricSize` step, or intended unit-scale meshes) would let them
  drop the legacy toggle — but the toggle is the minimal, exact, reversible bridge.
