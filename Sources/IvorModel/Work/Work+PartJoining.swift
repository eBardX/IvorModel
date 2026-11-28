// © 2026 John Gary Pusey (see LICENSE.md)

internal import IvorTiming
internal import IvorTuning

extension Work {

    // MARK: Public Instance Methods

    /// Takes a strand out of its part into a new part, placed right after it.
    ///
    /// The new part copies the old part’s pedals, pan, marks, instrument table, dynamic map,
    /// interpretation rules, extras and patch tables in every realization, so nothing sounds
    /// different; the strand’s own instrument table and dynamic map, if any, become the new
    /// part’s. The strand and its notes keep their IDs; its arpeggio groups are renumbered in the
    /// new part. The new part takes the strand’s name, or the old part’s if the strand has none.
    ///
    /// - Parameter strandID:   The ID of the strand.
    ///
    /// - Returns:  The new part’s ID.
    ///
    /// - Throws:   ``Work/Error/workIsLocked`` if this work is locked;
    ///             ``Work/Error/unknownStrandID(_:)`` if no strand has the ID;
    ///             ``Work/Error/lastStrand(_:)`` if it is its part’s only strand.
    @discardableResult
    public mutating func extractStrand(_ strandID: StrandID) throws(Error) -> PartID {
        let (sourceID, newID) = try editingContent { content throws(Error) in
            try Self._extractStrand(strandID, from: &content.body)
        }

        copyPartTables(from: sourceID,
                       to: newID)

        return newID
    }

    /// Joins parts into one, as strands of the first of them in score order.
    ///
    /// The first part keeps its ID, place, name, tables, rules and extras; each other part’s
    /// strands are appended in order, keeping their IDs, and the other parts are removed. A
    /// joined part’s instrument table and dynamic map become its strands’ own tables, unless
    /// they’re the same as the first part’s. Its pedals, pan and marks are dropped when they’re
    /// the same, taken when the first part has none, and otherwise lost to the first part’s,
    /// which the result reports. In every realization, its patch table merges into the first
    /// part’s, the first part’s assignment winning for an instrument both assign. Arpeggio
    /// groups are renumbered so that rolls from different parts never meet.
    ///
    /// - Parameter partIDs:    The IDs of the parts to join. Fewer than two does nothing.
    ///
    /// - Returns:  For each joined part that lost a table to the first part’s, the kinds lost
    ///             (``TransformTargets/pan``, ``TransformTargets/mark``,
    ///             ``TransformTargets/pedal``).
    ///
    /// - Throws:   ``Work/Error/workIsLocked`` if this work is locked;
    ///             ``Work/Error/unknownPartID(_:)`` if an ID isn’t in this work.
    @discardableResult
    public mutating func joinParts(_ partIDs: Set<PartID>) throws(Error) -> [PartID: TransformTargets] {
        try ensureUnlocked()

        //
        // Assigning the content drops the patch tables of parts no longer in the work, so the
        // joined parts' tables merge first, and are put back if the join fails.
        //
        let ordered = try Self._ordered(partIDs, in: content.body)
        let savedRealizations = realizations

        if let survivorID = ordered.first {
            for joinedID in ordered.dropFirst() {
                mergePartTables(from: joinedID,
                                into: survivorID)
            }
        }

        do {
            return try editingContent { content throws(Error) in
                try Self._joinParts(ordered, in: &content.body)
            }
        } catch {
            realizations = savedRealizations

            throw error
        }
    }

    // MARK: Private Type Methods

    private static func _extractStrand(_ strandID: StrandID,
                                       from body: inout some Body) throws(Error) -> (PartID, PartID) {
        let location = try strandLocation(of: strandID, in: body)
        let part = body.parts[location.part]

        guard part.strands.count > 1
        else { throw .lastStrand(strandID) }

        let (remaining, extracted) = part.extractingStrand(at: location.strand)

        body.parts[location.part] = remaining
        body.parts.insert(extracted, at: location.part + 1)

        return (part.partID, extracted.partID)
    }

    //
    // The parts `partIDs` names, in score order. Naming a part that isn't in the work is an
    // error.
    //
    private static func _ordered(_ partIDs: Set<PartID>,
                                 in body: some Body) throws(Error) -> [PartID] {
        var indices: [Int] = []

        for partID in partIDs.sorted(by: { $0.stringValue < $1.stringValue }) {
            try indices.append(partIndex(of: partID, in: body))
        }

        return indices.sorted().map { body.parts[$0].partID }
    }

    //
    // Joins the parts `partIDs` names, in score order, into the first. Returns the kinds of
    // table each joined part lost.
    //
    private static func _joinParts(_ partIDs: [PartID],
                                   in body: inout some Body) throws(Error) -> [PartID: TransformTargets] {
        guard partIDs.count > 1
        else { return [:] }

        var indices: [Int] = []

        for partID in partIDs {
            try indices.append(partIndex(of: partID, in: body))
        }

        let survivorIndex = indices[0]
        var survivor = body.parts[survivorIndex]
        var dropped: [PartID: TransformTargets] = [:]

        for index in indices.dropFirst() {
            let part = body.parts[index]
            let result = survivor.joining(part)

            survivor = result.part

            if !result.dropped.isEmpty {
                dropped[part.partID] = result.dropped
            }
        }

        body.parts[survivorIndex] = survivor

        for index in indices.dropFirst().reversed() {
            body.parts.remove(at: index)
        }

        return dropped
    }
}
