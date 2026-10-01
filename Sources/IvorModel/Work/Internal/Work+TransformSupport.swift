// © 2025–2026 John Gary Pusey (see LICENSE.md)

internal import IvorTiming
internal import IvorTuning

extension Work {

    // MARK: Internal Type Aliases

    //
    // Shorthand for a per-part transform closure, used only to keep `transformed(...)`'s own
    // signature below a manageable line length.
    //
    internal typealias PartTransform<T: TimeProtocol, P: PitchProtocol> = (inout Part<T, P>) throws(Part<T, P>.Error) -> Void

    // MARK: Internal Type Methods

    //
    // `applyTo` also governs whether a beat-time transform carries the work's own `tempoMap`
    // along (§7a's Key Concepts) — an empty `applyTo` leaves it untouched, exactly as it leaves
    // every per-part map untouched. Which parts are targeted makes no difference: the tempo map
    // is work-wide.
    //
    internal static func carried(tempoMap: TempoMap,
                                 applyTo: MapTargets,
                                 kind: TransformKind,
                                 transform: (inout TempoMap) throws(TempoMap.Error) -> Void) throws(Error) -> TempoMap {
        guard !applyTo.isEmpty
        else { return tempoMap }

        var newTempoMap = tempoMap

        do {
            try transform(&newTempoMap)
        } catch {
            throw Error.tempoMapTransformFailure(kind: kind,
                                                 detail: error.message)
        }

        return newTempoMap
    }

    //
    // The parts a transform targets: those whose ID is in `partIDs`, or every part when
    // `partIDs` is `nil`. Used to resolve a default anchor or range over just the targeted parts.
    //
    internal static func selected<T: TimeProtocol, P: PitchProtocol>(_ parts: [Part<T, P>],
                                                                     partIDs: Set<PartID>?) -> [Part<T, P>] {
        guard let partIDs
        else { return parts }

        return parts.filter { partIDs.contains($0.partID) }
    }

    //
    // Applies `transform` to every part whose ID is in `partIDs` — every part when `partIDs` is
    // `nil` — leaving every other part untouched and in place. IDs naming no part are ignored.
    // All-or-nothing: a thrown error abandons the local `result` array before it is ever
    // assigned to `content`.
    //
    internal static func transformed<T: TimeProtocol, P: PitchProtocol>(parts: [Part<T, P>],
                                                                        partIDs: Set<PartID>?,
                                                                        kind: TransformKind,
                                                                        transform: PartTransform<T, P>) throws(Error) -> [Part<T, P>] {
        var result = parts

        for index in result.indices where partIDs?.contains(result[index].partID) ?? true {
            do {
                try transform(&result[index])
            } catch {
                throw Self.wrapped(error: error,
                                   kind: kind,
                                   partID: result[index].partID)
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
    internal static func wrapped(error: Part<some TimeProtocol, some PitchProtocol>.Error,
                                 kind: TransformKind,
                                 partID: PartID) -> Error {
        switch error {
        case let .dynamicMapFailure(underlying):
                .dynamicMapTransformFailure(kind: kind,
                                            partID: partID,
                                            detail: underlying.message)

        case let .instrumentMapFailure(underlying):
                .instrumentMapTransformFailure(kind: kind,
                                               partID: partID,
                                               detail: underlying.message)

        case let .noteTableFailure(underlying):
                .transformFailure(kind: kind,
                                  partID: partID,
                                  detail: underlying.message)

        case let .panMapFailure(underlying):
                .panMapTransformFailure(kind: kind,
                                        partID: partID,
                                        detail: underlying.message)
        }
    }
}
