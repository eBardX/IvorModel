# Follow-ups

## Deferred features (settled shape, not yet built)

- **Quantizing along parameter maps** `Part.augment`/
  `diminish`/`invert`/`move`/`reverse`/`transpose` all take a `MapTargets`/
  `applyTo` parameter that carries `dynamicMap`/`instrumentMap`/`panMap`
  along with the note table. `Part.quantize` deliberately does not: quantize
  snaps note attacks to a rhythmic grid, and continuous automation doesn't
  obviously want to snap to the *same* grid — a crescendo or pan sweep
  arguably wants to move smoothly through where a note's attack got rounded
  to, not get chopped onto beat subdivisions. This is unresolved, not
  rejected. Also note: `DynamicMap`/`InstrumentMap`/`PanMap` have no
  `quantize` method at all today — building this would mean designing and
  implementing quantize for all three map types first, then deciding whether
  it should even default to on or off.

- **Note-range selection queries** Shape is already settled:
  `attackingIn(_:)` / `soundingIn(_:)` / `pitchIn(_:)` (exact names/casing
  TBD), each returning `Set<NoteID>` for use with the `noteIDs:` parameter
  every transform already accepts. Not yet implemented anywhere in the
  codebase — build it once there's an actual selection UI (`IvorApp`) driving
  it; `noteIDs: Set<NoteID>?` already works today with IDs computed any other
  way, so nothing is blocked on this.

## Known code-level stub

- **Varispeed pitch-shift is unimplemented**
  `NoteTable+Advanced.swift`'s private `_varispeed(of:by:)` literally returns
  the input pitch unchanged (commented `pitch // + (12 * log2(factor))`), and
  its caller `_varispeed(of:at:using:normalTempo:)` is marked `// NEEDS
  WORK???` in the source. This is a pre-existing defect, but `Work.varispeeded(normalTempo:)`
  builds directly on top of it and cannot give correct results until this is
  fixed.

## Settled design decisions worth preserving

Recorded so nobody re-opens or re-litigates them without cause:

- **No anchor semantics for quantize.** `BeatQuantizer` always snaps to
  absolute beat zero, never to a table's or selection's own range — there is
  nothing for an `anchor` parameter to compute, so `quantize` doesn't have
  one (unlike `augment`/`diminish`/`move`).
- **No in-place mutating warp/varispeed on `Work`.** `warped()`/`unwarped()`/
  `varispeeded(normalTempo:)` are derived/export operations that return a new
  `Work?` (or `nil` for a `Content` case that doesn't apply); none of them
  mutate the receiver. This is deliberate, not a placeholder for a future
  mutating variant.
- **No public `warped(using:)`/`unwarped(using:)` on the parameter maps
  themselves.** `DynamicMap`/`InstrumentMap`/`PanMap`/`TempoMap` conversion
  between `BeatTime` and `WallTime` is handled by `Work+Convert.swift`'s
  existing private `_convertBeatTimes`/`_convertWallTimes` helpers, reused
  rather than duplicated as public API on each map type.
- **No shared generic error/protocol across the parameter maps.** Each map
  transform failure is its own hand-written `Work.Error` case
  (`dynamicMapTransformFailure`, `instrumentMapTransformFailure`,
  `panMapTransformFailure`, `tempoMapTransformFailure`) rather than one
  shared `Error`/protocol parameterized over map kind. If a future map type
  needs the same treatment, follow this precedent rather than introducing a
  shared abstraction retroactively.
