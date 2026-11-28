// © 2025–2026 John Gary Pusey (see LICENSE.md)

internal import IvorTiming
internal import IvorTuning
internal import XestiNumbers
internal import XestiTools

extension Work {

    // MARK: Public Instance Methods

    /// Quantizes note attack and release times across the notes of this beat-time work that
    /// `scope` takes, along with the tables it carries.
    ///
    /// A table is carried only when `scope` covers everything that shares it (see
    /// ``Work/Scope``), and `applyTo` names its kind; `alsoCarry` opts shared tables in anyway.
    /// The work’s tempo map needs the whole work. The meter table and key table are never
    /// quantized, whatever `applyTo` holds: their entries mark notation, not sound.
    ///
    /// - Parameter factors:    An array of positive integer subdivision factors.
    /// - Parameter applyTo:    The kinds of table to quantize along with the notes. Defaults to
    ///                         ``TransformTargets/all``.
    /// - Parameter alsoCarry:  The kinds of shared table to carry even though `scope` doesn’t
    ///                         cover everything that shares them. Defaults to none.
    /// - Parameter scope:      The notes to quantize. Defaults to ``Work/Scope/all``.
    ///
    /// - Throws:   ``Work/Error/workIsLocked`` if this work is locked;
    ///             ``Work/Error/timeBasisMismatch(expected:)`` if this work does not use beat
    ///             time; ``Work/Error/emptyQuantizationFactors`` /
    ///             ``Work/Error/invalidQuantizationFactor(_:)`` if `factors` is invalid; an
    ///             unknown-ID case if `scope` names something not in this work.
    public mutating func quantize(to factors: [Int],
                                  applyTo: TransformTargets = .all,
                                  alsoCarry: TransformTargets = [],
                                  scope: Scope = .all) throws(Error) {
        try ensureUnlocked()

        let quantizer = try Self._quantizer(factors)

        guard var body = content.body as? any BeatTimeBody
        else { throw Error.timeBasisMismatch(expected: .beat) }

        try Self._quantize(&body,
                           using: quantizer,
                           applyTo: applyTo,
                           alsoCarry: alsoCarry,
                           scope: scope)

        content.body = body
    }

    // MARK: Private Type Methods

    private static func _quantize<WorkBody: BeatTimeBody>(_ body: inout WorkBody,
                                                          using quantizer: BeatQuantizer,
                                                          applyTo: TransformTargets,
                                                          alsoCarry: TransformTargets,
                                                          scope: Scope) throws(Error) {
        typealias PartType = Part<BeatTime, WorkBody.PitchType>

        let resolution = try scope.resolved(in: body)

        try transform(&body,
                      resolution: resolution,
                      kind: .quantize) { (part: inout PartType, selection) throws(PartType.Error) in
            part.quantize(to: quantizer,
                          selection: selection,
                          applyTo: applyTo,
                          alsoCarry: alsoCarry)
        }

        body.tempoMap = _quantized(tempoMap: body.tempoMap,
                                   using: quantizer,
                                   applyTo: resolution.workTargets(applyTo: applyTo,
                                                                   alsoCarry: alsoCarry))
    }

    //
    // The tempo map quantized, when `applyTo` (the work targets the scope carries) contains
    // `.tempo`. Quantizing can't fail, so this needn't go through
    // `carried(tempoMap:applyTo:kind:transform:)`.
    //
    private static func _quantized(tempoMap: TempoMap,
                                   using quantizer: BeatQuantizer,
                                   applyTo: TransformTargets) -> TempoMap {
        guard applyTo.contains(.tempo)
        else { return tempoMap }

        var newTempoMap = tempoMap

        newTempoMap.quantize(using: quantizer)

        _snapRampDurations(in: &newTempoMap,
                           quantizedFrom: tempoMap,
                           using: quantizer)

        return newTempoMap
    }

    private static func _quantizer(_ factors: [Int]) throws(Error) -> BeatQuantizer {
        do {
            return try BeatQuantizer(factors: factors)
        } catch {
            switch error {
            case .emptyFactors:
                throw Error.emptyQuantizationFactors

            case let .invalidFactor(factor):
                throw Error.invalidQuantizationFactor(factor)
            }
        }
    }

    //
    // The JohnnySonic `rampDuration` extra runs in whole notes from its entry, and the exporter
    // trusts it over the map. Quantizing snaps the entry but not the duration, so snap the
    // ramp's end too, as a note's release is snapped with its attack, and set the duration to
    // the distance between the snapped ends.
    //
    private static func _snapRampDurations(in tempoMap: inout TempoMap,
                                           quantizedFrom original: TempoMap,
                                           using quantizer: BeatQuantizer) {
        for entry in original {
            guard let ramp = entry.extras?.elements.first(where: { $0.name == Extra.rampDuration.name }),
                  case let .double(duration)? = ramp.values.first,
                  let end = BeatTime(numberValue: entry.beatTime.numberValue + Number(duration)),
                  let newEntry = tempoMap.first(where: { $0.entryID == entry.entryID }),
                  let newExtras = newEntry.extras
            else { continue }

            let newDuration = quantizer.quantize(end).numberValue - newEntry.beatTime.numberValue

            tempoMap.update(entryID: newEntry.entryID,
                            tempo: newEntry.tempo,
                            extras: newExtras.inserting(Extra(name: ramp.name,
                                                              values: [.double(newDuration.doubleValue)])))
        }
    }
}
