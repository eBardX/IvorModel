// © 2025–2026 John Gary Pusey (see LICENSE.md)

internal import IvorTiming
internal import IvorTuning
internal import XestiTools

extension Work {

    // MARK: Internal Type Methods

    //
    // As for the tempo map below, but for the work's own `keyTable`, governed by
    // `.key`.
    //
    internal static func carried(keyTable: KeyTable,
                                 applyTo: TransformTargets,
                                 kind: TransformKind,
                                 transform: (inout KeyTable) throws(KeyTable.Error) -> Void) throws(Error) -> KeyTable {
        guard applyTo.contains(.key)
        else { return keyTable }

        var newKeyTable = keyTable

        do {
            try transform(&newKeyTable)
        } catch {
            throw Error.keyTableTransformFailure(kind: kind,
                                                 detail: error.message)
        }

        return newKeyTable
    }

    //
    // As for the tempo map below, but for the work's own `meterTable`, governed by `.meter`.
    //
    internal static func carried(meterTable: MeterTable,
                                 applyTo: TransformTargets,
                                 kind: TransformKind,
                                 transform: (inout MeterTable) throws(MeterTable.Error) -> Void) throws(Error) -> MeterTable {
        guard applyTo.contains(.meter)
        else { return meterTable }

        var newMeterTable = meterTable

        do {
            try transform(&newMeterTable)
        } catch {
            throw Error.meterTableTransformFailure(kind: kind,
                                                   detail: error.message)
        }

        return newMeterTable
    }

    //
    // Whether a beat-time transform carries the work's own `tempoMap` along: only when
    // `applyTo` contains `.tempo`. Callers pass the work targets their resolved scope carries
    // (`ResolvedScope.workTargets(applyTo:alsoCarry:)`), so the tempo map moves only with the
    // whole work, or when the caller opts it in.
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
    // `rampDuration` is in whole notes, but `TempoMap`'s own transforms don't know about it, so
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
    // The pitch range of the notes `resolution` takes, across every part it touches: what a
    // pitch transform's default range resolves to.
    //
    internal static func selectedPitchRange<WorkBody: Work.Body>(of body: WorkBody,
                                                                 resolution: ResolvedScope) -> ClosedRange<WorkBody.PitchType>? {
        let ranges = body.parts.compactMap { part in
            resolution.selections[part.partID].flatMap { part.selectedPitchRange(for: $0) }
        }

        guard let lowerBound = ranges.map(\.lowerBound).min(),
              let upperBound = ranges.map(\.upperBound).max()
        else { return nil }

        return lowerBound...upperBound
    }

    //
    // Applies `transform` to every part `resolution` touches, with what it takes of the part,
    // leaving every other part untouched and in place. All or nothing: a thrown error abandons
    // the local copy before it is ever assigned to `body`.
    //
    internal static func transform<WorkBody: Work.Body>(_ body: inout WorkBody,
                                                        resolution: ResolvedScope,
                                                        kind: TransformKind,
                                                        _ transform: PartTransform<WorkBody.TimeType, WorkBody.PitchType>) throws(Error) {
        var parts = body.parts

        for index in parts.indices {
            guard let selection = resolution.selections[parts[index].partID]
            else { continue }

            do {
                try transform(&parts[index], selection)
            } catch {
                throw Self.wrapped(error: error,
                                   kind: kind,
                                   partID: parts[index].partID)
            }
        }

        body.parts = parts
    }

    //
    // The one range a time transform's default resolves from, so everything that moves scales
    // or mirrors about the same point: each touched part's own range (its chosen notes and the
    // tables it carries whole; see `Part.transformTimeRange(_:)`), joined.
    //
    internal static func partsTimeRange<WorkBody: Work.Body>(of body: WorkBody,
                                                             resolution: ResolvedScope,
                                                             applyTo: TransformTargets,
                                                             alsoCarry: TransformTargets) -> ClosedRange<WorkBody.TimeType>? {
        body.parts.reduce(nil) { acc, part in
            guard let selection = resolution.selections[part.partID],
                  let partRange = part.transformTimeRange(part.carryPlan(for: selection,
                                                                         applyTo: applyTo,
                                                                         alsoCarry: alsoCarry))
            else { return acc }

            return Self._widened(acc, by: partRange)
        }
    }

    //
    // As above, for beat time, widened by the tempo map's, meter table's and key table's
    // entries when the transform carries them.
    //
    internal static func transformTimeRange(of body: some Work.BeatTimeBody,
                                            resolution: ResolvedScope,
                                            applyTo: TransformTargets,
                                            alsoCarry: TransformTargets) -> ClosedRange<BeatTime>? {
        let workTargets = resolution.workTargets(applyTo: applyTo,
                                                 alsoCarry: alsoCarry)
        var range = partsTimeRange(of: body,
                                   resolution: resolution,
                                   applyTo: applyTo,
                                   alsoCarry: alsoCarry)
        let tables: [(TransformTargets, [BeatTime])] = [(.tempo, body.tempoMap.map(\.beatTime)),
                                                        (.meter, body.meterTable.map(\.beatTime)),
                                                        (.key, body.keyTable.map(\.beatTime))]

        for (kind, times) in tables where workTargets.contains(kind) {
            if let first = times.min(),
               let last = times.max() {
                range = Self._widened(range, by: first...last)
            }
        }

        return range
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

        case let .markTableFailure(underlying):
                .markTableTransformFailure(kind: kind,
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

        case let .pedalTableFailure(pedal, underlying):
                .pedalTableTransformFailure(kind: kind,
                                            partID: partID,
                                            pedal: pedal,
                                            detail: underlying.message)
        }
    }

    // MARK: Private Type Methods

    private static func _widened<TimeType: TimeProtocol>(_ range: ClosedRange<TimeType>?,
                                                         by other: ClosedRange<TimeType>) -> ClosedRange<TimeType> {
        guard let range
        else { return other }

        return min(range.lowerBound, other.lowerBound)...max(range.upperBound, other.upperBound)
    }
}
