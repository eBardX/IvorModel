// © 2026 John Gary Pusey (see LICENSE.md)

internal import XestiTools

private import IvorTiming
private import IvorTuning

extension Work {

    // MARK: Public Instance Properties

    /// The IDs of the parts in this work, in order.
    public var partIDs: [PartID] {
        content.partIDs
    }

    /// An arpeggio group no note in this work belongs to: one past the largest in use, or the
    /// first group if there are none.
    ///
    /// Tones anywhere in a work that share an attack and an ``ArpeggioGroup`` roll as one, so an
    /// importer or an edit that adds a roll gives it a group from here.
    public var unusedArpeggioGroup: ArpeggioGroup {
        let largest = content.arpeggioGroups.max()?.uintValue ?? 0

        return ArpeggioGroup(uintValue: largest + 1).require()
    }

    // MARK: Public Instance Methods

    /// Appends a new, empty part to this work.
    ///
    /// - Parameter name:   The display name of the new part. Defaults to an empty string.
    ///
    /// - Returns:  The ID of the newly added part.
    ///
    /// - Throws:   ``Work/Error/workIsLocked`` if this work is locked.
    @discardableResult
    public mutating func addPart(name: String = "") throws(Error) -> PartID {
        try ensureUnlocked()

        return Self._appendPart(named: name,
                                to: &content.body)
    }

    /// Duplicates the part with the given ID, inserting the copy immediately after
    /// the original. Every realization gives the copy the same patch table as the
    /// original. The copy’s notes get identities of their own (see ``Part/duplicated()``),
    /// and its arpeggios groups of their own (see ``unusedArpeggioGroup``), so its rolls don’t
    /// join the original’s.
    ///
    /// - Parameter partID: The ID of the part to duplicate.
    ///
    /// - Returns:  The ID of the newly added duplicate, or `nil` if no part with
    ///             `partID` was found.
    ///
    /// - Throws:   ``Work/Error/workIsLocked`` if this work is locked.
    @discardableResult
    public mutating func duplicatePart(_ partID: PartID) throws(Error) -> PartID? {
        try ensureUnlocked()

        guard let index = index(ofPartID: partID)
        else { return nil }

        let duplicateID = Self._duplicatePart(at: index,
                                              in: &content.body,
                                              firstGroup: unusedArpeggioGroup)

        copyPartTables(from: partID,
                       to: duplicateID)

        return duplicateID
    }

    /// Returns the zero-based index of the part with the given ID.
    ///
    /// - Parameter partID: The ID of the part to locate.
    ///
    /// - Returns:  The zero-based index of the part with `partID`, or `nil` if no
    ///             such part is found.
    public func index(ofPartID partID: PartID) -> Int? {
        partIDs.firstIndex(of: partID)
    }

    /// Removes the part with the given ID, along with its patch table in every
    /// realization. No-ops if no part with `partID` is found.
    ///
    /// - Parameter partID: The ID of the part to remove.
    ///
    /// - Throws:   ``Work/Error/workIsLocked`` if this work is locked.
    public mutating func removePart(_ partID: PartID) throws(Error) {
        try ensureUnlocked()

        guard let index = index(ofPartID: partID)
        else { return }

        Self._removePart(at: index,
                         from: &content.body)
    }

    /// Renames the part with the given ID. No-ops if no part with `partID` is found.
    ///
    /// - Parameter partID: The ID of the part to rename.
    /// - Parameter name:   The new display name for the part.
    ///
    /// - Throws:   ``Work/Error/workIsLocked`` if this work is locked.
    public mutating func renamePart(_ partID: PartID,
                                    to name: String) throws(Error) {
        try ensureUnlocked()

        guard let index = index(ofPartID: partID)
        else { return }

        Self._renamePart(at: index,
                         to: name,
                         in: &content.body)
    }

    /// Shifts the part with the given ID to the given index, clamping to the valid
    /// range of indices. No-ops if no part with `partID` is found.
    ///
    /// - Parameter partID: The ID of the part to shift.
    /// - Parameter index:  The zero-based index to shift the part to.
    ///
    /// - Throws:   ``Work/Error/workIsLocked`` if this work is locked.
    public mutating func shiftPart(_ partID: PartID,
                                   to index: Int) throws(Error) {
        try ensureUnlocked()

        guard let currentIndex = self.index(ofPartID: partID)
        else { return }

        Self._shiftPart(from: currentIndex,
                        to: index,
                        in: &content.body)
    }

    // MARK: Private Type Methods

    private static func _appendPart<Body: Work.Body>(named name: String,
                                                     to body: inout Body) -> PartID {
        let part = Part<Body.TimeType, Body.PitchType>(name: name)

        body.parts.append(part)

        return part.partID
    }

    private static func _clamp(_ index: Int,
                               to count: Int) -> Int {
        min(max(index, 0), count)
    }

    //
    // Inserts a copy of the part at `index` right after it, its rolls renumbered from
    // `firstGroup` so they don't join the original's, and returns the copy's ID.
    //
    private static func _duplicatePart(at index: Int,
                                       in body: inout some Work.Body,
                                       firstGroup: ArpeggioGroup) -> PartID {
        let duplicate = body.parts[index].duplicated().regroupingArpeggios(from: firstGroup)

        body.parts.insert(duplicate,
                          at: index + 1)

        return duplicate.partID
    }

    private static func _removePart(at index: Int,
                                    from body: inout some Work.Body) {
        body.parts.remove(at: index)
    }

    private static func _renamePart(at index: Int,
                                    to name: String,
                                    in body: inout some Work.Body) {
        body.parts[index].name = name
    }

    private static func _shiftPart(from currentIndex: Int,
                                   to index: Int,
                                   in body: inout some Work.Body) {
        let part = body.parts.remove(at: currentIndex)

        body.parts.insert(part,
                          at: _clamp(index, to: body.parts.count))
    }
}
