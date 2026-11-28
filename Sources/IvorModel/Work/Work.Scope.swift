// © 2026 John Gary Pusey (see LICENSE.md)

internal import IvorTiming
internal import IvorTuning

extension Work {

    // MARK: Public Nested Types

    /// The notes a transform works on, and so whose tables it carries: any mix of whole parts,
    /// whole strands and single notes in a work.
    ///
    /// Build a scope from ``all``, ``init(parts:)``, ``init(strands:)`` or ``init(notes:)``, and
    /// combine scopes with ``union(_:)``. A strand or a note is found in its part by its ID
    /// alone, so a caller never says where it lives.
    ///
    /// Wholes add up, but notes never do: naming every strand of a part covers the part, as
    /// naming the part does, but naming every note of a strand one by one covers only those
    /// notes. The difference matters because a transform carries a table only when its scope
    /// covers everything that shares the table: the work’s tables need the whole work; a part’s
    /// pedals, pan and marks need the whole part; the part’s instrument table and dynamic map
    /// need every strand that uses them; and a strand’s own tables need the whole strand (or,
    /// for some of its notes, only the entries within their time range move).
    public struct Scope {

        // MARK: Public Initializers

        /// Creates a scope of whole parts.
        ///
        /// - Parameter partIDs:    The IDs of the parts.
        public init(parts partIDs: some Sequence<PartID>) {
            self.init(isAll: false,
                      noteIDs: [],
                      partIDs: Set(partIDs),
                      strandIDs: [])
        }

        /// Creates a scope of whole strands, wherever in the work they are.
        ///
        /// - Parameter strandIDs:  The IDs of the strands.
        public init(strands strandIDs: some Sequence<StrandID>) {
            self.init(isAll: false,
                      noteIDs: [],
                      partIDs: [],
                      strandIDs: Set(strandIDs))
        }

        /// Creates a scope of single notes, wherever in the work they are.
        ///
        /// - Parameter noteIDs:    The IDs of the notes.
        public init(notes noteIDs: some Sequence<NoteID>) {
            self.init(isAll: false,
                      noteIDs: Set(noteIDs),
                      partIDs: [],
                      strandIDs: [])
        }

        // MARK: Private Initializers

        private init(isAll: Bool,
                     noteIDs: Set<NoteID>,
                     partIDs: Set<PartID>,
                     strandIDs: Set<StrandID>) {
            self.isAll = isAll
            self.noteIDs = noteIDs
            self.partIDs = partIDs
            self.strandIDs = strandIDs
        }

        // MARK: Internal Instance Properties

        internal let isAll: Bool
        internal let noteIDs: Set<NoteID>
        internal let partIDs: Set<PartID>
        internal let strandIDs: Set<StrandID>
    }
}

// MARK: -

extension Work.Scope {

    // MARK: Public Type Properties

    /// The scope of the whole work: every part, whole.
    public static let all = Self(isAll: true,
                                 noteIDs: [],
                                 partIDs: [],
                                 strandIDs: [])

    // MARK: Public Instance Properties

    /// Whether this scope names nothing at all.
    public var isEmpty: Bool {
        !isAll && noteIDs.isEmpty && partIDs.isEmpty && strandIDs.isEmpty
    }

    // MARK: Public Instance Methods

    /// Combines this scope with another.
    ///
    /// - Parameter other:  The scope to combine with this one.
    ///
    /// - Returns:  A scope naming everything that either scope names.
    public func union(_ other: Self) -> Self {
        Self(isAll: isAll || other.isAll,
             noteIDs: noteIDs.union(other.noteIDs),
             partIDs: partIDs.union(other.partIDs),
             strandIDs: strandIDs.union(other.strandIDs))
    }

    // MARK: Internal Instance Methods

    //
    // This scope resolved against `body`'s parts to its canonical form (see `ResolvedScope`).
    // Naming a part, strand or note that isn't in the work is an error.
    //
    internal func resolved(in body: some Work.Body) throws(Work.Error) -> Work.ResolvedScope {
        let parts = body.parts
        var selections: [PartID: Work.PartSelection] = [:]

        if isAll {
            for part in parts {
                selections[part.partID] = .whole
            }
        }

        let partIDsInWork = Set(parts.map(\.partID))

        for partID in partIDs.sorted(by: { $0.stringValue < $1.stringValue }) {
            guard partIDsInWork.contains(partID)
            else { throw .unknownPartID(partID) }

            selections[partID] = .whole
        }

        let (strandParts, noteHomes) = _homes(in: parts)

        for strandID in strandIDs.sorted(by: { $0.stringValue < $1.stringValue }) {
            guard let partID = strandParts[strandID]
            else { throw .unknownStrandID(strandID) }

            Self._add(.whole, strandID: strandID, partID: partID, to: &selections)
        }

        for noteID in noteIDs.sorted(by: { $0.stringValue < $1.stringValue }) {
            guard let home = noteHomes[noteID]
            else { throw .unknownNoteID(noteID) }

            Self._add(.notes([noteID]), strandID: home.strandID, partID: home.partID, to: &selections)
        }

        Self._addUpWholes(of: parts, in: &selections)

        return Work.ResolvedScope(selections: selections,
                                  partIDs: parts.map(\.partID))
    }

    // MARK: Private Type Methods

    //
    // Wholes add up: a part whose every strand is taken whole is taken whole.
    //
    private static func _addUpWholes(of parts: [Part<some TimeProtocol, some PitchProtocol>],
                                     in selections: inout [PartID: Work.PartSelection]) {
        for part in parts {
            guard case let .strands(strandSelections) = selections[part.partID],
                  part.strandIDs.allSatisfy({ strandSelections[$0] == .whole })
            else { continue }

            selections[part.partID] = .whole
        }
    }

    //
    // Adds `selection` of a strand to the part's selection. A whole part, or a whole strand,
    // already takes in anything added to it.
    //
    private static func _add(_ selection: Work.StrandSelection,
                             strandID: StrandID,
                             partID: PartID,
                             to selections: inout [PartID: Work.PartSelection]) {
        var strandSelections: [StrandID: Work.StrandSelection]

        switch selections[partID] {
        case .whole:
            return

        case let .strands(existing):
            strandSelections = existing

        case nil:
            strandSelections = [:]
        }

        switch (strandSelections[strandID], selection) {
        case (.whole, _):
            return

        case let (.notes(existing), .notes(added)):
            strandSelections[strandID] = .notes(existing.union(added))

        default:
            strandSelections[strandID] = selection
        }

        selections[partID] = .strands(strandSelections)
    }

    // MARK: Private Type Aliases

    //
    // The part of every strand, and the part and strand of every note.
    //
    private typealias Homes = ([StrandID: PartID], [NoteID: (partID: PartID, strandID: StrandID)])

    // MARK: Private Instance Methods

    //
    // The part of every strand in `parts`, and, when this scope names notes, the part and strand
    // of every note.
    //
    private func _homes(in parts: [Part<some TimeProtocol, some PitchProtocol>]) -> Homes {
        var strandParts: [StrandID: PartID] = [:]
        var noteHomes: [NoteID: (partID: PartID, strandID: StrandID)] = [:]

        for part in parts {
            for strand in part.strands {
                strandParts[strand.strandID] = part.partID

                if !noteIDs.isEmpty {
                    for note in strand.noteTable {
                        noteHomes[note.noteID] = (part.partID, strand.strandID)
                    }
                }
            }
        }

        return (strandParts, noteHomes)
    }
}

// MARK: - Equatable

extension Work.Scope: Equatable {
}

// MARK: - Hashable

extension Work.Scope: Hashable {
}

// MARK: - Sendable

extension Work.Scope: Sendable {
}
