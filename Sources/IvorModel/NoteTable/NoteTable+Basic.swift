// © 2025–2026 John Gary Pusey (see LICENSE.md)

public import XestiTools

extension NoteTable {

    // MARK: Public Instance Properties

    /// The number of notes in the note table.
    public var count: Int {
        notes.count
    }

    /// A Boolean value indicating whether the note table contains no notes.
    public var isEmpty: Bool {
        notes.isEmpty
    }

    // MARK: Public Instance Methods

    /// Calls the given closure for each note in the table, in order.
    ///
    /// - Parameter body:   A closure that receives the identity, attack time,
    ///                     duration, start pitch, end pitch, and optional extras for
    ///                     each note.
    public func forEach(_ body: (NoteID, TimeType, DurationType, PitchType, PitchType, Extras?) -> Void) {
        notes.forEach {
            body($0.noteID,
                 $0.attack,
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
    ///
    /// - Returns:  The identity of the newly inserted note.
    @discardableResult
    public mutating func insert(attack: TimeType,
                                duration: DurationType,
                                pitch: PitchType,
                                extras: Extras? = nil) -> NoteID {
        insert(attack: attack,
               duration: duration,
               startPitch: pitch,
               endPitch: pitch,
               extras: extras)
    }

    /// Inserts a note with a start pitch and an end pitch into the table.
    ///
    /// Unlike the time-keyed maps (`TempoMap`, `PanMap`, `DynamicMap`, `InstrumentMap`), a note
    /// table represents discrete events rather than state sampled at a time, so two notes that are
    /// identical in every field — for example, a doubled unison — are not redundant and are not
    /// rejected or collapsed here.
    ///
    /// - Parameter attack:      The attack time of the note.
    /// - Parameter duration:    The duration of the note.
    /// - Parameter startPitch:  The pitch at the start of the note.
    /// - Parameter endPitch:    The pitch at the end of the note.
    /// - Parameter extras:      Optional extra data attached to the note. Defaults to `nil`.
    ///
    /// - Returns:  The identity of the newly inserted note.
    @discardableResult
    public mutating func insert(attack: TimeType,
                                duration: DurationType,
                                startPitch: PitchType,
                                endPitch: PitchType,
                                extras: Extras? = nil) -> NoteID {
        let noteID = NoteID()

        _insert(noteID: noteID,
                attack: attack,
                duration: duration,
                startPitch: startPitch,
                endPitch: endPitch,
                extras: extras)

        return noteID
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

    /// Moves the note with the given identity to a new attack time, keeping its duration,
    /// pitches, and extras, and re-sorts it into place.
    ///
    /// A note's position depends on all four of its attack, duration, and pitches (see
    /// ``insertionIndex(for:duration:startPitch:endPitch:)``), so changing any one of them can
    /// reorder the table — that is the point of editing any of these fields, not a side effect to
    /// avoid.
    ///
    /// Unlike the time-keyed maps' `move(noteID:to:)`, there is no "merges into a pre-existing
    /// duplicate" case to account for here — a note table allows exact duplicates (see
    /// ``insert(attack:duration:startPitch:endPitch:extras:)``), so `noteID` always keeps naming this
    /// same note after the move, regardless of whether another, unrelated note happens to already
    /// share every field with it.
    ///
    /// - Parameter noteID:  The identity of the note to move.
    /// - Parameter attack:  The new attack time for the note.
    ///
    /// - Returns:  `true` if `noteID` identified a note and it was moved; `false` if `noteID` did not
    ///             identify any note and nothing moved.
    @discardableResult
    public mutating func moveAttack(noteID: NoteID,
                                    to attack: TimeType) -> Bool {
        guard let position = firstIndex(noteID: noteID)
        else { return false }

        let note = notes.remove(at: position)

        _insert(noteID: noteID,
                attack: attack,
                duration: note.duration,
                startPitch: note.startPitch,
                endPitch: note.endPitch,
                extras: note.extras)

        return true
    }

    /// Moves the note with the given identity to a new duration, keeping its attack, pitches, and
    /// extras, and re-sorts it into place.
    ///
    /// See ``moveAttack(noteID:to:)`` for why this reorders rather than updating in place, and why `noteID`
    /// always keeps naming the same note afterward.
    ///
    /// - Parameter noteID:    The identity of the note to move.
    /// - Parameter duration:  The new duration for the note.
    ///
    /// - Returns:  `true` if `noteID` identified a note and it was moved; `false` otherwise. See
    ///             ``moveAttack(noteID:to:)``.
    @discardableResult
    public mutating func moveDuration(noteID: NoteID,
                                      to duration: DurationType) -> Bool {
        guard let position = firstIndex(noteID: noteID)
        else { return false }

        let note = notes.remove(at: position)

        _insert(noteID: noteID,
                attack: note.attack,
                duration: duration,
                startPitch: note.startPitch,
                endPitch: note.endPitch,
                extras: note.extras)

        return true
    }

    /// Moves the note with the given identity to a new end pitch, keeping its attack, duration,
    /// start pitch, and extras, and re-sorts it into place.
    ///
    /// See ``moveAttack(noteID:to:)`` for why this reorders rather than updating in place, and why `noteID`
    /// always keeps naming the same note afterward.
    ///
    /// - Parameter noteID:    The identity of the note to move.
    /// - Parameter endPitch:  The new end pitch for the note.
    ///
    /// - Returns:  `true` if `noteID` identified a note and it was moved; `false` otherwise. See
    ///             ``moveAttack(noteID:to:)``.
    @discardableResult
    public mutating func movePitchEnd(noteID: NoteID,
                                      to endPitch: PitchType) -> Bool {
        guard let position = firstIndex(noteID: noteID)
        else { return false }

        let note = notes.remove(at: position)

        _insert(noteID: noteID,
                attack: note.attack,
                duration: note.duration,
                startPitch: note.startPitch,
                endPitch: endPitch,
                extras: note.extras)

        return true
    }

    /// Moves the note with the given identity to a new start pitch, keeping its attack, duration,
    /// end pitch, and extras, and re-sorts it into place.
    ///
    /// See ``moveAttack(noteID:to:)`` for why this reorders rather than updating in place, and why `noteID`
    /// always keeps naming the same note afterward.
    ///
    /// - Parameter noteID:      The identity of the note to move.
    /// - Parameter startPitch:  The new start pitch for the note.
    ///
    /// - Returns:  `true` if `noteID` identified a note and it was moved; `false` otherwise. See
    ///             ``moveAttack(noteID:to:)``.
    @discardableResult
    public mutating func movePitchStart(noteID: NoteID,
                                        to startPitch: PitchType) -> Bool {
        guard let position = firstIndex(noteID: noteID)
        else { return false }

        let note = notes.remove(at: position)

        _insert(noteID: noteID,
                attack: note.attack,
                duration: note.duration,
                startPitch: startPitch,
                endPitch: note.endPitch,
                extras: note.extras)

        return true
    }

    /// Removes the note with the given identity, if present.
    ///
    /// - Parameter noteID:  The identity of the note to remove. An identity
    ///                       naming no note is ignored.
    ///
    /// - Returns:  `true` if `noteID` identified a note and it was removed,
    ///             `false` if `noteID` named no note and nothing happened.
    @discardableResult
    public mutating func remove(noteID: NoteID) -> Bool {
        guard let position = firstIndex(noteID: noteID)
        else { return false }

        let note = notes.remove(at: position)

        if note.extras != nil {
            hasExtras = Self.hasExtras(in: notes)
        }

        if note.startPitch != note.endPitch {
            hasPortamento = Self.hasPortamento(in: notes)
        }

        isMonophonic = Self.isMonophonic(in: notes)
        pitchRange = Self.pitchRange(in: notes)
        timeRange = Self.timeRange(in: notes)

        return true
    }

    /// Removes a note with a single pitch from the table, if present.
    ///
    /// - Parameter attack:     The attack time of the note to remove.
    /// - Parameter duration:   The duration of the note to remove.
    /// - Parameter pitch:      The pitch of the note to remove.
    /// - Parameter extras:     The optional extra data of the note to remove. Defaults to `nil`.
    ///
    /// - Returns:  The identity of the note that was removed, or `nil` if no
    ///             note matched `attack`, `duration`, `pitch`, and `extras`.
    @discardableResult
    public mutating func remove(attack: TimeType,
                                duration: DurationType,
                                pitch: PitchType,
                                extras: Extras? = nil) -> NoteID? {
        remove(attack: attack,
               duration: duration,
               startPitch: pitch,
               endPitch: pitch,
               extras: extras)
    }

    /// Removes a note with a start pitch and an end pitch from the table, if present.
    ///
    /// Exact duplicates are allowed in a note table (see
    /// ``insert(attack:duration:startPitch:endPitch:extras:)``), so more than one note can match
    /// `attack`, `duration`, `startPitch`, `endPitch`, and `extras`. When that happens, this removes
    /// whichever one ``firstIndex(attack:duration:startPitch:endPitch:extras:)`` finds first; the
    /// returned identity tells a caller exactly which note that was.
    ///
    /// - Parameter attack:      The attack time of the note to remove.
    /// - Parameter duration:    The duration of the note to remove.
    /// - Parameter startPitch:  The start pitch of the note to remove.
    /// - Parameter endPitch:    The end pitch of the note to remove.
    /// - Parameter extras:      The optional extra data of the note to remove. Defaults to `nil`.
    ///
    /// - Returns:  The identity of the note that was removed, or `nil` if no
    ///             note matched `attack`, `duration`, `startPitch`, `endPitch`, and `extras`.
    @discardableResult
    public mutating func remove(attack: TimeType,
                                duration: DurationType,
                                startPitch: PitchType,
                                endPitch: PitchType,
                                extras: Extras? = nil) -> NoteID? {
        guard let index = firstIndex(attack: attack,
                                     duration: duration,
                                     startPitch: startPitch,
                                     endPitch: endPitch,
                                     extras: extras)
        else { return nil }

        let noteID = notes[index].noteID

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

        return noteID
    }

    // MARK: Private Instance Methods

    private mutating func _insert(noteID: NoteID,
                                  attack: TimeType,
                                  duration: DurationType,
                                  startPitch: PitchType,
                                  endPitch: PitchType,
                                  extras: Extras?) {
        notes.insert(Note(noteID: noteID,
                          attack: attack,
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
}
