// © 2025–2026 John Gary Pusey (see LICENSE.md)

public import XestiTools

extension NoteTable {

    // MARK: Public Instance Properties

    /// A Boolean value indicating whether the note table contains no notes.
    public var isEmpty: Bool {
        notes.isEmpty
    }

    // MARK: Public Instance Methods

    /// Calls the given closure for each note in the table, in order.
    ///
    /// - Parameter body:   A closure that receives the attack time, duration,
    ///                     start pitch, end pitch, and optional extras for each note.
    public func forEach(_ body: (TimeType, DurationType, PitchType, PitchType, Extras?) -> Void) {
        notes.forEach {
            body($0.attack,
                 $0.duration,
                 $0.startPitch,
                 $0.endPitch,
                 $0.extras)
        }
    }

    /// Inserts a note with a single pitch into the table.
    ///
    /// - Parameter attack:     The attack time of the note.
    /// - Parameter duration:   The duration of the note.
    /// - Parameter pitch:      The pitch of the note.
    /// - Parameter extras:     Optional extra data attached to the note. Defaults to `nil`.
    public mutating func insert(attack: TimeType,
                                duration: DurationType,
                                pitch: PitchType,
                                extras: Extras? = nil) {
        insert(attack: attack,
               duration: duration,
               startPitch: pitch,
               endPitch: pitch,
               extras: extras)
    }

    /// Inserts a note with a start pitch and an end pitch into the table.
    ///
    /// - Parameter attack:      The attack time of the note.
    /// - Parameter duration:    The duration of the note.
    /// - Parameter startPitch:  The pitch at the start of the note.
    /// - Parameter endPitch:    The pitch at the end of the note.
    /// - Parameter extras:      Optional extra data attached to the note. Defaults to `nil`.
    public mutating func insert(attack: TimeType,
                                duration: DurationType,
                                startPitch: PitchType,
                                endPitch: PitchType,
                                extras: Extras? = nil) {
        notes.insert(Note(attack: attack,
                          duration: duration,
                          startPitch: startPitch,
                          endPitch: endPitch,
                          extras: extras),
                     at: insertionIndex(for: attack,
                                        duration: duration,
                                        startPitch: startPitch,
                                        endPitch: endPitch))

        if extras != nil {
            hasExtras = true
        }

        if startPitch != endPitch {
            hasPortamento = true
        }

        isMonophonic = Self.isMonophonic(in: notes)
        pitchRange = Self.pitchRange(in: notes)
        timeRange = Self.timeRange(in: notes)
    }

    /// Returns a copy of the table with a note added using a single pitch.
    ///
    /// - Parameter attack:     The attack time of the note.
    /// - Parameter duration:   The duration of the note.
    /// - Parameter pitch:      The pitch of the note.
    /// - Parameter extras:     Optional extra data attached to the note. Defaults to `nil`.
    ///
    /// - Returns:  A new ``NoteTable`` with the note inserted.
    public func inserting(attack: TimeType,
                          duration: DurationType,
                          pitch: PitchType,
                          extras: Extras? = nil) -> Self {
        inserting(attack: attack,
                  duration: duration,
                  startPitch: pitch,
                  endPitch: pitch,
                  extras: extras)
    }

    /// Returns a copy of the table with a note added using a start pitch and an end pitch.
    ///
    /// - Parameter attack:      The attack time of the note.
    /// - Parameter duration:    The duration of the note.
    /// - Parameter startPitch:  The pitch at the start of the note.
    /// - Parameter endPitch:    The pitch at the end of the note.
    /// - Parameter extras:      Optional extra data attached to the note. Defaults to `nil`.
    ///
    /// - Returns:  A new ``NoteTable`` with the note inserted.
    public func inserting(attack: TimeType,
                          duration: DurationType,
                          startPitch: PitchType,
                          endPitch: PitchType,
                          extras: Extras? = nil) -> Self {
        var new = self

        new.insert(attack: attack,
                   duration: duration,
                   startPitch: startPitch,
                   endPitch: endPitch,
                   extras: extras)

        return new
    }

    /// Merges the notes from another table into this table.
    ///
    /// - Parameter other:  The table whose notes are merged into this table.
    public mutating func merge(with other: Self) {
        guard !other.notes.isEmpty
        else { return }

        guard !notes.isEmpty
        else { self = other; return }

        notes.append(contentsOf: other.notes)
        notes.sort()

        hasExtras = hasExtras || other.hasExtras
        hasPortamento = hasPortamento || other.hasPortamento
        isMonophonic = Self.isMonophonic(in: notes)
        pitchRange = Self.mergePitchRanges(pitchRange.require(),
                                           other.pitchRange.require())
        timeRange = Self.mergeTimeRanges(timeRange.require(),
                                         other.timeRange.require())
    }

    /// Returns a copy of the table merged with another table.
    ///
    /// - Parameter other:  The table to merge with.
    ///
    /// - Returns:  A new ``NoteTable`` containing the notes from both tables.
    public func merging(with other: Self) -> Self {
        var new = self

        new.merge(with: other)

        return new
    }

    /// Removes a note with a single pitch from the table, if present.
    ///
    /// - Parameter attack:     The attack time of the note to remove.
    /// - Parameter duration:   The duration of the note to remove.
    /// - Parameter pitch:      The pitch of the note to remove.
    /// - Parameter extras:     The optional extra data of the note to remove. Defaults to `nil`.
    public mutating func remove(attack: TimeType,
                                duration: DurationType,
                                pitch: PitchType,
                                extras: Extras? = nil) {
        remove(attack: attack,
               duration: duration,
               startPitch: pitch,
               endPitch: pitch,
               extras: extras)
    }

    /// Removes a note with a start pitch and an end pitch from the table, if present.
    ///
    /// - Parameter attack:      The attack time of the note to remove.
    /// - Parameter duration:    The duration of the note to remove.
    /// - Parameter startPitch:  The start pitch of the note to remove.
    /// - Parameter endPitch:    The end pitch of the note to remove.
    /// - Parameter extras:      The optional extra data of the note to remove. Defaults to `nil`.
    public mutating func remove(attack: TimeType,
                                duration: DurationType,
                                startPitch: PitchType,
                                endPitch: PitchType,
                                extras: Extras? = nil) {
        guard let index = firstIndex(attack: attack,
                                     duration: duration,
                                     startPitch: startPitch,
                                     endPitch: endPitch,
                                     extras: extras)
        else { return }

        notes.remove(at: index)

        if extras != nil {
            hasExtras = Self.hasExtras(in: notes)
        }

        if startPitch != endPitch {
            hasPortamento = Self.hasPortamento(in: notes)
        }

        isMonophonic = Self.isMonophonic(in: notes)
        pitchRange = Self.pitchRange(in: notes)
        timeRange = Self.timeRange(in: notes)
    }

    /// Returns a copy of the table with a matching single-pitch note removed.
    ///
    /// - Parameter attack:     The attack time of the note to remove.
    /// - Parameter duration:   The duration of the note to remove.
    /// - Parameter pitch:      The pitch of the note to remove.
    /// - Parameter extras:     The optional extra data of the note to remove. Defaults to `nil`.
    ///
    /// - Returns:  A new ``NoteTable`` with the matching note removed.
    public func removing(attack: TimeType,
                         duration: DurationType,
                         pitch: PitchType,
                         extras: Extras? = nil) -> Self {
        removing(attack: attack,
                 duration: duration,
                 startPitch: pitch,
                 endPitch: pitch,
                 extras: extras)
    }

    /// Returns a copy of the table with a matching portamento note removed.
    ///
    /// - Parameter attack:      The attack time of the note to remove.
    /// - Parameter duration:    The duration of the note to remove.
    /// - Parameter startPitch:  The start pitch of the note to remove.
    /// - Parameter endPitch:    The end pitch of the note to remove.
    /// - Parameter extras:      The optional extra data of the note to remove. Defaults to `nil`.
    ///
    /// - Returns:  A new ``NoteTable`` with the matching note removed.
    public func removing(attack: TimeType,
                         duration: DurationType,
                         startPitch: PitchType,
                         endPitch: PitchType,
                         extras: Extras? = nil) -> Self {
        var new = self

        new.remove(attack: attack,
                   duration: duration,
                   startPitch: startPitch,
                   endPitch: endPitch,
                   extras: extras)

        return new
    }
}
