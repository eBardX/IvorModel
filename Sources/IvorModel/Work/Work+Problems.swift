// © 2026 John Gary Pusey (see LICENSE.md)

internal import IvorTiming
internal import IvorTuning
internal import XestiNumbers

extension Work {

    // MARK: Public Instance Methods

    /// Returns what in this work rendering can’t follow exactly as written (see
    /// ``rendered(options:)``).
    ///
    /// The problems are worked out afresh each time, never stored: fermatas starting at one
    /// moment with conflicting holds, a note’s fermata while another part attacks, grace
    /// figures whose events take time in an order that can’t be played, and rolled chords whose
    /// tones disagree. See ``Problem/Kind`` for each.
    ///
    /// - Returns:  The problems, holds first, then fermata spans, grace figures and arpeggios,
    ///             each in time order.
    public func problems() -> [Problem] {
        if let body = content.body as? any BeatTimeBody {
            return _beatProblems(body)
        }

        guard let body = content.body as? any WallTimeBody
        else { preconditionFailure("A work's body is of beat or wall time") }

        return _wallProblems(body)
    }

    // MARK: Private Type Methods

    //
    // Rolled chords whose tones disagree on direction or execution.
    //
    private static func _arpeggioProblems<TimeType: RenderableTime,
                                          PitchType: PitchProtocol>(_ parts: [Part<TimeType, PitchType>],
                                                                    time: (Number) -> WorkTime?) -> [Problem] {
        var rolls: [Number: [ArpeggioGroup: [NoteTable<TimeType, PitchType>.Arpeggio]]] = [:]

        for part in parts {
            for note in part.mergedNoteTable {
                if let arpeggio = note.ornamentation?.arpeggio {
                    rolls[note.attack.number, default: [:]][arpeggio.group, default: []].append(arpeggio)
                }
            }
        }

        return rolls.keys.sorted().flatMap { attack in
            (rolls[attack] ?? [:]).values.compactMap { tones -> Problem? in
                guard let first = tones.first,
                      tones.contains(where: { $0.direction != first.direction || $0.execution != first.execution })
                else { return nil }

                return Problem(severity: .error,
                               kind: .conflictingArpeggio,
                               time: time(attack))
            }
        }
    }

    private static func _beatTime(_ number: Number) -> WorkTime? {
        BeatTime(numberValue: number).map(WorkTime.beat)
    }

    //
    // Grace figures whose events take time from both sides of the main note in an order that can't
    // be played.
    //
    private static func _graceProblems(_ parts: [Part<some RenderableTime, some PitchProtocol>],
                                       time: (Number) -> WorkTime?) -> [Problem] {
        var problems: [Problem] = []

        for (index, part) in parts.enumerated() {
            for note in part.mergedNoteTable {
                let ornamentation = note.ornamentation
                let before = ornamentation?.graceBefore.map { _isUnordered($0, outsideFirst: true) } ?? false
                let after = ornamentation?.graceAfter.map { _isUnordered($0, outsideFirst: false) } ?? false

                if before || after {
                    problems.append(Problem(severity: .warning,
                                            kind: .unorderedGraceAmounts,
                                            partIndex: index,
                                            noteID: note.noteID,
                                            time: time(note.attack.number)))
                }
            }
        }

        return problems
    }

    //
    // Fermatas starting at one moment whose holds differ: an error when two explicit holds
    // differ, else a warning.
    //
    private static func _holdProblems(_ holds: [TimelineHold],
                                      time: (Number) -> WorkTime?) -> [Problem] {
        Dictionary(grouping: holds, by: \.time).sorted { $0.key < $1.key }.compactMap { moment, holds in
            let explicit = Set(holds.filter(\.isExplicit).map(\.extra))

            if explicit.count > 1 {
                return Problem(severity: .error,
                               kind: .conflictingExplicitHolds,
                               time: time(moment))
            }

            guard Set(holds.map(\.extra)).count > 1
            else { return nil }

            return Problem(severity: .warning,
                           kind: .conflictingDefaultHolds,
                           time: time(moment))
        }
    }

    //
    // Whether a figure's events with their own amounts are out of order: one taking time from
    // the side that should come later before one taking time from the side that should come
    // first.
    //
    private static func _isUnordered(_ figure: NoteTable<some RenderableTime, some PitchProtocol>.GraceFigure,
                                     outsideFirst: Bool) -> Bool {
        var seenLater = false

        for event in figure.events {
            guard let execution = event.execution
            else { continue }

            let first = outsideFirst ? execution.fromPrevious : execution.fromMain
            let later = outsideFirst ? execution.fromMain : execution.fromPrevious

            if first != nil, seenLater {
                return true
            }

            if later != nil {
                seenLater = true
            }
        }

        return false
    }

    private static func _order(_ time: WorkTime) -> Number {
        switch time {
        case let .beat(time):
            time.numberValue

        case let .wall(time):
            time.numberValue
        }
    }

    //
    // Notes with a fermata while another part attacks during them.
    //
    private static func _spanProblems(_ parts: [Part<some RenderableTime, some PitchProtocol>],
                                      time: (Number) -> WorkTime?) -> [Problem] {
        var problems: [Problem] = []

        for (index, part) in parts.enumerated() {
            for note in part.mergedNoteTable where note.ornamentation?.fermata != nil {
                let attack = note.attack.number
                let release = note.release.number
                let isAmbiguous = parts.indices.contains { other in
                    other != index && parts[other].mergedNoteTable.contains { $0.attack.number > attack && $0.attack.number < release }
                }

                if isAmbiguous {
                    problems.append(Problem(severity: .warning,
                                            kind: .ambiguousHoldSpan,
                                            partIndex: index,
                                            noteID: note.noteID,
                                            time: time(attack)))
                }
            }
        }

        return problems.sorted { ($0.time.map(Self._order) ?? 0) < ($1.time.map(Self._order) ?? 0) }
    }

    private static func _wallTime(_ number: Number) -> WorkTime? {
        WallTime(numberValue: number).map(WorkTime.wall)
    }

    // MARK: Private Instance Methods

    private func _beatProblems(_ body: some BeatTimeBody) -> [Problem] {
        _problems(body.parts,
                  clock: RenderingClock(tempoMap: body.tempoMap,
                                        meterTable: body.meterTable,
                                        keyTable: body.keyTable),
                  time: Self._beatTime)
    }

    private func _problems(_ parts: [Part<some RenderableTime, some PitchProtocol>],
                           clock: RenderingClock,
                           time: (Number) -> WorkTime?) -> [Problem] {
        let collector = HoldCollector(parts: parts,
                                      workRules: interpretationRules,
                                      clock: clock)

        return Self._holdProblems(collector.holds, time: time)
            + Self._spanProblems(parts, time: time)
            + Self._graceProblems(parts, time: time).sorted { ($0.time.map(Self._order) ?? 0) < ($1.time.map(Self._order) ?? 0) }
            + Self._arpeggioProblems(parts, time: time)
    }

    private func _wallProblems(_ body: some WallTimeBody) -> [Problem] {
        _problems(body.parts,
                  clock: RenderingClock(),
                  time: Self._wallTime)
    }
}
