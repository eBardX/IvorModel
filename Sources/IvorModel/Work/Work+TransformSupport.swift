// © 2025–2026 John Gary Pusey (see LICENSE.md)

internal import IvorTiming
internal import IvorTuning

extension Work {

    // MARK: Internal Type Aliases

    //
    // Shorthand for a per-part transform closure, used only to keep the `transformed(...)`
    // overloads' own signatures below a manageable line length.
    //
    internal typealias PartTransform<T: TimeProtocol, P: PitchProtocol> = (inout Part<T, P>) throws(Part<T, P>.Error) -> Void

    // MARK: Internal Type Methods

    //
    // `applyTo` also governs whether a whole-work transform carries the work's own `tempoMap`
    // along (§7a's Key Concepts) — an empty `applyTo` leaves it untouched, exactly as it leaves
    // every per-part map untouched.
    //
    internal static func carriedTempoMap(_ tempoMap: TempoMap,
                                         applyTo: MapTargets,
                                         kind: TransformKind,
                                         _ transform: (inout TempoMap) throws(TempoMap.Error) -> Void) throws(Error) -> TempoMap {
        guard !applyTo.isEmpty
        else { return tempoMap }

        var newTempoMap = tempoMap

        do {
            try transform(&newTempoMap)
        } catch {
            throw Error.tempoMapTransformFailure(kind, detail: error.message)
        }

        return newTempoMap
    }

    //
    // Applies `transform` to every part, building the result into a local array and only
    // returning it once every part has succeeded — all-or-nothing, since a thrown error abandons
    // the whole array rather than returning a partially transformed one.
    //
    internal static func transformed<T: TimeProtocol, P: PitchProtocol>(_ parts: [Part<T, P>],
                                                                        kind: TransformKind,
                                                                        _ transform: PartTransform<T, P>) throws(Error) -> [Part<T, P>] {
        var result: [Part<T, P>] = []

        result.reserveCapacity(parts.count)

        for part in parts {
            var newPart = part

            do {
                try transform(&newPart)
            } catch {
                throw Self.wrapped(error, kind: kind, partID: part.partID)
            }

            result.append(newPart)
        }

        return result
    }

    //
    // Applies `transform` to just the part with `partID`, leaving every other part untouched and
    // in place. Returns `parts` unchanged if no part with `partID` is found, matching the
    // no-op-if-not-found convention `Work+PartEditing.swift`'s methods already follow.
    //
    internal static func transformed<T: TimeProtocol, P: PitchProtocol>(_ parts: [Part<T, P>],
                                                                        partID: PartID,
                                                                        kind: TransformKind,
                                                                        _ transform: PartTransform<T, P>) throws(Error) -> [Part<T, P>] {
        guard let index = parts.firstIndex(where: { $0.partID == partID })
        else { return parts }

        var result = parts

        do {
            try transform(&result[index])
        } catch {
            throw Self.wrapped(error, kind: kind, partID: partID)
        }

        return result
    }

    //
    // Applies `transform` to every part whose ID is in `partIDs`, leaving every other part
    // untouched and in place. All-or-nothing across just the targeted subset: a thrown error
    // abandons the local `result` array before it is ever assigned to `content`.
    //
    internal static func transformed<T: TimeProtocol, P: PitchProtocol>(_ parts: [Part<T, P>],
                                                                        partIDs: Set<PartID>,
                                                                        kind: TransformKind,
                                                                        _ transform: PartTransform<T, P>) throws(Error) -> [Part<T, P>] {
        var result = parts

        for index in result.indices where partIDs.contains(result[index].partID) {
            do {
                try transform(&result[index])
            } catch {
                throw Self.wrapped(error, kind: kind, partID: result[index].partID)
            }
        }

        return result
    }

    //
    // Translates a `Part.Error` (generic over `TimeType`/`PitchType`) into the non-generic
    // `Work.Error`, naming which part and sub-structure actually failed. `Part.Error` has no
    // `Work`-facing typed payload to carry forward, so the wrapped error's own `.message`
    // becomes `detail`.
    //
    internal static func wrapped(_ error: Part<some TimeProtocol, some PitchProtocol>.Error,
                                 kind: TransformKind,
                                 partID: PartID) -> Error {
        switch error {
        case let .dynamicMapFailure(underlying):
            .dynamicMapTransformFailure(kind, partID: partID, detail: underlying.message)

        case let .instrumentMapFailure(underlying):
            .instrumentMapTransformFailure(kind, partID: partID, detail: underlying.message)

        case let .noteTableFailure(underlying):
            .transformFailure(kind, partID: partID, detail: underlying.message)

        case let .panMapFailure(underlying):
            .panMapTransformFailure(kind, partID: partID, detail: underlying.message)
        }
    }
}
