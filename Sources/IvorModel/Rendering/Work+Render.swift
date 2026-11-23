// © 2026 John Gary Pusey (see LICENSE.md)

internal import IvorTiming
internal import IvorTuning
internal import XestiNumbers

extension Work {

    // MARK: Public Instance Methods

    /// Returns this work with every note’s ornamentation turned into the plain notes that
    /// sound, and its fermatas and caesuras turned into time.
    ///
    /// Grace figures, trills, mordents, tremolos and arpeggios each become notes, played as each
    /// one’s execution says, else as its part’s and then its work’s interpretation rules say,
    /// else by the built-in ``RenderingDefaults``. Grace notes before the first beat, or a chord
    /// rolled into it, would start before time zero, so everything then moves later by a
    /// ``Rendering/LeadIn``: in a beat work the pickup grows by that much, or one is created (a
    /// pickup reaching a full bar adds a bar).
    ///
    /// Then each fermata — on a note, over a span in a part mark — holds every part: the holds
    /// of all parts starting at one moment become the longest of them, as do the pauses (after a
    /// fermata, or at a caesura) at one moment. A hold comes from the fermata’s execution, else
    /// the rules for its shape, else the built-in stretch for its shape; a fermata that isn’t
    /// played holds nothing. `options.fermataMode` says how the holds become time (see
    /// ``RenderingOptions/FermataMode``); a wall work, which has no tempo map, inserts it. The
    /// fermatas and caesuras are then removed; ``Rendering/fermataTimes`` keeps where each
    /// fermata now starts.
    ///
    /// The result is the same kind of content, keeps everything else — maps, pedals, tables,
    /// rules — and is unlocked.
    ///
    /// - Parameter options:    How to render. Defaults to the default options.
    ///
    /// - Returns:  The rendered work, with its lead-in.
    ///
    /// - Throws:   A ``Work/Error`` if the lead-in can’t be applied.
    public func rendered(options: RenderingOptions = RenderingOptions()) throws(Error) -> Rendering {
        var work = self

        work.isLocked = false

        switch content {
        case let .absoluteBeat(parts, tempoMap, meterTable, keyTable):
            return try work._rendered(parts,
                                      clock: RenderingClock(tempoMap: tempoMap,
                                                            meterTable: meterTable,
                                                            keyTable: keyTable),
                                      options: options)

        case let .absoluteWall(parts):
            return try work._rendered(parts,
                                      clock: RenderingClock(),
                                      options: options)

        case let .keyboardBeat(parts, tempoMap, meterTable, keyTable):
            return try work._rendered(parts,
                                      clock: RenderingClock(tempoMap: tempoMap,
                                                            meterTable: meterTable,
                                                            keyTable: keyTable),
                                      options: options)

        case let .keyboardWall(parts):
            return try work._rendered(parts,
                                      clock: RenderingClock(),
                                      options: options)

        case let .standardBeat(parts, tempoMap, meterTable, keyTable):
            return try work._rendered(parts,
                                      clock: RenderingClock(tempoMap: tempoMap,
                                                            meterTable: meterTable,
                                                            keyTable: keyTable),
                                      options: options)

        case let .standardWall(parts):
            return try work._rendered(parts,
                                      clock: RenderingClock(),
                                      options: options)
        }
    }

    // MARK: Private Type Methods

    //
    // The rendered notes as a note table, each moved later by `offset`. A note that rounds to no
    // length (possible in wall time, which counts whole microseconds) is left out.
    //
    private static func _noteTable<TimeType: RenderableTime,
                                   PitchType: RenderablePitch>(_ notes: [Renderer<TimeType, PitchType>.Note],
                                                               offset: Number) -> NoteTable<TimeType, PitchType> {
        var stored: [NoteTable<TimeType, PitchType>.StoredNote] = []

        for note in notes {
            guard let attack = TimeType(number: note.start + offset),
                  let release = TimeType(number: note.end + offset),
                  let span = attack.duration(to: release),
                  span.direction == .forward,
                  !span.duration.isZero
            else { continue }

            stored.append(NoteTable<TimeType, PitchType>.StoredNote(attack: attack,
                                                                    duration: span.duration,
                                                                    startPitch: note.startPitch,
                                                                    endPitch: note.endPitch,
                                                                    extras: note.extras,
                                                                    ornamentation: nil))
        }

        return NoteTable(notes: stored.sorted())
    }

    // MARK: Private Instance Methods

    //
    // Moves everything in this work later by `leadIn` (in the work's own numbers), so the
    // rendered notes, placed after it, start at or after time zero.
    //
    private mutating func _applyLeadIn<TimeType: RenderableTime>(_ leadIn: Number,
                                                                 of type: TimeType.Type) throws(Error) -> Rendering.LeadIn? {
        guard leadIn > 0
        else { return nil }

        if TimeType.self == BeatTime.self,
           let duration = BeatDuration(numberValue: leadIn) {
            try move(by: DirectedDuration(duration: duration,
                                          direction: .forward))

            return .beat(duration)
        }

        if TimeType.self == WallTime.self,
           let duration = WallDuration(numberValue: leadIn) {
            try move(by: DirectedDuration(duration: duration,
                                          direction: .forward))

            return .wall(duration)
        }

        return nil
    }

    private func _rendered<TimeType: RenderableTime,
                           PitchType: RenderablePitch>(_ parts: [Part<TimeType, PitchType>],
                                                       clock: RenderingClock,
                                                       options: RenderingOptions) throws(Error) -> Rendering {
        let output = Renderer(parts: parts,
                              workRules: interpretationRules,
                              clock: clock).render()
        var work = self
        let leadIn = try work._applyLeadIn(output.leadIn,
                                           of: TimeType.self)
        let offset = leadIn == nil ? 0 : output.leadIn

        for (index, part) in parts.enumerated() {
            try work.modifyPart(part.partID, as: Part<TimeType, PitchType>.self) { part in
                part.noteTable = Self._noteTable(output.notes[index],
                                                 offset: offset)

                for (time, mark) in output.fermataMarks[index] {
                    if let time = TimeType(number: time + offset) {
                        part.markTable.insert(time: time,
                                              mark: mark)
                    }
                }
            }
        }

        let timeline = work.applyingTimeline(mode: options.fermataMode)

        return Rendering(work: timeline.work,
                         leadIn: leadIn,
                         fermataTimes: timeline.fermataTimes)
    }
}
