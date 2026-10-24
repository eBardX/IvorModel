// © 2026 John Gary Pusey (see LICENSE.md)

extension Work {

    // MARK: Public Instance Methods

    /// Edits the realization with the given ID in place.
    ///
    /// Permitted even on a locked work: realizations aren’t part of the music. Afterward, any
    /// part table for a part not in this work is dropped.
    ///
    /// - Parameter realizationID:  The ID of the realization to edit.
    /// - Parameter body:           A closure that edits the realization it is passed.
    ///
    /// - Returns:  The value returned by `body`, or `nil` if no realization with
    ///             `realizationID` is found.
    @discardableResult
    public mutating func modifyRealization<R>(_ realizationID: RealizationID,
                                              _ body: (inout Realization) -> R) -> R? {
        guard let index = realizations.firstIndex(where: { $0.realizationID == realizationID })
        else { return nil }

        let result = body(&realizations[index])

        removeOrphanedPartTables()

        return result
    }

    /// Returns the realization with the given ID.
    ///
    /// - Parameter realizationID:  The ID of the realization to return.
    ///
    /// - Returns:  The realization with `realizationID`, or `nil` if no such realization is
    ///             found.
    public func realization(_ realizationID: RealizationID) -> Realization? {
        realizations.first { $0.realizationID == realizationID }
    }

    /// Replaces the realizations of this work — to add, remove, reorder, or edit several at once.
    ///
    /// Permitted even on a locked work: realizations aren’t part of the music. Any part table for
    /// a part not in this work is dropped.
    ///
    /// - Parameter realizations:   The new realizations, in order.
    ///
    /// - Throws:   ``Work/Error/noRealizations`` if `realizations` is empty;
    ///             ``Work/Error/duplicateRealizationID(_:)`` if two of them share a realization ID.
    public mutating func replaceRealizations(with realizations: [Realization]) throws(Error) {
        if let error = Self.firstRealizationError(in: realizations) {
            throw error
        }

        self.realizations = realizations

        removeOrphanedPartTables()
    }

    // MARK: Internal Type Methods

    internal static func firstRealizationError(in realizations: [Realization]) -> Error? {
        guard !realizations.isEmpty
        else { return .noRealizations }

        var seen: Set<RealizationID> = []

        for realization in realizations where !seen.insert(realization.realizationID).inserted {
            return .duplicateRealizationID(realization.realizationID)
        }

        return nil
    }

    // MARK: Internal Instance Methods

    internal mutating func copyPartTables(from sourceID: PartID,
                                          to destinationID: PartID) {
        for index in realizations.indices {
            realizations[index].copyPartTable(from: sourceID,
                                              to: destinationID)
        }
    }

    internal mutating func removeOrphanedPartTables() {
        let partIDs = Set(partIDs)

        for index in realizations.indices {
            realizations[index].removePartTables(notIn: partIDs)
        }
    }
}
