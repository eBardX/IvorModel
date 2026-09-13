// © 2026 John Gary Pusey (see LICENSE.md)

extension NoteTable {

    // MARK: Public Instance Methods

    /// Returns the identities of the notes whose attack time falls within a range.
    ///
    /// - Parameter range:   The closed range of attack times to select.
    ///
    /// - Returns:  The identities of the matching notes, for use with any transform’s
    ///             `noteIDs:` parameter.
    public func attackingIn(_ range: ClosedRange<TimeType>) -> Set<NoteID> {
        Set(notes.filter { range.contains($0.attack) }.map(\.noteID))
    }

    /// Returns the identities of the notes whose pitch — start, end, or anything a portamento
    /// glides through — falls within a range.
    ///
    /// - Parameter range:   The closed range of pitches to select.
    ///
    /// - Returns:  The identities of the matching notes, for use with any transform’s
    ///             `noteIDs:` parameter.
    public func pitchIn(_ range: ClosedRange<PitchType>) -> Set<NoteID> {
        Set(notes.filter { $0.minimumPitch <= range.upperBound && $0.maximumPitch >= range.lowerBound }.map(\.noteID))
    }

    /// Returns the identities of the notes sounding at any point within a range — that is, whose
    /// attack-to-release span overlaps the range, not only notes that attack within it.
    ///
    /// - Parameter range:   The closed range of times to select.
    ///
    /// - Returns:  The identities of the matching notes, for use with any transform’s
    ///             `noteIDs:` parameter.
    public func soundingIn(_ range: ClosedRange<TimeType>) -> Set<NoteID> {
        Set(notes.filter { $0.attack <= range.upperBound && $0.release >= range.lowerBound }.map(\.noteID))
    }
}
