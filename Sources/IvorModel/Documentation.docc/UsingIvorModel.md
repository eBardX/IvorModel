# Using IvorModel

Build, transform, convert, and analyze musical works, and generate new ones
from templates.

## Overview

IvorModel organizes music as a hierarchy of value types:

```
Project
├─ works:     [Work]
│  ├─ content:      Work.Content       // parts, plus a tempo map and meter table in beat time
│  │  └─ [Part]
│  │     ├─ noteTable:     NoteTable
│  │     ├─ dynamicMap:      DynamicMap
│  │     ├─ instrumentTable: InstrumentTable
│  │     └─ panMap:          PanMap
│  ├─ info:         Work.Info          // titles, credits, rights, remarks
│  └─ realizations: [Realization]      // how instruments sound when played
└─ templates: [Template]               // analyses that generate new works
```

Every work chooses a **time basis** and a **pitch notation**, from
[IvorTiming](https://github.com/eBardX/IvorTiming) and
[IvorTuning](https://github.com/eBardX/IvorTuning): times are metrical
(`BeatTime`, counted in whole notes, so a quarter note is 1/4) or seconds
(`WallTime`), and pitches are standard pitches (`Pitch`), frequencies
(`Frequency`), or MIDI note numbers (`NoteNumber`). The generic types —
``Part``, ``NoteTable``, ``NoteEvent``, the parameter maps, and the instrument
table — take those as their type parameters, so a `Part<BeatTime, Pitch>` holds
notes in whole notes and standard pitch.

## Works

A ``Work`` holds its parts as ``Work/Content``, an enumeration with one case per
combination of time basis and pitch notation. The three beat-time cases also
carry the work’s `TempoMap` and its ``MeterTable`` (see [Meters](#Meters)).

```swift
var work = Work(name: "Etude",
                content: .empty(timeBasis: .beat, pitchNotation: .standard))
```

A work reports its ``Work/timeBasis``, ``Work/pitchNotation``,
``Work/partCount``, ``Work/noteCount``, and the time and pitch range its notes
span. It also has:

- a ``Work/Info``: its title, subtitles, alternate titles, dedication, credits
  (``Credit``), rights notices (``RightsNotice``), and remarks (``Remark``),
  edited with ``Work/modifyInfo(_:)``;
- an SMPTE start time, the timecode at which its wall time zero falls;
- ``Work/extras``: format-specific data about the work as a whole, such as the
  ``Extra/midiTimeCode`` of the Standard MIDI File it came from, edited with
  ``Work/modifyExtras(_:)``;
- its ``Work/realizations``; and
- a ``Work/Generation`` record, if it was generated from a template.

Every work, part, note, map entry, realization, and template has a unique
identity — ``WorkID``, ``PartID``, ``NoteID``, ``EntryID``,
``RealizationID``, and ``TemplateID`` — that keeps addressing it while the
model changes. Methods that copy something, such as ``Work/duplicated()``, give
the copy a fresh identity.

**Locking.** A locked work can’t be changed: every method that would change its
content, info, name, or start time throws ``Work/Error/workIsLocked``, and a
project refuses to remove it. Its realizations can still be edited, methods
that return a new work are always permitted, and ``Work/isLocked`` itself can
always be set.

## Parts

A ``Part`` is a named line of music: a note table, two parameter maps, and an
instrument table, plus ``Part/extras`` for format-specific data about the part as a whole, such as
the ``Extra/midiChannel`` it came from. A work’s parts all share its time and pitch types, so reading or editing one
means naming its concrete type:

```swift
let melody = try work.addPart(name: "Melody")

try work.modifyPart(melody, as: Part<BeatTime, Pitch>.self) { part in
    part.noteTable.insert(attack: 0, duration: .quarter, pitch: .c4)
}

let part = work.part(melody, as: Part<BeatTime, Pitch>.self)
```

Both return `nil` when no part has the ID, or when the type doesn’t match the
work’s content. ``Work/addPart(name:)``, ``Work/duplicatePart(_:)``,
``Work/removePart(_:)``, ``Work/renamePart(_:to:)``, and
``Work/shiftPart(_:to:)`` edit the list of parts, and ``Work/partIDs`` lists
them in order. ``Work/modifyTempoMap(_:)`` and ``Work/modifyMeterTable(_:)`` edit
a beat-time work’s tempo map and meter table.

A part can also find its notes: ``Part/attackingIn(_:)`` (attacked within a
time range), ``Part/soundingIn(_:)`` (sounding at any point within it), and
``Part/pitchIn(_:)`` (with a pitch in a range) each return a set of note IDs.

## Notes

A ``NoteTable`` keeps a part’s notes sorted by time and pitch. Each note has an
attack time, a duration, and a pitch; a note can also glide from a start pitch
to an end pitch, and carry `Extras` of your own:

```swift
var table = NoteTable<BeatTime, Pitch>()

let noteID = table.insert(attack: 0, duration: .half, pitch: .c4)

table.insert(attack: 1, duration: .half, startPitch: .c4, endPitch: .g4)   // a glide
table.moveAttack(noteID: noteID, to: BeatTime(plain: "1/4")!)
table.remove(noteID: noteID)
```

`moveAttack`, `moveDuration`, `movePitchStart`, `movePitchEnd`,
`updateExtras`, and `remove` take the note’s ``NoteID`` and return whether it
named a note. A note table is also a collection of ``NoteTable/Note``
snapshots, each with its attack, release, duration, pitches, and ID.

``NoteTable/extractNoteEvents()`` slices the notes into a sequence of
``NoteEvent`` values: each a set of pitches sounding together for a duration,
with ties (``NoteEvent/TiedPitch``) where a note continues from one event into
the next. A work’s `extractNoteEvents()` does the same across every part, and
tags each event with its part and attack time.

## Parameter maps and the instrument table

A part has two parameter maps and an instrument table, which work like
IvorTiming’s `TempoMap`: a list of entries, each a value that takes effect at a
time, with a default for an empty one. Each entry has an ``EntryID`` that keeps
naming it across edits, and all three share `insert`, `update`, `move`,
`remove`, and `merge`.

 Type                 | Value              | Default                    | Represents
:---                  |:-----              |:------                     |:----------
 ``DynamicMap``       | ``Dynamic``        | ``Dynamic/mp``             | A loudness from 0 to 1; presets from `pppp` to `ffff`
 ``InstrumentTable``  | ``Instrument``     | ``Instrument/vanilla``     | An instrument designation, as a name
 ``PanMap``           | ``Pan``            | ``Pan/center``             | A direction in 3-D space, as horizontal and vertical angles

Subscripting a dynamic map with a time gives the level in effect there,
interpolated between entries. A ``Pan`` can be made from, and folded down to, a
stereo position from −1 (hard left) to 1 (hard right).

An instrument table doesn’t interpolate. Subscripting it with a time gives the
instrument of the last entry at or before that time, which holds until the next
entry.

An ``Instrument`` only designates an instrument; what it sounds like when the
part plays is up to a realization (see [Realizations](#Realizations)).

## Meters

A beat-time work’s ``MeterTable`` says where its barlines and felt beats fall.
Its meter never changes timing: beat time counts whole notes whatever the
meter. Each entry is a ``Meter`` — such as 3/4, 6/8, 2+2+3/8, 4/3, or
``Meter/free`` — that starts a new bar at its time, and the table has a pickup:
a first bar shorter than its meter, counted as bar 0.

```swift
try work.modifyMeterTable { table in
    _ = try? table.insert(beatTime: .zero, meter: Meter(plain: "6/8")!)
    _ = try? table.insert(beatTime: 3, meter: Meter(plain: "2+2+3/8")!)
    try? table.setPickup(.eighth)
}

work.meterTable?.position(at: BeatTime(plain: "1/2")!)   // bar 1, beat 2
```

A meter’s ``Meter/pulse`` gives its felt beats: two dotted quarter notes for
6/8, and a quarter, a quarter and a dotted quarter for 2+2+3/8. The table
answers where a time falls (``MeterTable/position(at:)``), the reverse
(``MeterTable/beatTime(bar:beat:offset:)``), and which bars overlap a range
(``MeterTable/bars(overlapping:)``). An entry that cuts the bar before it short
is a restart (``MeterTable/isRestart(entryID:)``).

## Transforming a work

A work transforms its parts in place. Each transform applies to every part, or
to the ones whose IDs you pass in `partIDs`:

- **Pitch:** `transpose(by:partIDs:)`, by an interval of the work’s own pitch
  notation — an `Interval`, a `Ratio`, or a `NoteDistance` — and
  `invert(around:partIDs:)`, which mirrors pitches within a range.
- **Time:** `augment(by:anchor:applyTo:partIDs:)`,
  `diminish(by:anchor:applyTo:partIDs:)`, `move(by:applyTo:partIDs:)`,
  `reverse(within:applyTo:partIDs:)`, and
  `quantize(to:noteIDs:applyTo:partIDs:)`.

```swift
try work.transpose(by: DirectedInterval(interval: .perfect5, direction: .ascending))
try work.augment(by: 2, anchor: BeatTime.zero)  // twice as slow, from the start
```

The time transforms come in a beat-time and a wall-time form, so give the anchor
(or the duration, or the range) in the work’s own time type. They move a part’s
parameter maps and instrument table along with its notes, and the work’s own
tempo map and meter table with them; `applyTo` takes a ``TransformTargets`` set
to choose which of these go along. When the meter table goes along, the meter is
re-notated so that every note keeps its bar and beat: 3/4 augmented by 2 becomes
3/2. Augment and diminish can also keep the sound (`keepingSound`), by scaling
each tempo’s unit with the music: 3/8 at ♪ = 240, augmented by 2, becomes 3/4 at
♩ = 240. Quantize never moves the meter table. A transform
whose interval or time type doesn’t match the work throws
``Work/Error/pitchNotationMismatch(expected:)`` or
``Work/Error/timeBasisMismatch(expected:)``. Parts and note tables have the same
transforms, for working on one at a time.

## Converting a work

``Work/convert(timeBasis:pitchNotation:context:dropsUnconvertibleNotes:)``
returns a new work in another time basis, pitch notation, or both. It returns
`nil` when the work already has both, so there is nothing to convert. Like
every method that returns a new work, the result has a fresh ``WorkID`` and is
unlocked.

```swift
let midi = try work.convert(timeBasis: .wall, pitchNotation: .keyboard)!
```

Converting pitches uses IvorTuning’s converters, configured by a
``Work/ConvertContext``: a tuning system, a pitch standard, a keyboard layout,
a pitch speller, and how strictly a pitch must match a key. The
``Work/ConvertContext/default`` context is the piano layout in 12-tone equal
temperament at A4 = 440 Hz, spelled with `MeredithPitchSpeller`. Build another
by changing what you need:

```swift
let context = Work.ConvertContext.default
    .tuningSystem(LinearTemperament.quarterCommaMeantone)
    .pitchStandard(.a415)

let baroque = try work.convert(timeBasis: .beat,
                               pitchNotation: .absolute,
                               context: context)
```

A conversion that needs a dependency the context lacks throws, such as
``Work/Error/missingTuningSystem``. A note whose pitch has no counterpart in the
target notation throws ``Work/Error/unconvertiblePitch(partID:)``, unless
`dropsUnconvertibleNotes` is `true`, which drops it instead. Each part’s pitches
are converted as one passage in performance order, so a pitch speller sees
their context.

Three more conversions change only the time basis, using a tempo map:

- ``Work/warped()`` converts beat time to wall time with the work’s own tempo
  map — a fixed-media rendering of the tempo curve. Wall time has no bars, so
  the meter table is dropped.
- ``Work/unwarped(using:)`` converts wall time to beat time with a tempo map
  you supply, such as a tapped-in or detected one. The meter table starts out
  empty.
- ``Work/varispeeded(normalTempo:)`` converts beat-time, absolute-pitch music to
  wall time like ``Work/warped()``, and also shifts each note’s pitch with the
  tempo in effect, as a tape played faster or slower would.

## Realizations

A ``Realization`` is one way of performing a work: which ``Patch`` — a sound on
a synthesizer — each ``Instrument`` sounds as. It has a work-wide
``PatchTable`` of defaults and, for any part that needs one, a patch table of
the part’s own, so `Vanilla` can be a grand piano in one part and a pipe organ
in another. A patch table maps each instrument to a ``PatchTable/Assignment``:
a patch and, optionally, the MIDI channel to play it on.

A patch is a General MIDI 1 or 2 instrument, a General MIDI percussion kit or
drum set, or a custom program and bank with an optional name. Every work has at
least one realization; ``Work/replaceRealizations(with:)`` and
``Work/modifyRealization(_:_:)`` edit them, and
``Realization/assignment(for:in:)`` finds the assignment an instrument has in a
part.

## Templates

A ``Template`` is an analysis of a part as Markov chains of note events, from
which new, derived works can be generated.

### Analyzing

``Template/analyzeNoteEvents(in:at:options:name:)`` analyzes one part of a work with
a ``Template/AnalysisOptions`` recipe. The recipe sets the maximum order — the
longest pattern the template remembers — and can also:

- align near-simultaneous attacks and releases
  (``Template/AnalysisOptions/TimingTolerance``), and group near-identical
  durations and pitches (``Template/AnalysisOptions/DurationTolerance`` and
  ``Template/AnalysisOptions/PitchTolerance``);
- record pitches as absolute pitches, pitch classes, or intervals, and
  durations as absolute or relative to the previous one, or leave either out
  (``Template/AnalysisOptions/StateRecipe``) — and learn pitch and duration in
  one chain or two;
- learn transposed, inverted, retrograde, and time-scaled copies along with the
  part (``Template/AnalysisOptions/Variants``); and
- split the part into separate sequences at long rests
  (``Template/AnalysisOptions/RestSplit``).

``Template/analyzeNoteEvents(in:at:maximumOrder:name:)`` is the exact analysis,
with no tolerances. ``Template/adding(partAt:of:name:)`` returns a template that
has learned another part as well. Each takes the new template’s name from the
caller; IvorModel never makes up names.

### Generating

`generateWork(name:partName:options:seed:)` generates a new work, with the
given work and part names, from a ``Template/GenerationOptions`` recipe and a
seed. The same template, recipe, and
seed always give the same notes, and the new work records the recipe and seed
in its ``Work/generation``, so it can be generated again or varied. A beat-time
work starts out in its source’s tempo and meter (``Template/SourceContext``),
with a pickup that puts the first note as far into its bar as the source’s
was.

```swift
let template = try Template.analyzeNoteEvents(in: work,
                                              at: 0,
                                              maximumOrder: 2,
                                              name: "Melody")
let options  = Template.GenerationOptions<BeatTime, Pitch>(order: 1,
                                                           length: .noteCount(12),
                                                           stopsAtEnd: false)

let variation = try template.generateWork(name: "Variation",
                                          partName: "Melody",
                                          options: options,
                                          seed: 42)
```

The recipe is generic over the template’s time and pitch types;
``Template/AnyGenerationOptions`` wraps one whose types are chosen at run time.
Its main settings are:

- **Order and length.** The order — how many preceding note events choose the
  next, up to the template’s maximum — and the length, as a number of note
  events or a duration.
- **Starting and stopping.** Whether to start at the source’s opening, whether
  generation may stop where a source sequence ends (`stopsAtEnd`, `true` by
  default, so turn it off to reach the full length), whether to back off to
  lower orders at a dead end, and whether to loop.
- **Shape.** A contrast that favors common or rare paths; a blend or morph
  with another order (``Template/GenerationOptions/Mixing``); and, for a
  template with separate pitch and duration chains, options of its own for the
  pitch chain.
- **Limits.** ``Template/GenerationOptions/Constraints`` on pitch range,
  allowed pitches, durations, and rests, and a
  ``Template/GenerationOptions/Cadence`` to end on.
- **Material.** A ``Template/GenerationOptions/Phrase`` to continue, and other
  templates to blend or morph with (``Template/GenerationOptions/TemplateMix``),
  passed to ``Template/generateWork(name:partName:options:seed:mixingWith:)``.

## Projects

A ``Project`` holds works and templates, and saves them as a `FileWrapper`:

```swift
var project = Project()

project.updateWork(work)            // adds it, or replaces the one with its ID
project.updateTemplate(template)

let file     = try project.save()
let reopened = try Project.load(from: file)
```

``Project/removeWork(_:)`` and ``Project/removeTemplate(_:)`` refuse a locked
work or template. A work or template in a project’s file that can’t be read —
saved in an older format, say — doesn’t stop the rest from loading: a template
is left out (see ``Project/skippedTemplates``), and a work is kept unread (see
``Project/unreadableWorks``) and written back as it was when the project is
saved.

## Error handling

Thrown errors conform to `EnhancedError` (from
[XestiTools](https://github.com/eBardX/XestiTools)): each has a `category` of
`"IvorModel"` and a human-readable `message`.

 Type                            | Thrown by
:----                            |:---------
 ``Work/Error``                  | ``Work`` methods: editing a locked work, mismatched types, transforms, conversion
 ``Part/Error``                  | ``Part`` transforms, wrapping the error of the note table, map, or instrument table that failed
 ``NoteTable/Error``             | ``NoteTable`` transforms
 ``DynamicMap/Error``, ``InstrumentTable/Error``, ``PanMap/Error`` | The parameter-map and instrument-table transforms
 ``MeterTable/Error``            | Editing and scaling a meter table
 ``Template/Error``              | Analysis, generation, and renaming a locked template
 ``Project/Error``               | Loading, saving, and removing locked works and templates

Methods that look something up by ID return `nil`, or `false`, when nothing has
that ID; editing methods that take an ID do nothing for an unknown one.

## Concurrency

IvorModel is built for Swift 6 strict concurrency. Every public type is a
`Sendable` value type, so instances can be freely shared across tasks and actor
boundaries.
