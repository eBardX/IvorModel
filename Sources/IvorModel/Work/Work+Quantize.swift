// © 2025–2026 John Gary Pusey (see LICENSE.md)

internal import IvorTiming
internal import IvorTuning

extension Work {

    // MARK: Public Instance Methods

    /// Quantizes note attack/release times for a single beat-time part in this work, along with
    /// any parameter maps selected by `applyTo`. No-ops if no part with `partID` is found.
    ///
    /// - Parameter partID:    The ID of the part to quantize.
    /// - Parameter factors:   An array of positive integer subdivision factors.
    /// - Parameter noteIDs:   The identities of the notes to quantize, or `nil` to quantize
    ///                        every note in the part.
    /// - Parameter applyTo:   The parameter maps to quantize along with the part’s note table.
    ///                        Defaults to ``MapTargets/all``.
    ///
    /// - Throws:   ``Work/Error/timeBasisMismatch(expected:)`` if this work does not use beat
    ///             time; ``Work/Error/emptyQuantizationFactors`` /
    ///             ``Work/Error/invalidQuantizationFactor(_:)`` if `factors` is invalid;
    ///             otherwise a transform-failure case naming the part.
    public mutating func quantize(_ partID: PartID,
                                  to factors: [Int],
                                  noteIDs: Set<NoteID>? = nil,
                                  applyTo: MapTargets = .all) throws(Error) {
        let quantizer = try Self._quantizer(factors)

        switch content {
        case let .absoluteBeat(parts, tempoMap):
            typealias PartType = Part<BeatTime, Frequency>

            content = try .absoluteBeat(Self.transformed(parts: parts,
                                                         partID: partID,
                                                         kind: .quantize) { (part: inout PartType) throws(PartType.Error) in
                part.quantize(to: quantizer,
                              noteIDs: noteIDs,
                              applyTo: applyTo)
            }, tempoMap)

        case let .keyboardBeat(parts, tempoMap):
            typealias PartType = Part<BeatTime, NoteNumber>

            content = try .keyboardBeat(Self.transformed(parts: parts,
                                                         partID: partID,
                                                         kind: .quantize) { (part: inout PartType) throws(PartType.Error) in
                part.quantize(to: quantizer,
                              noteIDs: noteIDs,
                              applyTo: applyTo)
            }, tempoMap)

        case let .standardBeat(parts, tempoMap):
            typealias PartType = Part<BeatTime, Pitch>

            content = try .standardBeat(Self.transformed(parts: parts,
                                                         partID: partID,
                                                         kind: .quantize) { (part: inout PartType) throws(PartType.Error) in
                part.quantize(to: quantizer,
                              noteIDs: noteIDs,
                              applyTo: applyTo)
            }, tempoMap)

        default:
            throw Error.timeBasisMismatch(expected: .beat)
        }
    }

    /// Quantizes note attack/release times for a set of beat-time parts in this work, along with
    /// any parameter maps selected by `applyTo`. All-or-nothing across just the targeted parts.
    ///
    /// - Parameter partIDs:   The IDs of the parts to quantize.
    /// - Parameter factors:   An array of positive integer subdivision factors.
    /// - Parameter noteIDs:   The identities of the notes to quantize, or `nil` to quantize
    ///                        every note in each targeted part.
    /// - Parameter applyTo:   The parameter maps to quantize along with each targeted part’s note
    ///                        table. Defaults to ``MapTargets/all``.
    ///
    /// - Throws:   ``Work/Error/timeBasisMismatch(expected:)`` if this work does not use beat
    ///             time; ``Work/Error/emptyQuantizationFactors`` /
    ///             ``Work/Error/invalidQuantizationFactor(_:)`` if `factors` is invalid;
    ///             otherwise a transform-failure case naming the part.
    public mutating func quantize(_ partIDs: Set<PartID>,
                                  to factors: [Int],
                                  noteIDs: Set<NoteID>? = nil,
                                  applyTo: MapTargets = .all) throws(Error) {
        let quantizer = try Self._quantizer(factors)

        switch content {
        case let .absoluteBeat(parts, tempoMap):
            typealias PartType = Part<BeatTime, Frequency>

            content = try .absoluteBeat(Self.transformed(parts: parts,
                                                         partIDs: partIDs,
                                                         kind: .quantize) { (part: inout PartType) throws(PartType.Error) in
                part.quantize(to: quantizer,
                              noteIDs: noteIDs,
                              applyTo: applyTo)
            }, tempoMap)

        case let .keyboardBeat(parts, tempoMap):
            typealias PartType = Part<BeatTime, NoteNumber>

            content = try .keyboardBeat(Self.transformed(parts: parts,
                                                         partIDs: partIDs,
                                                         kind: .quantize) { (part: inout PartType) throws(PartType.Error) in
                part.quantize(to: quantizer,
                              noteIDs: noteIDs,
                              applyTo: applyTo)
            }, tempoMap)

        case let .standardBeat(parts, tempoMap):
            typealias PartType = Part<BeatTime, Pitch>

            content = try .standardBeat(Self.transformed(parts: parts,
                                                         partIDs: partIDs,
                                                         kind: .quantize) { (part: inout PartType) throws(PartType.Error) in
                part.quantize(to: quantizer,
                              noteIDs: noteIDs,
                              applyTo: applyTo)
            }, tempoMap)

        default:
            throw Error.timeBasisMismatch(expected: .beat)
        }
    }

    /// Quantizes note attack/release times across every beat-time part in this work, along with
    /// any parameter maps selected by `applyTo` and, when `applyTo` contains ``MapTargets/tempo``,
    /// the work’s own tempo map.
    ///
    /// - Parameter factors:   An array of positive integer subdivision factors.
    /// - Parameter applyTo:   The parameter maps (and tempo map) to quantize along with each
    ///                        part’s note table. Defaults to ``MapTargets/all``.
    ///
    /// - Throws:   ``Work/Error/timeBasisMismatch(expected:)`` if this work does not use beat
    ///             time; ``Work/Error/emptyQuantizationFactors`` /
    ///             ``Work/Error/invalidQuantizationFactor(_:)`` if `factors` is invalid;
    ///             otherwise a transform-failure case naming the part.
    public mutating func quantize(to factors: [Int],
                                  applyTo: MapTargets = .all) throws(Error) {
        let quantizer = try Self._quantizer(factors)

        switch content {
        case let .absoluteBeat(parts, tempoMap):
            typealias PartType = Part<BeatTime, Frequency>

            let newParts = try Self.transformed(parts: parts,
                                                kind: .quantize) { (part: inout PartType) throws(PartType.Error) in
                part.quantize(to: quantizer,
                              applyTo: applyTo)
            }

            content = .absoluteBeat(newParts,
                                    Self._quantized(tempoMap: tempoMap,
                                                    using: quantizer,
                                                    applyTo: applyTo))

        case let .keyboardBeat(parts, tempoMap):
            typealias PartType = Part<BeatTime, NoteNumber>

            let newParts = try Self.transformed(parts: parts,
                                                kind: .quantize) { (part: inout PartType) throws(PartType.Error) in
                part.quantize(to: quantizer,
                              applyTo: applyTo)
            }

            content = .keyboardBeat(newParts,
                                    Self._quantized(tempoMap: tempoMap,
                                                    using: quantizer,
                                                    applyTo: applyTo))

        case let .standardBeat(parts, tempoMap):
            typealias PartType = Part<BeatTime, Pitch>

            let newParts = try Self.transformed(parts: parts,
                                                kind: .quantize) { (part: inout PartType) throws(PartType.Error) in
                part.quantize(to: quantizer,
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
