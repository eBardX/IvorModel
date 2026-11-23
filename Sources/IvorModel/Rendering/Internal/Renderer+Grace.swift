// © 2026 John Gary Pusey (see LICENSE.md)

internal import IvorTiming
internal import XestiNumbers

extension Renderer {

    // MARK: Internal Instance Methods

    //
    // Delays each chord (the notes of a part sharing an attack) by the most time any grace
    // figure before one of its notes takes from inside it: a figure gracing a chord is stored on
    // one tone, but the whole chord waits for it.
    //
    internal mutating func applyChordDelays() {
        for (moment, delay) in chordDelays {
            for index in attacks[moment] ?? [] {
                starts[index] = max(starts[index], moment.time + delay)
            }
        }
    }

    //
    // Plans each figure after a note: its events end where they take time from — the end of the
    // main note (inside), or the start of the notes that follow it in the same part (outside).
    // The notes of its chord that end with it end earlier; the notes after it start later.
    //
    internal mutating func planGraceFiguresAfter() {
        for index in sources.indices {
            let source = sources[index]

            guard let figure = source.ornamentation?.graceAfter
            else { continue }

            let successors = attacks[Moment(part: source.part, time: source.release)] ?? []
            let neighbor = successors.map { sources[$0].duration }.min()

            guard let plan = _plan(figure,
                                   of: source,
                                   neighbor: neighbor,
                                   isBefore: false)
            else { continue }

            for other in attacks[Moment(part: source.part, time: source.attack)] ?? [] where sources[other].release == source.release {
                ends[other] = min(ends[other], source.release - plan.inside)
            }

            for successor in successors {
                starts[successor] = max(starts[successor], source.release + plan.outside)
            }

            afterEvents[index] = Self._events(of: figure,
                                              from: source.release - plan.inside,
                                              lengths: plan.lengths)
        }
    }

    //
    // Plans each figure before a note: its events start where they take time from — the notes
    // in the same part that end at its attack (outside, before the beat), or the main note
    // (inside, on the beat). Those notes end earlier; the main note's chord starts later (see
    // `applyChordDelays()`).
    //
    internal mutating func planGraceFiguresBefore() {
        for index in sources.indices {
            let source = sources[index]

            guard let figure = source.ornamentation?.graceBefore
            else { continue }

            let moment = Moment(part: source.part, time: source.attack)
            let predecessors = releases[moment] ?? []
            let neighbor = predecessors.map { sources[$0].duration }.min()

            guard let plan = _plan(figure,
                                   of: source,
                                   neighbor: neighbor,
                                   isBefore: true)
            else { continue }

            chordDelays[moment] = max(chordDelays[moment] ?? 0, plan.inside)

            for predecessor in predecessors {
                ends[predecessor] = min(ends[predecessor], source.attack - plan.outside)
            }

            beforeEvents[index] = Self._events(of: figure,
                                               from: source.attack - plan.outside,
                                               lengths: plan.lengths)
        }
    }

    // MARK: Private Type Methods

    private static func _amount(_ amount: NoteTable<TimeType, PitchType>.Amount?,
                                of reference: Number) -> Number? {
        switch amount {
        case let .duration(length):
            TimeType.number(of: length.duration)

        case let .share(share):
            share.numberValue * reference

        case nil:
            nil
        }
    }

    private static func _events(of figure: NoteTable<TimeType, PitchType>.GraceFigure,
                                from start: Number,
                                lengths: [Number]) -> [GraceEvent] {
        var time = start
        var events: [GraceEvent] = []

        for (event, length) in zip(figure.events, lengths) {
            events.append(GraceEvent(end: time + length,
                                     pitches: event.pitches,
                                     start: time))

            time += length
        }

        return events
    }

    //
    // Each event's share of the time its figure takes: its written length, or, for an event with
    // none, the average of those that have one (all equal when none do).
    //
    private static func _weights(of events: [NoteTable<TimeType, PitchType>.GraceFigure.Event]) -> [Number] {
        let written = events.compactMap { $0.length.map { TimeType.number(of: $0.duration) } }
        let fallback: Number = written.isEmpty ? 1 : written.reduce(0, +) / Number(written.count)

        return events.map { $0.length.map { TimeType.number(of: $0.duration) } ?? fallback }
    }

    // MARK: Private Instance Methods

    //
    // The built-in size of a figure's time, and where it falls, when neither the figure nor its
    // events say (MuseScore's sizes): a lone appoggiatura takes half its main note (two-thirds in
    // compound meter, when the main note is longer than an eighth); acciaccaturas and longer
    // figures take a sixty-fourth (or 40 milliseconds, in a wall work) per note, capped at half
    // the note the time comes from. The rules can set the placement, the time per note and the
    // cap.
    //
    private func _defaultTime(of figure: NoteTable<TimeType, PitchType>.GraceFigure,
                              events count: Int,
                              of source: Source,
                              neighbor: Number?,
                              isBefore: Bool) -> (time: Number, isOutside: Bool) {
        let graceRules = rules[source.part].grace
        let main = source.duration
        let rulePlacement = figure.isSlashed ? graceRules?.slashedPlacement : graceRules?.unslashedPlacement
        let placement = isBefore ? rulePlacement ?? RenderingDefaults.gracePlacement : .onBeat
        let isOutside = placement == .beforeBeat
        let reference = isOutside ? neighbor ?? main : main

        if isBefore, !figure.isSlashed, figure.events.count == 1 {
            let isCompound = clock.eighth.map { clock.isCompound(source.attack) && main > $0 } ?? false
            let share = isCompound ? RenderingDefaults.compoundAppoggiaturaShare : RenderingDefaults.appoggiaturaShare
            let time = share.numberValue * reference

            return (graceRules?.maximumShare.map { min(time, $0.numberValue * reference) } ?? time, isOutside)
        }

        let perNote = graceRules?.perNote.map { clock.length($0.duration.numberValue, source.attack) } ?? clock.defaultGracePerNote
        let maximum = (graceRules?.maximumShare ?? RenderingDefaults.graceMaximumShare).numberValue * reference

        return (min(perNote * Number(count), maximum), isOutside)
    }

    //
    // How a figure shares its time (see `GracePlan`). An event with its own execution takes its
    // own amounts; the others share the figure's (its execution's, or the built-in size) in
    // proportion to their written lengths. A share of the neighbor is a share of the main note
    // when there is no neighbor. The time inside can't exceed the main note, nor the time
    // outside the neighbor; `nil` if the figure takes no time.
    //
    private func _plan(_ figure: NoteTable<TimeType, PitchType>.GraceFigure,
                       of source: Source,
                       neighbor: Number?,
                       isBefore: Bool) -> GracePlan? {
        let main = source.duration
        let outsideReference = neighbor ?? main
        let events = figure.events
        var lengths = Array(repeating: Number(0), count: events.count)
        var outside: Number = 0
        var inside: Number = 0
        var shared: [Int] = []

        for (index, event) in events.enumerated() {
            guard let execution = event.execution,
                  !execution.isEmpty
            else { shared.append(index); continue }

            let eventOutside = Self._amount(execution.fromPrevious, of: outsideReference) ?? 0
            let eventInside = Self._amount(execution.fromMain, of: main) ?? 0

            lengths[index] = eventOutside + eventInside
            outside += eventOutside
            inside += eventInside
        }

        if !shared.isEmpty {
            var sharedOutside: Number = 0
            var sharedInside: Number = 0

            if let execution = figure.execution,
               !execution.isEmpty {
                sharedOutside = Self._amount(execution.fromPrevious, of: outsideReference) ?? 0
                sharedInside = Self._amount(execution.fromMain, of: main) ?? 0
            } else {
                let size = _defaultTime(of: figure,
                                        events: shared.count,
                                        of: source,
                                        neighbor: neighbor,
                                        isBefore: isBefore)

                if size.isOutside {
                    sharedOutside = size.time
                } else {
                    sharedInside = size.time
                }
            }

            let weights = Self._weights(of: shared.map { events[$0] })
            let totalWeight = weights.reduce(0, +)

            for (index, weight) in zip(shared, weights) where totalWeight > 0 {
                lengths[index] = (sharedOutside + sharedInside) * weight / totalWeight
            }

            outside += sharedOutside
            inside += sharedInside
        }

        outside = min(outside, outsideReference)
        inside = min(inside, main)

        let total = lengths.reduce(0, +)

        guard total > 0,
              outside + inside > 0
        else { return nil }

        let scale = (outside + inside) / total

        return GracePlan(inside: inside,
                         lengths: lengths.map { $0 * scale },
                         outside: outside)
    }
}
