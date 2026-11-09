// © 2025–2026 John Gary Pusey (see LICENSE.md)

internal import IvorTiming
internal import IvorTuning
internal import XestiTools

extension Work {

    // MARK: Internal Type Methods

    //
    // `applyTo` also governs whether a beat-time transform carries the work's own `tempoMap`
    // along: only when it contains `.tempo`, just as each per-part map moves only when `applyTo`
    // names it. Which parts are targeted makes no difference here. The tempo map is work-wide, so
    // the app clears `.tempo` by default when the user targets only some parts.
    //
    internal static func carried(tempoMap: TempoMap,
                                 applyTo: TransformTargets,
                                 kind: TransformKind,
                                 transform: (inout TempoMap) throws(TempoMap.Error) -> Void) throws(Error) -> TempoMap {
        guard applyTo.contains(.tempo)
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
    // `rampDuration` is in beats, but `TempoMap`'s own transforms don't know about it, so
    // augment and diminish scale it here, after the map itself has been scaled: by the factor
    // for augment, by its reciprocal for diminish.
    //
    internal static func scaleRampDurations(in tempoMap: inout TempoMap,
                                            by scale: Double) {
        for entry in Array(tempoMap) {
            guard let extras = entry.extras,
                  let ramp = extras.elements.first(where: { $0.name == Extra.rampDuration.name }),
                  case let .double(duration)? = ramp.values.first
            else { continue }

            tempoMap.update(entryID: entry.entryID,
                            tempo: entry.tempo,
                            extras: extras.inserting(Extra(name: ramp.name,
                                                           values: [.double(duration * scale)])))
        }
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

        case let .instrumentTableFailure(underlying):
                .instrumentTableTransformFailure(kind: kind,
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
