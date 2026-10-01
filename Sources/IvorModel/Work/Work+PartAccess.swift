// © 2026 John Gary Pusey (see LICENSE.md)

public import IvorTiming
public import IvorTuning

extension Work {

    // MARK: Public Instance Methods

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
    ///             found.
    @discardableResult
    public mutating func modifyPart<T: TimeProtocol, P: PitchProtocol, R>(_ partID: PartID,
                                                                          as type: Part<T, P>.Type,
                                                                          _ body: (inout Part<T, P>) -> R) throws(Error) -> R? {
        try ensureUnlocked()

        switch content {
        case let .absoluteBeat(parts, tempoMap):
            guard let modified = Self._modifying(parts, partID: partID, as: type, body)
            else { return nil }

            content = .absoluteBeat(modified.parts, tempoMap)

            return modified.result

        case let .absoluteWall(parts):
            guard let modified = Self._modifying(parts, partID: partID, as: type, body)
            else { return nil }

            content = .absoluteWall(modified.parts)

            return modified.result

        case let .keyboardBeat(parts, tempoMap):
            guard let modified = Self._modifying(parts, partID: partID, as: type, body)
            else { return nil }

            content = .keyboardBeat(modified.parts, tempoMap)

            return modified.result

        case let .keyboardWall(parts):
            guard let modified = Self._modifying(parts, partID: partID, as: type, body)
            else { return nil }

            content = .keyboardWall(modified.parts)

            return modified.result

        case let .standardBeat(parts, tempoMap):
            guard let modified = Self._modifying(parts, partID: partID, as: type, body)
            else { return nil }

            content = .standardBeat(modified.parts, tempoMap)

            return modified.result

        case let .standardWall(parts):
            guard let modified = Self._modifying(parts, partID: partID, as: type, body)
            else { return nil }

            content = .standardWall(modified.parts)

            return modified.result
        }
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

        switch content {
        case .absoluteBeat(let parts, var tempoMap):
            let result = body(&tempoMap)

            content = .absoluteBeat(parts, tempoMap)

            return result

        case .keyboardBeat(let parts, var tempoMap):
            let result = body(&tempoMap)

            content = .keyboardBeat(parts, tempoMap)

            return result

        case .standardBeat(let parts, var tempoMap):
            let result = body(&tempoMap)

            content = .standardBeat(parts, tempoMap)

            return result

        case .absoluteWall,
             .keyboardWall,
             .standardWall:
            return nil
        }
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
        switch content {
        case let .absoluteBeat(parts, _):
            Self._part(partID, in: parts, as: type)

        case let .absoluteWall(parts):
            Self._part(partID, in: parts, as: type)

        case let .keyboardBeat(parts, _):
            Self._part(partID, in: parts, as: type)

        case let .keyboardWall(parts):
            Self._part(partID, in: parts, as: type)

        case let .standardBeat(parts, _):
            Self._part(partID, in: parts, as: type)

        case let .standardWall(parts):
            Self._part(partID, in: parts, as: type)
        }
    }

    // MARK: Private Type Methods

    private static func _modifying<ST, SP, T, P, R>(_ parts: [Part<ST, SP>],
                                                    partID: PartID,
                                                    as type: Part<T, P>.Type,
                                                    _ body: (inout Part<T, P>) -> R) -> (parts: [Part<ST, SP>], result: R)? {
        guard let index = parts.firstIndex(where: { $0.partID == partID }),
              var part = parts[index] as? Part<T, P>
        else { return nil }

        let result = body(&part)

        //
        // Can't fail: `Part<T, P>` and `Part<ST, SP>` were just shown to be the same type.
        //
        guard let storedPart = part as? Part<ST, SP>
        else { return nil }

        var newParts = parts

        newParts[index] = storedPart

        return (newParts, result)
    }

    private static func _part<T, P>(_ partID: PartID,
                                    in parts: [Part<some TimeProtocol, some PitchProtocol>],
                                    as type: Part<T, P>.Type) -> Part<T, P>? {
        parts.first { $0.partID == partID } as? Part<T, P>
    }
}
