// © 2025–2026 John Gary Pusey (see LICENSE.md)

internal import IvorTiming
internal import IvorTuning

extension Work {

    // MARK: Public Instance Methods

    /// Quantizes note attack/release times across the beat-time parts in this work that `partIDs`
    /// names, along with any parameter maps selected by `applyTo` and, when `applyTo` contains
    /// ``MapTargets/tempo``, the work’s own tempo map. The tempo map is work-wide, so it is carried
    /// along whichever parts are targeted.
    ///
    /// - Parameter factors:   An array of positive integer subdivision factors.
    /// - Parameter noteIDs:   The identities of the notes to quantize, or `nil` to quantize every
    ///                        note in the targeted parts.
    /// - Parameter applyTo:   The parameter maps (and tempo map) to quantize along with each part’s
    ///                        note table. Defaults to ``MapTargets/all``.
    /// - Parameter partIDs:   The IDs of the parts to transform, or `nil` (the default) for every
    ///                        part. IDs naming no part are ignored.
    ///
    /// - Throws:   ``Work/Error/workIsLocked`` if this work is locked;
    ///             ``Work/Error/timeBasisMismatch(expected:)`` if this work does not use beat
    ///             time; ``Work/Error/emptyQuantizationFactors`` /
    ///             ``Work/Error/invalidQuantizationFactor(_:)`` if `factors` is invalid;
    ///             otherwise a transform-failure case naming the part.
    public mutating func quantize(to factors: [Int],
                                  noteIDs: Set<NoteID>? = nil,
                                  applyTo: MapTargets = .all,
                                  partIDs: Set<PartID>? = nil) throws(Error) {
        try ensureUnlocked()

        let quantizer = try Self._quantizer(factors)

        switch content {
        case let .absoluteBeat(parts, tempoMap):
            typealias PartType = Part<BeatTime, Frequency>

            let newParts = try Self.transformed(parts: parts,
                                                partIDs: partIDs,
                                                kind: .quantize) { (part: inout PartType) throws(PartType.Error) in
                part.quantize(to: quantizer,
                              noteIDs: noteIDs,
                              applyTo: applyTo)
            }

            content = .absoluteBeat(newParts,
                                    Self._quantized(tempoMap: tempoMap,
                                                    using: quantizer,
                                                    applyTo: applyTo))

        case let .keyboardBeat(parts, tempoMap):
            typealias PartType = Part<BeatTime, NoteNumber>

            let newParts = try Self.transformed(parts: parts,
                                                partIDs: partIDs,
                                                kind: .quantize) { (part: inout PartType) throws(PartType.Error) in
                part.quantize(to: quantizer,
                              noteIDs: noteIDs,
                              applyTo: applyTo)
            }

            content = .keyboardBeat(newParts,
                                    Self._quantized(tempoMap: tempoMap,
                                                    using: quantizer,
                                                    applyTo: applyTo))

        case let .standardBeat(parts, tempoMap):
            typealias PartType = Part<BeatTime, Pitch>

            let newParts = try Self.transformed(parts: parts,
                                                partIDs: partIDs,
                                                kind: .quantize) { (part: inout PartType) throws(PartType.Error) in
                part.quantize(to: quantizer,
                              noteIDs: noteIDs,
                              applyTo: applyTo)
            }

            content = .standardBeat(newParts,
                                    Self._quantized(tempoMap: tempoMap,
                                                    using: quantizer,
                                                    applyTo: applyTo))

        default:
            throw Error.timeBasisMismatch(expected: .beat)
        }
    }

    // MARK: Private Type Methods

    //
    // Unlike `carried(tempoMap:applyTo:kind:transform:)` (used by augment/diminish/move/reverse),
    // this gates on the `.tempo` bit specifically rather than on `applyTo` merely being
    // non-empty: quantize's per-part maps are each opted into individually (see
    // `Part.quantize(to:noteIDs:applyTo:)`), and the tempo map — timing information in its own
    // right, not a parallel automation lane — follows the same opt-in-by-bit rule rather than
    // riding along with any other map selection.
    //
    private static func _quantized(tempoMap: TempoMap,
                                   using quantizer: BeatQuantizer,
                                   applyTo: MapTargets) -> TempoMap {
        guard applyTo.contains(.tempo)
        else { return tempoMap }

        var newTempoMap = tempoMap

        newTempoMap.quantize(using: quantizer)

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
}
