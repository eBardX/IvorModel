// © 2026 John Gary Pusey (see LICENSE.md)

public import XestiTools

internal import IvorTiming
internal import IvorTuning

extension Work {

    // MARK: Public Instance Methods

    /// Adds an empty strand at the end of a part’s strands.
    ///
    /// - Parameter name:   The new strand’s name. Defaults to none.
    /// - Parameter partID: The ID of the part to add the strand to.
    ///
    /// - Returns:  The new strand’s ID.
    ///
    /// - Throws:   ``Work/Error/workIsLocked`` if this work is locked;
    ///             ``Work/Error/unknownPartID(_:)`` if no part has the ID.
    @discardableResult
    public mutating func addStrand(named name: String = "",
                                   to partID: PartID) throws(Error) -> StrandID {
        try editingContent { content throws(Error) in
            try Self._addStrand(named: name, to: partID, in: &content.body)
        }
    }

    /// Gives a strand a dynamic map of its own, starting as a copy of its part’s. A strand that
    /// already has one keeps it.
    ///
    /// - Parameter strandID:   The ID of the strand.
    ///
    /// - Throws:   ``Work/Error/workIsLocked`` if this work is locked;
    ///             ``Work/Error/unknownStrandID(_:)`` if no strand has the ID.
    public mutating func giveOwnDynamicMap(to strandID: StrandID) throws(Error) {
        try editingContent { content throws(Error) in
            try Self._editStrand(strandID, .giveOwnDynamicMap, in: &content.body)
        }
    }

    /// Gives a strand an instrument table of its own, starting as a copy of its part’s. A
    /// strand that already has one keeps it.
    ///
    /// - Parameter strandID:   The ID of the strand.
    ///
    /// - Throws:   ``Work/Error/workIsLocked`` if this work is locked;
    ///             ``Work/Error/unknownStrandID(_:)`` if no strand has the ID.
    public mutating func giveOwnInstrumentTable(to strandID: StrandID) throws(Error) {
        try editingContent { content throws(Error) in
            try Self._editStrand(strandID, .giveOwnInstrumentTable, in: &content.body)
        }
    }

    /// Removes the strands with no notes, among those a scope takes.
    ///
    /// “Empty” means no notes, whatever else a strand has: a name and tables of its own go
    /// with it. A part is never emptied: if every one of its strands is empty, the first in
    /// score order stays.
    ///
    /// - Parameter scope:  The parts and strands to look among. Only the strands it takes count.
    ///                     Defaults to ``Work/Scope/all``.
    ///
    /// - Returns:  The IDs of the strands removed.
    ///
    /// - Throws:   ``Work/Error/workIsLocked`` if this work is locked; an unknown-ID case if
    ///             `scope` names something not in this work.
    @discardableResult
    public mutating func removeEmptyStrands(scope: Scope = .all) throws(Error) -> Set<StrandID> {
        try editingContent { content throws(Error) in
            try Self._removeEmptyStrands(scope: scope, from: &content.body)
        }
    }

    /// Removes a strand’s own dynamic map, so it uses its part’s again.
    ///
    /// - Parameter strandID:   The ID of the strand.
    ///
    /// - Throws:   ``Work/Error/workIsLocked`` if this work is locked;
    ///             ``Work/Error/unknownStrandID(_:)`` if no strand has the ID.
    public mutating func removeOwnDynamicMap(from strandID: StrandID) throws(Error) {
        try editingContent { content throws(Error) in
            try Self._editStrand(strandID, .removeOwnDynamicMap, in: &content.body)
        }
    }

    /// Removes a strand’s own instrument table, so it uses its part’s again.
    ///
    /// - Parameter strandID:   The ID of the strand.
    ///
    /// - Throws:   ``Work/Error/workIsLocked`` if this work is locked;
    ///             ``Work/Error/unknownStrandID(_:)`` if no strand has the ID.
    public mutating func removeOwnInstrumentTable(from strandID: StrandID) throws(Error) {
        try editingContent { content throws(Error) in
            try Self._editStrand(strandID, .removeOwnInstrumentTable, in: &content.body)
        }
    }

    /// Removes a strand, with its notes and tables.
    ///
    /// - Parameter strandID:   The ID of the strand.
    ///
    /// - Throws:   ``Work/Error/workIsLocked`` if this work is locked;
    ///             ``Work/Error/unknownStrandID(_:)`` if no strand has the ID;
    ///             ``Work/Error/lastStrand(_:)`` if it is its part’s only strand (remove the part
    ///             instead).
    public mutating func removeStrand(_ strandID: StrandID) throws(Error) {
        try editingContent { content throws(Error) in
            try Self._editStrand(strandID, .remove, in: &content.body)
        }
    }

    /// Renames a strand.
    ///
    /// - Parameter strandID:   The ID of the strand.
    /// - Parameter name:       The strand’s new name.
    ///
    /// - Throws:   ``Work/Error/workIsLocked`` if this work is locked;
    ///             ``Work/Error/unknownStrandID(_:)`` if no strand has the ID.
    public mutating func renameStrand(_ strandID: StrandID,
                                      to name: String) throws(Error) {
        try editingContent { content throws(Error) in
            try Self._editStrand(strandID, .rename(name), in: &content.body)
        }
    }

    /// Replaces a strand’s extras.
    ///
    /// - Parameter extras:     The strand’s new extras, or `nil` for none.
    /// - Parameter strandID:   The ID of the strand.
    ///
    /// - Throws:   ``Work/Error/workIsLocked`` if this work is locked;
    ///             ``Work/Error/unknownStrandID(_:)`` if no strand has the ID.
    public mutating func setExtras(_ extras: Extras?,
                                   ofStrand strandID: StrandID) throws(Error) {
        try editingContent { content throws(Error) in
            try Self._editStrand(strandID, .setExtras(extras), in: &content.body)
        }
    }

    /// Moves a strand to another place in its part’s score order.
    ///
    /// - Parameter strandID:   The ID of the strand.
    /// - Parameter index:      The strand’s new index among its part’s strands, clamped to
    ///                         them.
    ///
    /// - Throws:   ``Work/Error/workIsLocked`` if this work is locked;
    ///             ``Work/Error/unknownStrandID(_:)`` if no strand has the ID.
    public mutating func shiftStrand(_ strandID: StrandID,
                                     to index: Int) throws(Error) {
        try editingContent { content throws(Error) in
            try Self._editStrand(strandID, .shift(index), in: &content.body)
        }
    }

    // MARK: Private Type Methods

    private static func _addStrand<WorkBody: Body>(named name: String,
                                                   to partID: PartID,
                                                   in body: inout WorkBody) throws(Error) -> StrandID {
        let index = try partIndex(of: partID, in: body)
        let strand = Strand<WorkBody.TimeType, WorkBody.PitchType>(name: name)

        body.parts[index].strands.append(strand)

        return strand.strandID
    }

    //
    // Applies `edit` to the strand `strandID` names, in its part.
    //
    private static func _editStrand(_ strandID: StrandID,
                                    _ edit: StrandEdit,
                                    in body: inout some Body) throws(Error) {
        let location = try strandLocation(of: strandID, in: body)

        try _apply(edit, toStrandAt: location.strand, of: &body.parts[location.part])
    }

    private static func _apply(_ edit: StrandEdit,
                               toStrandAt index: Int,
                               of part: inout Part<some TimeProtocol, some PitchProtocol>) throws(Error) {
        switch edit {
        case .giveOwnDynamicMap:
            if part.strands[index].dynamicMap == nil {
                part.strands[index].dynamicMap = part.dynamicMap
            }

        case .giveOwnInstrumentTable:
            if part.strands[index].instrumentTable == nil {
                part.strands[index].instrumentTable = part.instrumentTable
            }

        case .remove:
            guard part.strands.count > 1
            else { throw .lastStrand(part.strands[index].strandID) }

            part.strands.remove(at: index)

        case .removeOwnDynamicMap:
            part.strands[index].dynamicMap = nil

        case .removeOwnInstrumentTable:
            part.strands[index].instrumentTable = nil

        case let .rename(name):
            part.strands[index].name = name

        case let .setExtras(extras):
            part.strands[index].extras = extras

        case let .shift(newIndex):
            let strand = part.strands.remove(at: index)

            part.strands.insert(strand, at: min(max(newIndex, 0), part.strands.count))
        }
    }

    private static func _removeEmptyStrands(scope: Scope,
                                            from body: inout some Body) throws(Error) -> Set<StrandID> {
        let resolution = try scope.resolved(in: body)
        var removed: Set<StrandID> = []

        for index in body.parts.indices {
            let part = body.parts[index]
            let candidates: Set<StrandID>

            switch resolution.selections[part.partID] {
            case .whole:
                candidates = Set(part.strandIDs)

            case let .strands(strandSelections):
                candidates = Set(strandSelections.keys)

            case nil:
                continue
            }

            var kept = part.strands.filter { !candidates.contains($0.strandID) || !$0.noteTable.isEmpty }

            if kept.isEmpty, let first = part.strands.first {
                kept = [first]
            }

            removed.formUnion(Set(part.strandIDs).subtracting(kept.map(\.strandID)))
            body.parts[index].strands = kept
        }

        return removed
    }
}
