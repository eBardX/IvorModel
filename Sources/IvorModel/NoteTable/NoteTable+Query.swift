// © 2026 John Gary Pusey (see LICENSE.md)

extension NoteTable {

    // MARK: Public Instance Properties

    /// The arpeggio groups the notes in this table belong to.
    ///
    /// Tones anywhere in a work that share an attack and an ``ArpeggioGroup`` roll as one, so a
    /// new roll needs a group no part of the work uses (see ``Work/unusedArpeggioGroup``).
    public var arpeggioGroups: Set<ArpeggioGroup> {
        Set(notes.compactMap { $0.ornamentation?.arpeggio?.group })
    }

    // MARK: Public Instance Methods

    /// Returns the identities of the notes whose attack time falls within a range.
    ///
    /// - Parameter range:  The closed range of attack times to select.
    ///
    /// - Returns:  The identities of the matching notes, for use with any transform’s
    ///             `noteIDs:` parameter.
    public func attackingIn(_ range: ClosedRange<TimeType>) -> Set<NoteID> {
        Set(notes.filter { range.contains($0.attack) }.map(\.noteID))
    }

    /// Returns the identities of the notes whose pitch — start, end, or anything a portamento
    /// glides through — falls within a range.
    ///
    /// - Parameter range:  The closed range of pitches to select.
    ///
    /// - Returns:  The identities of the matching notes, for use with any transform’s
    ///             `noteIDs:` parameter.
    public func pitchIn(_ range: ClosedRange<PitchType>) -> Set<NoteID> {
        Set(notes.filter { $0.minimumPitch <= range.upperBound && $0.maximumPitch >= range.lowerBound }.map(\.noteID))
    }

    /// Returns the identities of the notes sounding at any point within a range — that is, whose
    /// attack-to-release span overlaps the range, not only notes that attack within it.
    ///
    /// - Parameter range:  The closed range of times to select.
    ///
    /// - Returns:  The identities of the matching notes, for use with any transform’s
    ///             `noteIDs:` parameter.
    public func soundingIn(_ range: ClosedRange<TimeType>) -> Set<NoteID> {
        Set(notes.filter { $0.attack <= range.upperBound && $0.release >= range.lowerBound }.map(\.noteID))
    }

    // MARK: Internal Instance Methods

    //
    // This table with each arpeggio's group replaced as `groups` maps it; a group it doesn't map
    // is kept. Used to give a duplicated part's rolls their own groups.
    //
    internal func regroupingArpeggios(_ groups: [ArpeggioGroup: ArpeggioGroup]) -> Self {
        Self(notes: notes.map { note in
            guard let ornamentation = note.ornamentation,
                  let arpeggio = ornamentation.arpeggio,
                  let group = groups[arpeggio.group]
            else { return note }

            return StoredNote(noteID: note.noteID,
                              attack: note.attack,
                              duration: note.duration,
                              startPitch: note.startPitch,
                              endPitch: note.endPitch,
                              extras: note.extras,
                              ornamentation: Ornamentation(graceBefore: ornamentation.graceBefore,
                                                           graceAfter: ornamentation.graceAfter,
                                                           ornament: ornamentation.ornament,
                                                           arpeggio: Arpeggio(group: group,
                                                                              direction: arpeggio.direction,
                                                                              execution: arpeggio.execution),
                                                           fermata: ornamentation.fermata))
        })
    }
}
