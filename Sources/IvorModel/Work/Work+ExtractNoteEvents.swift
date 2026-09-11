// © 2025–2026 John Gary Pusey (see LICENSE.md)

public import IvorTiming
public import IvorTuning

extension Work {

    // MARK: Public Instance Methods

    /// Extracts note events from every part in this work, tagged with their originating part and
    /// absolute attack time, merged and sorted by attack time across all parts (ties broken by
    /// part array order). `nil` if this work's content is not beat-time, absolute-pitch content.
    public func extractNoteEvents() -> [TaggedNoteEvent<BeatTime, Frequency>]? {
        guard case let .absoluteBeat(parts, _) = content
        else { return nil }

        return Self._extractNoteEvents(from: parts)
    }

    /// Extracts note events from every part in this work, tagged with their originating part and
    /// absolute attack time, merged and sorted by attack time across all parts (ties broken by
    /// part array order). `nil` if this work's content is not wall-time, absolute-pitch content.
    public func extractNoteEvents() -> [TaggedNoteEvent<WallTime, Frequency>]? {
        guard case let .absoluteWall(parts) = content
        else { return nil }

        return Self._extractNoteEvents(from: parts)
    }

    /// Extracts note events from every part in this work, tagged with their originating part and
    /// absolute attack time, merged and sorted by attack time across all parts (ties broken by
    /// part array order). `nil` if this work's content is not beat-time, keyboard-pitch content.
    public func extractNoteEvents() -> [TaggedNoteEvent<BeatTime, NoteNumber>]? {
        guard case let .keyboardBeat(parts, _) = content
        else { return nil }

        return Self._extractNoteEvents(from: parts)
    }

    /// Extracts note events from every part in this work, tagged with their originating part and
    /// absolute attack time, merged and sorted by attack time across all parts (ties broken by
    /// part array order). `nil` if this work's content is not wall-time, keyboard-pitch content.
    public func extractNoteEvents() -> [TaggedNoteEvent<WallTime, NoteNumber>]? {
        guard case let .keyboardWall(parts) = content
        else { return nil }

        return Self._extractNoteEvents(from: parts)
    }

    /// Extracts note events from every part in this work, tagged with their originating part and
    /// absolute attack time, merged and sorted by attack time across all parts (ties broken by
    /// part array order). `nil` if this work's content is not beat-time, standard-pitch content.
    public func extractNoteEvents() -> [TaggedNoteEvent<BeatTime, Pitch>]? {
        guard case let .standardBeat(parts, _) = content
        else { return nil }

        return Self._extractNoteEvents(from: parts)
    }

    /// Extracts note events from every part in this work, tagged with their originating part and
    /// absolute attack time, merged and sorted by attack time across all parts (ties broken by
    /// part array order). `nil` if this work's content is not wall-time, standard-pitch content.
    public func extractNoteEvents() -> [TaggedNoteEvent<WallTime, Pitch>]? {
        guard case let .standardWall(parts) = content
        else { return nil }

        return Self._extractNoteEvents(from: parts)
    }

    // MARK: Private Type Methods

    //
    // Reconstructs each part's absolute attack times by walking cumulative event durations from
    // `TimeType.zero`, since `NoteEvent`/`NoteTable.extractNoteEvents()` deliberately don't carry
    // attack time (a slice can start mid-note, e.g. a tied continuation, so there's no single
    // "attack" to attribute at that level). `moved(by:)` returning `nil` here would mean a
    // well-formed note table produced an invalid cumulative time — an internal invariant
    // violation, not a reachable user-input error — so this fails the same way
    // `NoteTable.Extractor`'s own internal arithmetic does elsewhere in this module.
    //
    private static func _extractNoteEvents<T: TimeProtocol, P: PitchProtocol>(from parts: [Part<T, P>]) -> [TaggedNoteEvent<T, P>] {
        var tagged: [TaggedNoteEvent<T, P>] = []

        for part in parts {
            var currentAttack = T.zero

            for event in part.noteTable.extractNoteEvents() {
                tagged.append(TaggedNoteEvent(partID: part.partID,
                                              attack: currentAttack,
                                              noteEvent: event))

                guard let next = currentAttack.moved(by: DirectedDuration(duration: event.duration,
                                                                          direction: .forward))
                else { fatalError("Bad logic!") }

                currentAttack = next
            }
        }

        return tagged.sorted { $0.attack < $1.attack }
    }
}
