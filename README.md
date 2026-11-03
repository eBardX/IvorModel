# IvorModel

A representation-agnostic musical composition model.

[![Swift 6.3](https://img.shields.io/badge/Swift-6.3-orange.svg)](https://swift.org)
[![Platforms](https://img.shields.io/badge/platforms-iOS%20%7C%20macOS-lightgrey.svg)](https://developer.apple.com)
[![SwiftPM](https://img.shields.io/badge/SwiftPM-compatible-brightgreen.svg)](https://swift.org/package-manager/)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](https://github.com/eBardX/IvorModel/blob/main/LICENSE.md)

* [Overview](#overview)
* [Requirements](#requirements)
* [Installation](#installation)
    * [Swift Package Manager](#spm_installation)
* [Quick Start](#quick_start)
* [Documentation](#documentation)
* [Reference Documentation](#reference_documentation)
* [Credits](#credits)
* [License](#license)

## <a name="overview">Overview</a>

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

## <a name="requirements">Requirements</a>

* iOS 18.0+ / macOS 15.0+
* Swift 6.3 toolchain
* Swift 6 language mode

## <a name="installation">Installation</a>

### <a name="spm_installation">Swift Package Manager</a>

IvorModel is distributed exclusively through the [Swift Package Manager][spm].

To add IvorModel to a Swift package, add it to the `dependencies` in your
`Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/eBardX/IvorModel.git",
             .upToNextMinor(from: "0.45.0"))
]
```

Then add `IvorModel` to the dependencies of any target that uses it:

```swift
.target(name: "MyTarget",
        dependencies: [.product(name: "IvorModel",
                                package: "IvorModel")])
```

To add IvorModel to an Xcode project, choose **File ▸ Add Package
Dependencies…** and enter the repository URL:

```
https://github.com/eBardX/IvorModel.git
```

IvorModel depends on [IvorSMPTE][ivorsmpte], [IvorTiming][ivortiming],
[IvorTuning][ivortuning], [XestiArchive][xestiarchive],
[XestiMarkov][xestimarkov], [XestiNumbers][xestinumbers],
[XestiSexp][xestisexp], and [XestiTools][xestitools]; the Swift Package
Manager resolves them automatically.

## <a name="quick_start">Quick Start</a>

Write a melody, transform and convert it, learn a template from it, and save
everything in a project:

```swift
import IvorModel
import IvorTiming
import IvorTuning

// A work in beat time and standard pitch, with one part.
var work = Work(name: "Etude",
                content: .empty(timeBasis: .beat, pitchNotation: .standard))
let melody = try work.addPart(name: "Melody")

let notes: [(BeatTime, String)] = [(0, "C4"), (1, "E4"), (2, "G4"), (3, "E4"),
                                   (4, "C4"), (5, "G3"), (6, "C4")]

try work.modifyPart(melody, as: Part<BeatTime, Pitch>.self) { part in
    for (attack, name) in notes {
        part.noteTable.insert(attack: attack, duration: 1, pitch: Pitch(plain: name)!)
    }
}

// Transpose it up a fifth, then convert it to wall time and MIDI note numbers.
try work.transpose(by: DirectedInterval(interval: .perfect5, direction: .ascending))

let midi = try work.convert(timeBasis: .wall, pitchNotation: .keyboard)!

// Learn the melody, and generate a 12-note variation of it.
let template = try Template.analyzeNoteEvents(in: work, at: 0, maximumOrder: 2)
let options  = Template.GenerationOptions<BeatTime, Pitch>(order: 1,
                                                           length: .noteCount(12),
                                                           stopsAtEnd: false)
let variation = try template.generateWork(name: "Variation", options: options, seed: 42)

// Keep them in a project, and save it.
var project = Project()

project.updateWork(work)
project.updateTemplate(template)

let file = try project.save()               // a FileWrapper
```

For the complete story — works and parts, note tables and parameter maps,
transforms, conversion, realizations, templates, and error handling — see the
[usage guide][guide].

## <a name="documentation">Documentation</a>

* [Using IvorModel][guide] — a guide to using the public API, published as
  part of the DocC documentation.
* Every public declaration carries a DocC comment.

## <a name="reference_documentation">Reference Documentation</a>

Full [reference documentation][refdoc] is available courtesy of [DocC][docc].

## <a name="credits">Credits</a>

John Gary Pusey (ebardx@gmail.com)

## <a name="license">License</a>

IvorModel is available under [the MIT license][license].

[docc]:          https://www.swift.org/documentation/docc/
[guide]:         https://eBardX.github.io/ivor-packages-docs/documentation/ivormodel/usingivormodel
[ivorsmpte]:     https://github.com/eBardX/IvorSMPTE
[ivortiming]:    https://github.com/eBardX/IvorTiming
[ivortuning]:    https://github.com/eBardX/IvorTuning
[license]:       https://github.com/eBardX/IvorModel/blob/main/LICENSE.md
[refdoc]:        https://eBardX.github.io/ivor-packages-docs/documentation/ivormodel
[spm]:           https://swift.org/package-manager/
[xestiarchive]:  https://github.com/eBardX/XestiArchive
[xestimarkov]:   https://github.com/eBardX/XestiMarkov
[xestinumbers]:  https://github.com/eBardX/XestiNumbers
[xestisexp]:     https://github.com/eBardX/XestiSexp
[xestitools]:    https://github.com/eBardX/XestiTools
