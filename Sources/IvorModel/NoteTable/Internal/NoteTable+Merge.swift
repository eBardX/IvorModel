// © 2026 John Gary Pusey (see LICENSE.md)

internal import IvorTiming

extension NoteTable {

    // MARK: Internal Instance Methods

    //
    // Groups the attack and release times, earliest first, so that each lies within `window` of
    // the first time in its group, and moves each to that first time — so that a chord whose
    // notes start or end at slightly different times starts or ends together.  A note left with
    // no length keeps one window's length.  Used by analysis (see `Template+Analyze.swift`); the
    // table itself is left unchanged.
    //
    internal func mergingTimes(within window: DurationType) -> Self {
        let times = Set(notes.flatMap { [$0.attack, $0.release] }).sorted()
        var mergedTimes: [TimeType: TimeType] = [:]
        var groupStart: TimeType?

        for time in times {
            if let start = groupStart,
               let distance = start.duration(to: time),
               distance.duration <= window {
                mergedTimes[time] = start
            } else {
                groupStart = time
                mergedTimes[time] = time
            }
        }

        let merged = notes.map { note in
            let attack = mergedTimes[note.attack] ?? note.attack
            let release = mergedTimes[note.release] ?? note.release
            let span = attack.duration(to: release)
            let duration = if let span, span.direction == .forward, !span.duration.isZero {
                span.duration
            } else {
                window
            }

            return StoredNote(noteID: note.noteID,
                              attack: attack,
                              duration: duration,
                              startPitch: note.startPitch,
                              endPitch: note.endPitch,
                              extras: note.extras)
        }

        return Self(notes: merged.sorted())
    }
}
