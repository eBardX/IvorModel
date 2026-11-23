// © 2025–2026 John Gary Pusey (see LICENSE.md)

public import XestiTools

private import IvorTiming

extension NoteTable {

    // MARK: Public Instance Methods

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

    /// Inserts a note with a single pitch and ornamentation into the table.
    ///
    /// - Parameter attack:         The attack time of the note.
    /// - Parameter duration:       The duration of the note.
    /// - Parameter pitch:          The pitch of the note.
    /// - Parameter extras:         Optional extra data attached to the note. Defaults to `nil`.
    /// - Parameter ornamentation:  The ornamentation of the note, or `nil` for none.
    ///
    /// - Returns:  The identity of the newly inserted note.
    ///
    /// - Throws:   ``NoteTable/Error/partnerOnWrongSide(_:_:_:_:)`` if the ornament’s written
    ///             partner isn’t strictly on its side of `pitch`.
    @discardableResult
    public mutating func insert(attack: TimeType,
                                duration: DurationType,
                                pitch: PitchType,
                                extras: Extras? = nil,
                                ornamentation: Ornamentation?) throws(Error) -> NoteID {
        try insert(attack: attack,
                   duration: duration,
                   startPitch: pitch,
                   endPitch: pitch,
                   extras: extras,
                   ornamentation: ornamentation)
    }

    /// Inserts a note with a start pitch and an end pitch into the table.
    ///
    /// Unlike the time-keyed maps (`TempoMap`, `PanMap`, `DynamicMap`) and `InstrumentTable`, which
    /// collapse exact-duplicate entries, a note table keeps them: two notes that are identical in
    /// every field — for example, a doubled unison — are not redundant and are not rejected or
    /// collapsed here.
    ///
    /// - Parameter attack:     The attack time of the note.
    /// - Parameter duration:   The duration of the note.
    /// - Parameter startPitch: The pitch at the start of the note.
    /// - Parameter endPitch:   The pitch at the end of the note.
    /// - Parameter extras:     Optional extra data attached to the note. Defaults to `nil`.
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
                extras: extras,
                ornamentation: nil)

        return noteID
    }

    /// Inserts a note with a start pitch, an end pitch, and ornamentation into the table.
    ///
    /// A step partner’s written pitch must lie strictly on its side of the note’s start pitch:
    /// above it for a trill or upper mordent, below it for a lower mordent. A contradiction is an
    /// error, never silently reinterpreted.
    ///
    /// - Parameter attack:         The attack time of the note.
    /// - Parameter duration:       The duration of the note.
    /// - Parameter startPitch:     The pitch at the start of the note.
    /// - Parameter endPitch:       The pitch at the end of the note.
    /// - Parameter extras:         Optional extra data attached to the note. Defaults to `nil`.
    /// - Parameter ornamentation:  The ornamentation of the note, or `nil` for none.
    ///
    /// - Returns:  The identity of the newly inserted note.
    ///
    /// - Throws:   ``NoteTable/Error/partnerOnWrongSide(_:_:_:_:)`` if the ornament’s written
    ///             partner isn’t strictly on its side of `startPitch`.
    @discardableResult
    public mutating func insert(attack: TimeType,
                                duration: DurationType,
                                startPitch: PitchType,
                                endPitch: PitchType,
                                extras: Extras? = nil,
                                ornamentation: Ornamentation?) throws(Error) -> NoteID {
        guard !Self.hasPartnerOnWrongSide(ornamentation, startPitch: startPitch)
        else { throw .partnerOnWrongSide(attack, duration, startPitch, endPitch) }

        let noteID = NoteID()

        _insert(noteID: noteID,
                attack: attack,
                duration: duration,
                startPitch: startPitch,
                endPitch: endPitch,
                extras: extras,
                ornamentation: ornamentation)

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
        hasOrnamentation = hasOrnamentation || other.hasOrnamentation
        hasPortamento = hasPortamento || other.hasPortamento
        isMonophonic = Self.isMonophonic(in: notes)
        pitchRange = Self.mergePitchRanges(pitchRange.require(),
                                           other.pitchRange.require())
        timeRange = Self.mergeTimeRanges(timeRange.require(),
                                         other.timeRange.require())
    }

    /// Moves the note with the given identity to a new attack time, keeping its duration,
    /// pitches, extras, and ornamentation, and re-sorts it into place.
    ///
    /// A note’s position depends on all four of its attack, duration, and pitches (see
    /// ``insertionIndex(for:duration:startPitch:endPitch:)``), so changing any one of them can
    /// reorder the table — that is the point of editing any of these fields, not a side effect to
    /// avoid.
    ///
    /// Unlike moving an entry of a time-keyed map or `InstrumentTable`, there is no “merges into a
    /// pre-existing duplicate” case to account for here — a note table allows exact duplicates (see
    /// ``insert(attack:duration:startPitch:endPitch:extras:)``), so `noteID` always keeps naming this
    /// same note after the move, regardless of whether another, unrelated note happens to already
    /// share every field with it.
    ///
    /// - Parameter noteID: The identity of the note to move.
    /// - Parameter attack: The new attack time for the note.
    ///
    /// - Returns:  `true` if `noteID` identified a note and it was moved; `false` if `noteID` did not
    ///             identify any note and nothing moved.
    @discardableResult
    public mutating func moveAttack(noteID: NoteID,
                                    to attack: TimeType) -> Bool {
        guard let position = firstIndex(noteID: noteID)
        else { return false }

        let note = notes.remove(at: position)

        _recomputeSummaries()

        _insert(noteID: noteID,
                attack: attack,
                duration: note.duration,
                startPitch: note.startPitch,
                endPitch: note.endPitch,
                extras: note.extras,
                ornamentation: note.ornamentation)

        return true
    }

    /// Moves the note with the given identity to a new duration, keeping its attack, pitches,
    /// extras, and ornamentation, and re-sorts it into place.
    ///
    /// See ``moveAttack(noteID:to:)`` for why this reorders rather than updating in place, and why `noteID`
    /// always keeps naming the same note afterward.
    ///
    /// - Parameter noteID:     The identity of the note to move.
    /// - Parameter duration:   The new duration for the note.
    ///
    /// - Returns:  `true` if `noteID` identified a note and it was moved; `false` otherwise. See
    ///             ``moveAttack(noteID:to:)``.
    @discardableResult
    public mutating func moveDuration(noteID: NoteID,
                                      to duration: DurationType) -> Bool {
        guard let position = firstIndex(noteID: noteID)
        else { return false }

        let note = notes.remove(at: position)

        _recomputeSummaries()

        _insert(noteID: noteID,
                attack: note.attack,
                duration: duration,
                startPitch: note.startPitch,
                endPitch: note.endPitch,
                extras: note.extras,
                ornamentation: note.ornamentation)

        return true
    }

    /// Moves the note with the given identity to a new end pitch, keeping its attack, duration,
    /// start pitch, extras, and ornamentation, and re-sorts it into place.
    ///
    /// See ``moveAttack(noteID:to:)`` for why this reorders rather than updating in place, and why `noteID`
    /// always keeps naming the same note afterward.
    ///
    /// - Parameter noteID:     The identity of the note to move.
    /// - Parameter endPitch:   The new end pitch for the note.
    ///
    /// - Returns:  `true` if `noteID` identified a note and it was moved; `false` otherwise. See
    ///             ``moveAttack(noteID:to:)``.
    @discardableResult
    public mutating func movePitchEnd(noteID: NoteID,
                                      to endPitch: PitchType) -> Bool {
        guard let position = firstIndex(noteID: noteID)
        else { return false }

        let note = notes.remove(at: position)

        _recomputeSummaries()

        _insert(noteID: noteID,
                attack: note.attack,
                duration: note.duration,
                startPitch: note.startPitch,
                endPitch: endPitch,
                extras: note.extras,
                ornamentation: note.ornamentation)

        return true
    }

    /// Moves the note with the given identity to a new start pitch, keeping its attack, duration,
    /// end pitch, extras, and ornamentation, and re-sorts it into place.
    ///
    /// See ``moveAttack(noteID:to:)`` for why this reorders rather than updating in place, and why `noteID`
    /// always keeps naming the same note afterward.
    ///
    /// The new start pitch must keep the ornament’s written partner, if any, strictly on its side
    /// (see ``insert(attack:duration:startPitch:endPitch:extras:ornamentation:)``); otherwise the
    /// note is left unchanged and this throws.
    ///
    /// - Parameter noteID:     The identity of the note to move.
    /// - Parameter startPitch: The new start pitch for the note.
    ///
    /// - Returns:  `true` if `noteID` identified a note and it was moved; `false` otherwise. See
    ///             ``moveAttack(noteID:to:)``.
    ///
    /// - Throws:   ``NoteTable/Error/partnerOnWrongSide(_:_:_:_:)`` if `startPitch` would put the
    ///             ornament’s written partner on the wrong side of the note.
    @discardableResult
    public mutating func movePitchStart(noteID: NoteID,
                                        to startPitch: PitchType) throws(Error) -> Bool {
        guard let position = firstIndex(noteID: noteID)
        else { return false }

        let oldNote = notes[position]

        guard !Self.hasPartnerOnWrongSide(oldNote.ornamentation, startPitch: startPitch)
        else { throw .partnerOnWrongSide(oldNote.attack, oldNote.duration, startPitch, oldNote.endPitch) }

        let note = notes.remove(at: position)

        _recomputeSummaries()

        _insert(noteID: noteID,
                attack: note.attack,
                duration: note.duration,
                startPitch: startPitch,
                endPitch: note.endPitch,
                extras: note.extras,
                ornamentation: note.ornamentation)

        return true
    }

    /// Removes the note with the given identity, if present.
    ///
    /// - Parameter noteID: The identity of the note to remove. An identity
    ///                     naming no note is ignored.
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

        if note.ornamentation != nil {
            hasOrnamentation = Self.hasOrnamentation(in: notes)
        }

        if note.startPitch != note.endPitch {
            hasPortamento = Self.hasPortamento(in: notes)
        }

        _recomputeSummaries()

        return true
    }

    /// Updates the extras attached to the note with the given identity, keeping its attack,
    /// duration, pitches, and ornamentation unchanged.
    ///
    /// Unlike ``moveAttack(noteID:to:)`` and its siblings, this never reorders the table — a
    /// note’s position depends only on its attack, duration, and pitches (see
    /// ``insertionIndex(for:duration:startPitch:endPitch:)``), which extras play no part in — so
    /// this replaces the note in place at its existing index rather than removing and
    /// reinserting it. That distinction matters when two notes tie on every
    /// position-determining field: reinserting one of them would always land it after the other
    /// (see `insertionIndex`’s doc comment), silently swapping their relative order even though
    /// neither note’s own position actually changed.
    ///
    /// - Parameter noteID: The identity of the note to update.
    /// - Parameter extras: The new extras for the note.
    ///
    /// - Returns:  `true` if `noteID` identified a note and it was updated; `false` if `noteID`
    ///             named no note and nothing happened.
    @discardableResult
    public mutating func updateExtras(noteID: NoteID,
                                      extras: Extras?) -> Bool {
        guard let position = firstIndex(noteID: noteID)
        else { return false }

        let note = notes[position]

        notes[position] = StoredNote(noteID: noteID,
                                     attack: note.attack,
                                     duration: note.duration,
                                     startPitch: note.startPitch,
                                     endPitch: note.endPitch,
                                     extras: extras,
                                     ornamentation: note.ornamentation)

        hasExtras = Self.hasExtras(in: notes)

        return true
    }

    /// Updates the ornamentation of the note with the given identity, keeping its attack,
    /// duration, pitches, and extras unchanged.
    ///
    /// Like ``updateExtras(noteID:extras:)``, this never reorders the table: ornamentation plays
    /// no part in a note’s position, so the note is replaced in place.
    ///
    /// - Parameter noteID:         The identity of the note to update.
    /// - Parameter ornamentation:  The new ornamentation for the note, or `nil` for none.
    ///
    /// - Returns:  `true` if `noteID` identified a note and it was updated; `false` if `noteID`
    ///             named no note and nothing happened.
    ///
    /// - Throws:   ``NoteTable/Error/partnerOnWrongSide(_:_:_:_:)`` if the ornament’s written
    ///             partner isn’t strictly on its side of the note’s start pitch; the note is left
    ///             unchanged.
    @discardableResult
    public mutating func updateOrnamentation(noteID: NoteID,
                                             ornamentation: Ornamentation?) throws(Error) -> Bool {
        guard let position = firstIndex(noteID: noteID)
        else { return false }

        let note = notes[position]

        guard !Self.hasPartnerOnWrongSide(ornamentation, startPitch: note.startPitch)
        else { throw .partnerOnWrongSide(note.attack, note.duration, note.startPitch, note.endPitch) }

        notes[position] = StoredNote(noteID: noteID,
                                     attack: note.attack,
                                     duration: note.duration,
                                     startPitch: note.startPitch,
                                     endPitch: note.endPitch,
                                     extras: note.extras,
                                     ornamentation: ornamentation)

        hasOrnamentation = Self.hasOrnamentation(in: notes)

        return true
    }

    // MARK: Private Instance Methods

    private mutating func _insert(noteID: NoteID,
                                  attack: TimeType,
                                  duration: DurationType,
                                  startPitch: PitchType,
                                  endPitch: PitchType,
                                  extras: Extras?,
                                  ornamentation: Ornamentation?) {
        let note = StoredNote(noteID: noteID,
                              attack: attack,
                              duration: duration,
                              startPitch: startPitch,
                              endPitch: endPitch,
                              extras: extras,
                              ornamentation: ornamentation)
        let index = insertionIndex(for: attack,
                                   duration: duration,
                                   startPitch: startPitch,
                                   endPitch: endPitch)

        // The other notes are already sorted and, if monophonic, free of overlaps, so the new
        // note can only break monophony against its neighbours.
        if isMonophonic {
            let followsPrevious = index > notes.startIndex ? notes[index - 1].release <= attack : attack >= TimeType.zero
            let precedesNext = index < notes.endIndex ? note.release <= notes[index].attack : true

            isMonophonic = followsPrevious && precedesNext
        }

        notes.insert(note, at: index)

        if note.extras != nil {
            hasExtras = true
        }

        if note.ornamentation != nil {
            hasOrnamentation = true
        }

        if startPitch != endPitch {
            hasPortamento = true
        }

        let notePitchRange = note.minimumPitch...note.maximumPitch
        let noteTimeRange = note.attack...note.release

        pitchRange = pitchRange.map { Self.mergePitchRanges($0, notePitchRange) } ?? notePitchRange
        timeRange = timeRange.map { Self.mergeTimeRanges($0, noteTimeRange) } ?? noteTimeRange
    }

    // Recomputes the summaries that `_insert` updates incrementally, after a note has been
    // removed and they may have shrunk.
    private mutating func _recomputeSummaries() {
        isMonophonic = Self.isMonophonic(in: notes)
        pitchRange = Self.pitchRange(in: notes)
        timeRange = Self.timeRange(in: notes)
    }
}
