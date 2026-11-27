// © 2026 John Gary Pusey (see LICENSE.md)

public import IvorTiming
public import IvorTuning

extension Work {

    // MARK: Public Instance Methods

    /// Returns the key table a strand’s notes follow, or `nil` for wall-time content, which has no
    /// key table.
    ///
    /// Every strand follows the work’s key table today. The strand is asked for so that callers
    /// need no change if strands come to have keys of their own (polytonality).
    ///
    /// - Parameter strandID:   The ID of a strand of this work.
    ///
    /// - Returns:  The key table the strand’s notes follow.
    public func keyTable(for strandID: StrandID) -> KeyTable? {
        keyTable
    }

    /// Edits the key table of this work in place.
    ///
    /// - Parameter body:   A closure that edits the key table in place, and whose result
    ///                     is returned.
    ///
    /// - Returns:  The result of `body`, or `nil` (without calling `body`) if this work has
    ///             wall-time content, which has no key table.
    ///
    /// - Throws:   ``Work/Error/workIsLocked`` if this work is locked, whatever its time basis.
    @discardableResult
    public mutating func modifyKeyTable<R>(_ body: (inout KeyTable) -> R) throws(Error) -> R? {
        try ensureUnlocked()

        guard var beatBody = content.body as? any BeatTimeBody
        else { return nil }

        let result = body(&beatBody.keyTable)

        content.body = beatBody

        return result
    }

    /// Edits the meter table of this work in place.
    ///
    /// - Parameter body:   A closure that edits the meter table in place, and whose result is
    ///                     returned.
    ///
    /// - Returns:  The result of `body`, or `nil` (without calling `body`) if this work has
    ///             wall-time content, which has no meter table.
    ///
    /// - Throws:   ``Work/Error/workIsLocked`` if this work is locked, whatever its time basis.
    @discardableResult
    public mutating func modifyMeterTable<R>(_ body: (inout MeterTable) -> R) throws(Error) -> R? {
        try ensureUnlocked()

        guard var beatBody = content.body as? any BeatTimeBody
        else { return nil }

        let result = body(&beatBody.meterTable)

        content.body = beatBody

        return result
    }

    /// Edits one part of this work in place.
    ///
    /// The caller names the part’s concrete type, which must match this work’s time basis and
    /// pitch notation — for example, `Part<BeatTime, Pitch>.self` for standard-beat content.
    ///
    /// - Parameter partID: The ID of the part to edit.
    /// - Parameter type:   The concrete type of the part.
    /// - Parameter body:   A closure that edits the part in place, and whose result is returned.
    ///
    /// - Returns:  The result of `body`, or `nil` (without calling `body`) if no part with
    ///             `partID` is found or this work’s parts aren’t of type `type`.
    ///
    /// - Throws:   ``Work/Error/workIsLocked`` if this work is locked, whether or not the part is
    ///             found; ``Work/Error/duplicateNoteID(_:)`` if `body` leaves two notes of the
    ///             work sharing a note ID where none did before, in which case the work is left
    ///             as it was.
    @discardableResult
    public mutating func modifyPart<T: TimeProtocol, P: PitchProtocol, R>(_ partID: PartID,
                                                                          as type: Part<T, P>.Type,
                                                                          _ body: (inout Part<T, P>) -> R) throws(Error) -> R? {
        try ensureUnlocked()

        let original = content
        let keptRules = original.invariantError == nil

        guard let result = _modifyPart(partID, as: type, body)
        else { return nil }

        //
        // The body can edit the part freely, so it can break a rule the work keeps (two notes
        // sharing an identity, say). Then the edit is undone, so the work is as it was. Only a
        // rule the edit breaks counts: `Work.init` doesn't check its content, so a work can
        // already break one, and editing it (as rendering does) mustn't then fail.
        //
        if keptRules,
           let error = content.invariantError {
            content = original

            throw error
        }

        return result
    }

    /// Edits one strand of this work in place, whichever part it belongs to.
    ///
    /// The caller names the strand’s concrete type, which must match this work’s time basis and
    /// pitch notation — for example, `Strand<BeatTime, Pitch>.self` for standard-beat content.
    /// The strand keeps its ``StrandID``, whatever `body` does.
    ///
    /// - Parameter strandID:   The ID of the strand to edit.
    /// - Parameter type:       The concrete type of the strand.
    /// - Parameter body:       A closure that edits the strand in place, and whose result is
    ///                         returned.
    ///
    /// - Returns:  The result of `body`, or `nil` (without calling `body`) if no strand with
    ///             `strandID` is found or this work’s strands aren’t of type `type`.
    ///
    /// - Throws:   ``Work/Error/workIsLocked`` if this work is locked, whether or not the strand
    ///             is found; ``Work/Error/duplicateNoteID(_:)`` if `body` leaves two notes of the
    ///             work sharing a note ID where none did before, in which case the work is left
    ///             as it was.
    @discardableResult
    public mutating func modifyStrand<T: TimeProtocol, P: PitchProtocol, R>(_ strandID: StrandID,
                                                                            as type: Strand<T, P>.Type,
                                                                            _ body: (inout Strand<T, P>) -> R) throws(Error) -> R? {
        try ensureUnlocked()

        let original = content
        let keptRules = original.invariantError == nil

        guard let result = Self._modifyingStrand(strandID,
                                                 in: &content.body,
                                                 as: type,
                                                 body)
        else { return nil }

        //
        // As in `modifyPart`: an edit that breaks a rule the work kept is undone.
        //
        if keptRules,
           let error = content.invariantError {
            content = original

            throw error
        }

        return result
    }

    /// Edits the tempo map of this work in place.
    ///
    /// - Parameter body:   A closure that edits the tempo map in place, and whose result is
    ///                     returned.
    ///
    /// - Returns:  The result of `body`, or `nil` (without calling `body`) if this work has
    ///             wall-time content, which has no tempo map.
    ///
    /// - Throws:   ``Work/Error/workIsLocked`` if this work is locked, whatever its time basis.
    @discardableResult
    public mutating func modifyTempoMap<R>(_ body: (inout TempoMap) -> R) throws(Error) -> R? {
        try ensureUnlocked()

        guard var beatBody = content.body as? any BeatTimeBody
        else { return nil }

        let result = body(&beatBody.tempoMap)

        content.body = beatBody

        return result
    }

    /// Returns one part of this work.
    ///
    /// The caller names the part’s concrete type, which must match this work’s time basis and
    /// pitch notation — for example, `Part<BeatTime, Pitch>.self` for standard-beat content.
    ///
    /// - Parameter partID: The ID of the part to return.
    /// - Parameter type:   The concrete type of the part.
    ///
    /// - Returns:  The part with `partID`, or `nil` if no such part is found or this work’s parts
    ///             aren’t of type `type`.
    public func part<T: TimeProtocol, P: PitchProtocol>(_ partID: PartID,
                                                        as type: Part<T, P>.Type) -> Part<T, P>? {
        Self._part(partID,
                   in: content.body,
                   as: type)
    }

    /// Returns one strand of this work, whichever part it belongs to.
    ///
    /// The caller names the strand’s concrete type, which must match this work’s time basis and
    /// pitch notation — for example, `Strand<BeatTime, Pitch>.self` for standard-beat content.
    ///
    /// - Parameter strandID:   The ID of the strand to return.
    /// - Parameter type:       The concrete type of the strand.
    ///
    /// - Returns:  The strand with `strandID`, or `nil` if no such strand is found or this work’s
    ///             strands aren’t of type `type`.
    public func strand<T: TimeProtocol, P: PitchProtocol>(_ strandID: StrandID,
                                                          as type: Strand<T, P>.Type) -> Strand<T, P>? {
        Self._strand(strandID,
                     in: content.body,
                     as: type)
    }

    // MARK: Private Type Methods

    //
    // Runs `body` on the part with `partID`, if `body`'s type of part is this body's, and writes
    // the edited part back.
    //
    private static func _modifying<WorkBody: Work.Body, T, P, R>(_ partID: PartID,
                                                                 in workBody: inout WorkBody,
                                                                 as type: Part<T, P>.Type,
                                                                 _ body: (inout Part<T, P>) -> R) -> R? {
        guard let index = workBody.parts.firstIndex(where: { $0.partID == partID }),
              var part = workBody.parts[index] as? Part<T, P>
        else { return nil }

        let result = body(&part)

        //
        // Can't fail: the part was just shown to be of the body's own type.
        //
        guard let storedPart = part as? Part<WorkBody.TimeType, WorkBody.PitchType>
        else { return nil }

        workBody.parts[index] = storedPart

        return result
    }

    //
    // Runs `body` on the strand with `strandID`, in whichever part holds it, if `body`'s type of
    // strand is this body's, and writes the edited strand back.
    //
    private static func _modifyingStrand<WorkBody: Work.Body, T, P, R>(_ strandID: StrandID,
                                                                       in workBody: inout WorkBody,
                                                                       as type: Strand<T, P>.Type,
                                                                       _ body: (inout Strand<T, P>) -> R) -> R? {
        guard let partIndex = workBody.parts.firstIndex(where: { $0.index(ofStrandID: strandID) != nil }),
              let strandIndex = workBody.parts[partIndex].index(ofStrandID: strandID),
              var strand = workBody.parts[partIndex].strands[strandIndex] as? Strand<T, P>
        else { return nil }

        let result = body(&strand)

        //
        // Can't fail: the strand was just shown to be of the body's own type.
        //
        guard let storedStrand = strand as? Strand<WorkBody.TimeType, WorkBody.PitchType>
        else { return nil }

        workBody.parts[partIndex].strands[strandIndex] = storedStrand

        return result
    }

    private static func _part<T, P>(_ partID: PartID,
                                    in workBody: some Work.Body,
                                    as type: Part<T, P>.Type) -> Part<T, P>? {
        workBody.parts.first { $0.partID == partID } as? Part<T, P>
    }

    private static func _strand<T, P>(_ strandID: StrandID,
                                      in workBody: some Work.Body,
                                      as type: Strand<T, P>.Type) -> Strand<T, P>? {
        for part in workBody.parts {
            if let strand = part.strand(strandID) {
                return strand as? Strand<T, P>
            }
        }

        return nil
    }

    // MARK: Private Instance Methods

    //
    // `modifyPart`'s edit, before its check of the work's rules.
    //
    private mutating func _modifyPart<T: TimeProtocol, P: PitchProtocol, R>(_ partID: PartID,
                                                                            as type: Part<T, P>.Type,
                                                                            _ body: (inout Part<T, P>) -> R) -> R? {
        Self._modifying(partID,
                        in: &content.body,
                        as: type,
                        body)
    }
}
