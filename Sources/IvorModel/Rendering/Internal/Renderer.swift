// © 2026 John Gary Pusey (see LICENSE.md)

internal import IvorTiming
internal import IvorTuning
internal import XestiNumbers
internal import XestiTools

//
// Turns the parts of one work's content into plain notes: each grace figure, trill, mordent,
// tremolo and arpeggio becomes the notes that sound (see `Work.rendered(options:)`).
//
// It works in plain numbers (see `RenderableTime`), on the notes' written times. First each
// grace figure is planned, which shortens or delays its neighbors and delays its chord; then
// rolled chords spread their tones; then each main note, over the span it has left, sounds its
// ornament; and last the grace notes are placed. A note's fermata becomes a fermata mark over
// its written span, for the timeline rendering that comes after.
//
internal struct Renderer<TimeType: RenderableTime, PitchType: RenderablePitch> {

    // MARK: Internal Initializers

    internal init(parts: [Part<TimeType, PitchType>],
                  workRules: InterpretationRules?,
                  clock: RenderingClock) {
        var sources: [Source] = []

        for (index, part) in parts.enumerated() {
            for (strandIndex, strand) in part.strands.enumerated() {
                for note in strand.noteTable {
                    sources.append(Source(attack: note.attack.number,
                                          endPitch: note.endPitch,
                                          extras: note.extras,
                                          ornamentation: note.ornamentation,
                                          part: index,
                                          release: note.release.number,
                                          startPitch: note.startPitch,
                                          strand: strandIndex))
                }
            }
        }

        var attacks: [Moment: [Int]] = [:]
        var releases: [Moment: [Int]] = [:]

        for (index, source) in sources.enumerated() {
            attacks[Moment(part: source.part, time: source.attack), default: []].append(index)
            releases[Moment(part: source.part, time: source.release), default: []].append(index)
        }

        self.afterEvents = Array(repeating: [], count: sources.count)
        self.attacks = attacks
        self.beforeEvents = Array(repeating: [], count: sources.count)
        self.chordDelays = [:]
        self.clock = clock
        self.ends = sources.map(\.release)
        self.partCount = parts.count
        self.strandCounts = parts.map(\.strands.count)
        self.releases = releases
        self.rules = parts.map { InterpretationRules.resolved(work: workRules, part: $0.interpretationRules) }
        self.sources = sources
        self.starts = sources.map(\.attack)
    }

    // MARK: Internal Instance Properties

    internal let attacks: [Moment: [Int]]
    internal let clock: RenderingClock
    internal let partCount: Int
    internal let releases: [Moment: [Int]]
    internal let rules: [InterpretationRules]
    internal let sources: [Source]

    //
    // The number of strands of each part, in part order.
    //
    internal let strandCounts: [Int]

    internal var afterEvents: [[GraceEvent]]
    internal var beforeEvents: [[GraceEvent]]
    internal var chordDelays: [Moment: Number]
    internal var ends: [Number]
    internal var starts: [Number]
}

// MARK: -

extension Renderer {

    // MARK: Internal Instance Methods

    internal func render() -> Output {
        var renderer = self

        renderer.planGraceFiguresBefore()
        renderer.planGraceFiguresAfter()
        renderer.applyChordDelays()
        renderer.rollArpeggios()

        return renderer._output()
    }

    // MARK: Private Instance Methods

    private func _output() -> Output {
        var notes = strandCounts.map { Array(repeating: [Note](), count: $0) }
        var fermataMarks = Array(repeating: [(time: Number, mark: PartMark<TimeType>)](), count: partCount)

        for index in sources.indices {
            let source = sources[index]

            notes[source.part][source.strand] += renderedNotes(of: index)

            if let fermata = source.ornamentation?.fermata,
               let span = TimeType.duration(fromNumber: source.duration).flatMap(PositiveDuration.init) {
                fermataMarks[source.part].append((source.attack, .fermata(fermata, span: span)))
            }
        }

        let earliest = notes.joined().joined().map(\.start).min() ?? 0

        return Output(fermataMarks: fermataMarks,
                      leadIn: earliest < 0 ? -earliest : 0,
                      notes: notes)
    }
}
