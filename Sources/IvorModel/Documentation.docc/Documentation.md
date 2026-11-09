# ``IvorModel``

@Metadata {
    @PageColor(blue)
}

A representation-agnostic musical composition model.

## Overview

IvorModel is the foundational data-modeling framework for the Ivor music
ecosystem, providing a representation-agnostic model for musical compositions,
written in Swift.

Designed as a flexible composer’s assistant, IvorModel bridges the gap between
abstract symbolic notation and physical audio performance through a unified,
dual-paradigm architecture. Compositions are organized as projects containing
works, each broken into parts with note events, dynamics, panning, and
instrumentation — all captured at a level natural to a composer, without being
tied to any particular notation system, audio format, or instrument family.

A template system rounds out the model, enabling analysis of existing works and
algorithmic generation of new, derived ones. Together these capabilities make it
straightforward to aggregate, analyze, and transform musical data from disparate
sources before exporting to any destination.

The model is oriented toward Western musical traditions but is not confined to
Western classical music, and aims to accommodate a broader range of musical
practice where possible.

```swift
import IvorModel
import IvorTiming
import IvorTuning

// A work in beat time and standard pitch, with one part.
var work = Work(name: "Etude",
                content: .empty(timeBasis: .beat,
                                pitchNotation: .standard))
let melody = try work.addPart(name: "Melody")

let notes: [(BeatTime, String)] = [(0, "C4"), (1, "E4"), (2, "G4"), (3, "E4"),
                                   (4, "C4"), (5, "G3"), (6, "C4")]

try work.modifyPart(melody, as: Part<BeatTime, Pitch>.self) { part in
    for (attack, name) in notes {
        part.noteTable.insert(attack: attack,
                              duration: 1,
                              pitch: Pitch(plain: name)!)
    }
}

// Transpose it up a fifth, then convert it to wall time and MIDI note numbers.
try work.transpose(by: DirectedInterval(interval: .perfect5,
                                        direction: .ascending))

let midi = try work.convert(timeBasis: .wall,
                            pitchNotation: .keyboard)!

// Learn the melody, and generate a 12-note variation of it.
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

// Keep them in a project, and save it.
var project = Project()

project.updateWork(work)
project.updateTemplate(template)

let file = try project.save()               // a FileWrapper
```

See <doc:UsingIvorModel> for a full guide to works, parts, notes, parameter
maps, transforms, conversion, realizations, templates, and projects.

## Topics

### Guides

- <doc:UsingIvorModel>

### Projects and works

- ``Project``
- ``Work``

### Parts and notes

- ``Part``
- ``NoteTable``
- ``NoteEvent``

### Parameter maps

- ``Dynamic``
- ``DynamicMap``
- ``Pan``
- ``PanMap``

### Instruments

- ``Instrument``
- ``InstrumentTable``

### Transforms

- ``TransformTargets``

### Realizations

- ``Realization``
- ``PatchTable``
- ``Patch``

### Templates

- ``Template``
- ``TemplateDuration``
- ``TemplatePitch``

### Descriptive information

- ``Credit``
- ``RightsNotice``
- ``Remark``

### Identifiers

- ``UniqueID``
- ``WorkID``
- ``PartID``
- ``NoteID``
- ``EntryID``
- ``RealizationID``
- ``TemplateID``
