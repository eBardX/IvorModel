// © 2026 John Gary Pusey (see LICENSE.md)

internal import IvorTiming
internal import IvorTuning
internal import XestiTools

extension Work {

    // MARK: Public Instance Methods

    /// Copies notes into a strand, under new IDs. The copies keep their times, pitches, extras
    /// and ornamentation, and take on the instrument and dynamics of the strand they land in.
    /// Copies of rolled notes from another part get fresh arpeggio groups in the strand’s part.
    ///
    /// - Parameter noteIDs:    The IDs of the notes to copy, wherever they are in this work.
    /// - Parameter strandID:   The ID of the strand to copy them into.
    ///
    /// - Returns:  The ID of each copy, by the ID of the note it copies.
    ///
    /// - Throws:   ``Work/Error/workIsLocked`` if this work is locked;
    ///             ``Work/Error/unknownNoteID(_:)`` or ``Work/Error/unknownStrandID(_:)`` if an
    ///             ID isn’t in this work.
    @discardableResult
    public mutating func copyNotes(_ noteIDs: Set<NoteID>,
                                   to strandID: StrandID) throws(Error) -> [NoteID: NoteID] {
        try editingContent { content throws(Error) in
            try Self._bringNotes(noteIDs, to: strandID, copying: true, in: &content.body)
        }
    }

    /// Merges strands of one part into the first of them in score order, which keeps its name,
    /// its own tables and its extras. The others’ notes move into it, keeping their IDs, and the
    /// others are removed.
    ///
    /// - Parameter strandIDs:  The IDs of the strands to merge.
    ///
    /// - Returns:  The ID of the strand they merged into, or `nil` if `strandIDs` is empty.
    ///
    /// - Throws:   ``Work/Error/workIsLocked`` if this work is locked;
    ///             ``Work/Error/unknownStrandID(_:)`` if an ID isn’t in this work;
    ///             ``Work/Error/strandsInDifferentParts`` if the strands aren’t all in one part.
    @discardableResult
    public mutating func mergeStrands(_ strandIDs: Set<StrandID>) throws(Error) -> StrandID? {
        try editingContent { content throws(Error) in
            try Self._mergeStrands(strandIDs, in: &content.body)
        }
    }

    /// Moves notes into a strand, of the same part or another. Each note keeps its ID, times,
    /// pitches, extras and ornamentation, and takes on the instrument and dynamics of the strand
    /// it lands in; no table moves. A rolled note moved to another part leaves its arpeggio
    /// group and gets a fresh one there, shared with the notes of its group that move with it.
    ///
    /// - Parameter noteIDs:    The IDs of the notes to move, wherever they are in this work.
    /// - Parameter strandID:   The ID of the strand to move them into.
    ///
    /// - Throws:   ``Work/Error/workIsLocked`` if this work is locked;
    ///             ``Work/Error/unknownNoteID(_:)`` or ``Work/Error/unknownStrandID(_:)`` if an
    ///             ID isn’t in this work.
    public mutating func moveNotes(_ noteIDs: Set<NoteID>,
                                   to strandID: StrandID) throws(Error) {
        try editingContent { content throws(Error) in
            _ = try Self._bringNotes(noteIDs, to: strandID, copying: false, in: &content.body)
        }
    }

    /// Removes notes, wherever they are in this work.
    ///
    /// - Parameter noteIDs:    The IDs of the notes to remove.
    ///
    /// - Throws:   ``Work/Error/workIsLocked`` if this work is locked;
    ///             ``Work/Error/unknownNoteID(_:)`` if an ID isn’t in this work.
    public mutating func removeNotes(_ noteIDs: Set<NoteID>) throws(Error) {
        try editingContent { content throws(Error) in
            try Self._removeNotes(noteIDs, from: &content.body)
        }
    }

    /// Splits the notes a scope takes out of a strand into a new strand beside it.
    ///
    /// The new strand copies the source’s own instrument table, dynamic map and extras, so
    /// nothing sounds or exports differently until they’re changed. It goes above the source when
    /// it takes the upper pitches (its lowest at least the highest left behind), and after it
    /// otherwise. The notes keep their IDs.
    ///
    /// - Parameter strandID:   The ID of the strand to split.
    /// - Parameter scope:      The notes to split off. Build it with
    ///                         ``Work/scope(matching:within:)`` to split by time or pitch.
    ///
    /// - Returns:  The new strand’s ID.
    ///
    /// - Throws:   ``Work/Error/workIsLocked`` if this work is locked; an unknown-ID case if
    ///             an ID isn’t in this work; ``Work/Error/scopeOutsideStrand(_:)`` if `scope`
    ///             takes anything outside the strand.
    @discardableResult
    public mutating func splitStrand(_ strandID: StrandID,
                                     scope: Scope) throws(Error) -> StrandID {
        try editingContent { content throws(Error) in
            try Self._splitStrand(strandID, scope: scope, in: &content.body)
        }
    }

    // MARK: Private Type Methods

    //
    // Moves (or copies, under new IDs) the notes `noteIDs` names into the strand `strandID`
    // names. Rolled notes from another part get fresh arpeggio groups in the strand's part, one
    // for each group they came from. Returns each copy's ID by its original's (none for a move).
    //
    private static func _bringNotes<WorkBody: Body>(_ noteIDs: Set<NoteID>,
                                                    to strandID: StrandID,
                                                    copying: Bool,
                                                    in body: inout WorkBody) throws(Error) -> [NoteID: NoteID] {
        let destination = try strandLocation(of: strandID, in: body)
        let sources = try _bySource(noteLocations(of: noteIDs, in: body))
        var nextGroup = body.parts[destination.part].unusedArpeggioGroup.uintValue
        var arrived = NoteTable<WorkBody.TimeType, WorkBody.PitchType>()
        var copies: [NoteID: NoteID] = [:]

        for (source, sourceNoteIDs) in sources {
            let isDestination = source.part == destination.part && source.strand == destination.strand

            if isDestination, !copying {
                continue
            }

            var (taken, kept) = body.parts[source.part].strands[source.strand].noteTable.partitioned(by: sourceNoteIDs)

            if copying {
                taken = NoteTable(notes: taken.notes.map { note in
                    let copy = note.renewingNoteID()

                    copies[note.noteID] = copy.noteID

                    return copy
                })
            } else {
                body.parts[source.part].strands[source.strand].noteTable = kept
            }

            if source.part != destination.part {
                var groups: [ArpeggioGroup: ArpeggioGroup] = [:]

                for group in taken.arpeggioGroups.sorted() {
                    groups[group] = ArpeggioGroup(uintValue: nextGroup).require()
                    nextGroup += 1
                }

                taken = taken.regroupingArpeggios(groups)
            }

            arrived.merge(with: taken)
        }

        body.parts[destination.part].strands[destination.strand].noteTable.merge(with: arrived)

        return copies
    }

    //
    // The notes `locations` places, by the strand they're in, in score order, so that fresh
    // arpeggio groups are given in a fixed order.
    //
    private static func _bySource(_ locations: [NoteID: (part: Int, strand: Int)]) -> [(key: (part: Int, strand: Int), value: Set<NoteID>)] {
        var byStrand: [Int: [Int: Set<NoteID>]] = [:]

        for (noteID, location) in locations {
            byStrand[location.part, default: [:]][location.strand, default: []].insert(noteID)
        }

        return byStrand.sorted { $0.key < $1.key }.flatMap { part, strands in
            strands.sorted { $0.key < $1.key }.map { (key: (part: part, strand: $0.key), value: $0.value) }
        }
    }

    private static func _mergeStrands(_ strandIDs: Set<StrandID>,
                                      in body: inout some Body) throws(Error) -> StrandID? {
        var locations: [(part: Int, strand: Int)] = []

        for strandID in strandIDs.sorted(by: { $0.stringValue < $1.stringValue }) {
            try locations.append(strandLocation(of: strandID, in: body))
        }

        guard let partIndex = locations.first?.part
        else { return nil }

        guard locations.allSatisfy({ $0.part == partIndex })
        else { throw .strandsInDifferentParts }

        let indices = locations.map(\.strand).sorted()
        let survivor = indices[0]

        for index in indices.dropFirst().reversed() {
            let strand = body.parts[partIndex].strands.remove(at: index)

            body.parts[partIndex].strands[survivor].noteTable.merge(with: strand.noteTable)
        }

        return body.parts[partIndex].strands[survivor].strandID
    }

    private static func _removeNotes(_ noteIDs: Set<NoteID>,
                                     from body: inout some Body) throws(Error) {
        for (source, sourceNoteIDs) in try _bySource(noteLocations(of: noteIDs, in: body)) {
            body.parts[source.part].strands[source.strand].noteTable = body.parts[source.part]
                .strands[source.strand].noteTable.partitioned(by: sourceNoteIDs).kept
        }
    }

    private static func _splitStrand(_ strandID: StrandID,
                                     scope: Scope,
                                     in body: inout some Body) throws(Error) -> StrandID {
        let location = try strandLocation(of: strandID, in: body)
        let part = body.parts[location.part]
        let strand = part.strands[location.strand]
        var noteIDs: Set<NoteID>?

        for (partID, selection) in try scope.resolved(in: body).selections {
            guard partID == part.partID
            else { throw .scopeOutsideStrand(strandID) }

            switch selection {
            case let .strands(strandSelections):
                guard let strandSelection = strandSelections[strandID],
                      strandSelections.count == 1
                else { throw .scopeOutsideStrand(strandID) }

                noteIDs = strandSelection.noteIDs ?? Set(strand.noteTable.map(\.noteID))

            case .whole:
                guard part.strands.count == 1
                else { throw .scopeOutsideStrand(strandID) }

                noteIDs = Set(strand.noteTable.map(\.noteID))
            }
        }

        let (taken, kept) = strand.noteTable.partitioned(by: noteIDs ?? [])
        let newStrand = Strand(strandID: StrandID(),
                               name: "",
                               noteTable: taken,
                               instrumentTable: strand.instrumentTable,
                               dynamicMap: strand.dynamicMap,
                               extras: strand.extras)
        let takesUpperPitches = if let takenRange = taken.pitchRange,
                                   let keptRange = kept.pitchRange {
            takenRange.lowerBound >= keptRange.upperBound
        } else {
            false
        }

        body.parts[location.part].strands[location.strand].noteTable = kept
        body.parts[location.part].strands.insert(newStrand,
                                                 at: takesUpperPitches ? location.strand : location.strand + 1)

        return newStrand.strandID
    }
}
