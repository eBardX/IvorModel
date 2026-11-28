// © 2026 John Gary Pusey (see LICENSE.md)

internal import IvorTiming
internal import IvorTuning

//
// What the strand and note operations share: finding parts, strands and notes by ID, and
// editing the content so that a failure, or an edit that would break an invariant, leaves the
// work unchanged.
//
extension Work {

    // MARK: Internal Type Methods

    //
    // Where each note `noteIDs` names is: its part's and strand's indices. Naming a note that
    // isn't in the work is an error.
    //
    internal static func noteLocations(of noteIDs: Set<NoteID>,
                                       in body: some Body) throws(Error) -> [NoteID: (part: Int, strand: Int)] {
        var locations: [NoteID: (part: Int, strand: Int)] = [:]

        for (partIndex, part) in body.parts.enumerated() {
            for (strandIndex, strand) in part.strands.enumerated() {
                for note in strand.noteTable where noteIDs.contains(note.noteID) {
                    locations[note.noteID] = (partIndex, strandIndex)
                }
            }
        }

        if let missing = noteIDs.subtracting(locations.keys).min(by: { $0.stringValue < $1.stringValue }) {
            throw .unknownNoteID(missing)
        }

        return locations
    }

    //
    // The index of the part `partID` names. Naming a part that isn't in the work is an error.
    //
    internal static func partIndex(of partID: PartID,
                                   in body: some Body) throws(Error) -> Int {
        guard let index = body.parts.firstIndex(where: { $0.partID == partID })
        else { throw .unknownPartID(partID) }

        return index
    }

    //
    // The indices of the part holding the strand `strandID` names, and of the strand within it.
    // Naming a strand that isn't in the work is an error.
    //
    internal static func strandLocation(of strandID: StrandID,
                                        in body: some Body) throws(Error) -> (part: Int, strand: Int) {
        for (partIndex, part) in body.parts.enumerated() {
            if let strandIndex = part.index(ofStrandID: strandID) {
                return (partIndex, strandIndex)
            }
        }

        throw .unknownStrandID(strandID)
    }

    // MARK: Internal Instance Methods

    //
    // Applies `edit` to a copy of the content, and keeps the result only if it succeeds and
    // keeps every invariant (see `Work.Content.invariantError`). A locked work is refused first.
    //
    internal mutating func editingContent<R>(_ edit: (inout Content) throws(Error) -> R) throws(Error) -> R {
        try ensureUnlocked()

        var newContent = content
        let result = try edit(&newContent)

        if let error = newContent.invariantError {
            throw error
        }

        content = newContent

        return result
    }
}
