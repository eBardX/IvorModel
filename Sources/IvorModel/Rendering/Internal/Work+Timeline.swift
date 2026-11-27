// © 2026 John Gary Pusey (see LICENSE.md)

internal import IvorTiming
internal import IvorTuning
internal import XestiNumbers

extension Work {

    // MARK: Internal Instance Methods

    //
    // This work with its fermata holds and caesura pauses turned into time, as `mode` says, and
    // their signs consumed: its part marks removed and its notes' fermatas dropped. Also returns
    // where each fermata's span starts in the new timeline, for markers.
    //
    // The holds of all parts that start at one moment become one: the longest (in seconds), with
    // the longest pause after. In tempo-changes mode a beat work slows its tempo over each held
    // span, and over the stretch from the latest attack before each pause (in any part) to the
    // pause, so the bar grid stays; a pause with no attack before it inserts time instead.
    // Otherwise — stretched-notes mode, or any wall work — time is inserted: a held span spreads
    // out, and everything after it moves later. Not-realized mode changes no times.
    //
    internal func applyingTimeline(mode: RenderingOptions.FermataMode) -> (work: Work, fermataTimes: [WorkTime]) {
        var work = self

        work.isLocked = false

        if var body = content.body as? any BeatTimeBody {
            let times = _applyBeatTimeline(to: &body,
                                           mode: mode)

            work.content.body = body

            return (work, times)
        }

        guard var body = content.body as? any WallTimeBody
        else { preconditionFailure("A work's body is of beat or wall time") }

        let times = _applyWallTimeline(to: &body,
                                       mode: mode)

        work.content.body = body

        return (work, times)
    }

    // MARK: Private Type Aliases

    private typealias MergedHolds = (holds: [TimelineHold], pauses: [TimelinePause])

    // MARK: Private Type Methods

    //
    // The operations that insert the holds and pauses as time.
    //
    private static func _insertions(_ holds: [TimelineHold],
                                    _ pauses: [TimelinePause]) -> [TimelineOperation] {
        holds.map { .stretch(from: $0.time, to: $0.time + $0.span, extra: $0.extra) } + pauses.map { .insert(at: $0.time, length: $0.length) }
    }

    //
    // One position map for all `operations`. They're applied latest first, so each one's start is
    // still where it was written; a stretch's end first passes through the later ones.
    //
    private static func _map(_ operations: [TimelineOperation]) -> PositionMap {
        var applied: [TimelineOperation] = []

        func compose(_ position: Number, _ isRelease: Bool) -> Number {
            applied.reduce(position) { $1.mapped($0, isRelease: isRelease) }
        }

        for operation in operations.sorted(by: { $0.time > $1.time }) {
            switch operation {
            case .insert:
                applied.append(operation)

            case let .stretch(start, end, extra):
                applied.append(.stretch(from: start, to: compose(end, true), extra: extra))
            }
        }

        let result = applied

        return { position, isRelease in
            result.reduce(position) { $1.mapped($0, isRelease: isRelease) }
        }
    }

    //
    // The longest hold starting at each moment, and the longest pause at each moment.
    //
    private static func _merged(_ collector: HoldCollector<some RenderableTime, some PitchProtocol>) -> MergedHolds {
        let holds = Dictionary(grouping: collector.holds, by: \.time).values.compactMap { $0.max { $0.extraSeconds < $1.extraSeconds } }
        let pauses = Dictionary(grouping: collector.pauses, by: \.time).values.compactMap { $0.max { $0.seconds < $1.seconds } }

        return (holds.sorted { $0.time < $1.time }, pauses.sorted { $0.time < $1.time })
    }

    //
    // `tempoMap` slowed over `start` up to `end` so that the span lasts `seconds` longer.
    //
    private static func _slowed(_ tempoMap: TempoMap,
                                from start: Number,
                                to end: Number,
                                adding seconds: Number) -> TempoMap {
        let clock = RenderingClock(tempoMap: tempoMap, meterTable: MeterTable(), keyTable: KeyTable())
        let length = clock.seconds(start, end)

        guard length > 0,
              seconds > 0,
              let startTime = BeatTime(numberValue: start),
              let endTime = BeatTime(numberValue: end)
        else { return tempoMap }

        //
        // A tempo's rate must be an exact rational, and the seconds come from rounded wall times.
        //
        let factor = rationalize((length / (length + seconds)).exact,
                                 Number(numerator: 1, denominator: 1_000_000_000))

        return tempoMap.slowed(from: startTime, to: endTime, by: factor)
    }

    //
    // `parts` with their fermatas and caesuras consumed: no part marks, and no fermata on any
    // note.
    //
    private static func _withoutSigns<TimeType: RenderableTime,
                                      PitchType: PitchProtocol>(_ parts: [Part<TimeType, PitchType>]) -> [Part<TimeType, PitchType>] {
        parts.map { part in
            var result = part

            result.markTable = PartMarkTable()
            result.noteTable = NoteTable(notes: part.noteTable.notes.map { note in
                guard let ornamentation = note.ornamentation,
                      ornamentation.fermata != nil
                else { return note }

                return NoteTable<TimeType, PitchType>.StoredNote(noteID: note.noteID,
                                                                 attack: note.attack,
                                                                 duration: note.duration,
                                                                 startPitch: note.startPitch,
                                                                 endPitch: note.endPitch,
                                                                 extras: note.extras,
                                                                 ornamentation: .init(graceBefore: ornamentation.graceBefore,
                                                                                      graceAfter: ornamentation.graceAfter,
                                                                                      ornament: ornamentation.ornament,
                                                                                      arpeggio: ornamentation.arpeggio))
            })

            return result
        }
    }

    // MARK: Private Instance Methods

    //
    // Applies the timeline to a beat-time body's parts and tables, and returns the fermata times.
    //
    private func _applyBeatTimeline(to body: inout some BeatTimeBody,
                                    mode: RenderingOptions.FermataMode) -> [WorkTime] {
        let result = _timeline(body.parts,
                               tempoMap: body.tempoMap,
                               meterTable: body.meterTable,
                               keyTable: body.keyTable,
                               mode: mode)

        body.parts = result.parts
        body.tempoMap = result.tempoMap
        body.meterTable = result.meterTable
        body.keyTable = result.keyTable

        return result.times.compactMap { BeatTime(numberValue: $0).map(WorkTime.beat) }
    }

    //
    // Applies the timeline to a wall-time body's parts, and returns the fermata times.
    //
    private func _applyWallTimeline(to body: inout some WallTimeBody,
                                    mode: RenderingOptions.FermataMode) -> [WorkTime] {
        let result = _timeline(body.parts,
                               mode: mode)

        body.parts = result.parts

        return result.times.compactMap { WallTime(numberValue: $0).map(WorkTime.wall) }
    }

    private func _timeline<TimeType: RenderableTime,
                           PitchType: PitchProtocol>(_ parts: [Part<TimeType, PitchType>],
                                                     mode: RenderingOptions.FermataMode) -> (parts: [Part<TimeType, PitchType>], times: [Number]) {
        let collector = HoldCollector(parts: parts, workRules: interpretationRules, clock: RenderingClock())
        let (holds, pauses) = Self._merged(collector)
        let map = Self._map(mode == .notRealized ? [] : Self._insertions(holds, pauses))

        return (Self._withoutSigns(parts.map { Self.retimed($0, by: map) }),
                collector.fermataTimes.map { map($0, false) })
    }

    private func _timeline<PitchType: PitchProtocol>(_ parts: [Part<BeatTime, PitchType>],
                                                     tempoMap: TempoMap,
                                                     meterTable: MeterTable,
                                                     keyTable: KeyTable,
                                                     mode: RenderingOptions.FermataMode) -> BeatTimeline<PitchType> {
        let clock = RenderingClock(tempoMap: tempoMap, meterTable: meterTable, keyTable: keyTable)
        let collector = HoldCollector(parts: parts, workRules: interpretationRules, clock: clock)
        let (holds, pauses) = Self._merged(collector)
        var newTempoMap = tempoMap
        var operations: [TimelineOperation] = []

        switch mode {
        case .notRealized:
            break

        case .stretchedNotes:
            operations = Self._insertions(holds, pauses)

        case .tempoChanges:
            let attacks = parts.flatMap { $0.noteTable.map(\.attack.numberValue) }.sorted()

            for hold in holds {
                newTempoMap = Self._slowed(newTempoMap, from: hold.time, to: hold.time + hold.span, adding: hold.extraSeconds)
            }

            for pause in pauses {
                if let start = attacks.last(where: { $0 < pause.time }) {
                    newTempoMap = Self._slowed(newTempoMap, from: start, to: pause.time, adding: pause.seconds)
                } else {
                    operations.append(.insert(at: pause.time, length: pause.length))
                }
            }
        }

        let map = Self._map(operations)

        return BeatTimeline(keyTable: Self.retimed(keyTable, by: map),
                            meterTable: Self.retimed(meterTable, by: map),
                            parts: Self._withoutSigns(parts.map { Self.retimed($0, by: map) }),
                            tempoMap: Self.retimed(newTempoMap, by: map),
                            times: collector.fermataTimes.map { map($0, false) })
    }
}
