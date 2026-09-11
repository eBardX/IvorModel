// © 2025–2026 John Gary Pusey (see LICENSE.md)

internal import IvorTiming
internal import IvorTuning

extension Work {

    // MARK: Public Instance Methods

    /// Quantizes note attack/release times for a single beat-time part in this work. No-ops if
    /// no part with `partID` is found.
    ///
    /// - Parameter partID:    The ID of the part to quantize.
    /// - Parameter factors:   An array of positive integer subdivision factors.
    /// - Parameter noteIDs:   The identities of the notes to quantize, or `nil` to quantize
    ///                        every note in the part.
    ///
    /// - Throws:   ``Work/Error/timeBasisMismatch(expected:)`` if this work does not use beat
    ///             time; ``Work/Error/emptyQuantizationFactors`` /
    ///             ``Work/Error/invalidQuantizationFactor(_:)`` if `factors` is invalid;
    ///             otherwise a transform-failure case naming the part.
    public mutating func quantize(_ partID: PartID,
                                  to factors: [Int],
                                  noteIDs: Set<NoteID>? = nil) throws(Error) {
        let quantizer = try Self._quantizer(factors)

        switch content {
        case let .absoluteBeat(parts, tempoMap):
            typealias PartType = Part<BeatTime, Frequency>

            content = try .absoluteBeat(Self.transformed(parts, partID: partID, kind: .quantize) { (part: inout PartType) throws(PartType.Error) in
                part.quantize(to: quantizer, noteIDs: noteIDs)
            }, tempoMap)

        case let .keyboardBeat(parts, tempoMap):
            typealias PartType = Part<BeatTime, NoteNumber>

            content = try .keyboardBeat(Self.transformed(parts, partID: partID, kind: .quantize) { (part: inout PartType) throws(PartType.Error) in
                part.quantize(to: quantizer, noteIDs: noteIDs)
            }, tempoMap)

        case let .standardBeat(parts, tempoMap):
            typealias PartType = Part<BeatTime, Pitch>

            content = try .standardBeat(Self.transformed(parts, partID: partID, kind: .quantize) { (part: inout PartType) throws(PartType.Error) in
                part.quantize(to: quantizer, noteIDs: noteIDs)
            }, tempoMap)

        default:
            throw Error.timeBasisMismatch(expected: .beat)
        }
    }

    /// Quantizes note attack/release times for a set of beat-time parts in this work.
    /// All-or-nothing across just the targeted parts.
    ///
    /// - Parameter partIDs:   The IDs of the parts to quantize.
    /// - Parameter factors:   An array of positive integer subdivision factors.
    /// - Parameter noteIDs:   The identities of the notes to quantize, or `nil` to quantize
    ///                        every note in each targeted part.
    ///
    /// - Throws:   ``Work/Error/timeBasisMismatch(expected:)`` if this work does not use beat
    ///             time; ``Work/Error/emptyQuantizationFactors`` /
    ///             ``Work/Error/invalidQuantizationFactor(_:)`` if `factors` is invalid;
    ///             otherwise a transform-failure case naming the part.
    public mutating func quantize(_ partIDs: Set<PartID>,
                                  to factors: [Int],
                                  noteIDs: Set<NoteID>? = nil) throws(Error) {
        let quantizer = try Self._quantizer(factors)

        switch content {
        case let .absoluteBeat(parts, tempoMap):
            typealias PartType = Part<BeatTime, Frequency>

            content = try .absoluteBeat(Self.transformed(parts, partIDs: partIDs, kind: .quantize) { (part: inout PartType) throws(PartType.Error) in
                part.quantize(to: quantizer, noteIDs: noteIDs)
            }, tempoMap)

        case let .keyboardBeat(parts, tempoMap):
            typealias PartType = Part<BeatTime, NoteNumber>

            content = try .keyboardBeat(Self.transformed(parts, partIDs: partIDs, kind: .quantize) { (part: inout PartType) throws(PartType.Error) in
                part.quantize(to: quantizer, noteIDs: noteIDs)
            }, tempoMap)

        case let .standardBeat(parts, tempoMap):
            typealias PartType = Part<BeatTime, Pitch>

            content = try .standardBeat(Self.transformed(parts, partIDs: partIDs, kind: .quantize) { (part: inout PartType) throws(PartType.Error) in
                part.quantize(to: quantizer, noteIDs: noteIDs)
            }, tempoMap)

        default:
            throw Error.timeBasisMismatch(expected: .beat)
        }
    }

    /// Quantizes note attack/release times across every beat-time part in this work.
    ///
    /// - Parameter factors:   An array of positive integer subdivision factors.
    ///
    /// - Throws:   ``Work/Error/timeBasisMismatch(expected:)`` if this work does not use beat
    ///             time; ``Work/Error/emptyQuantizationFactors`` /
    ///             ``Work/Error/invalidQuantizationFactor(_:)`` if `factors` is invalid;
    ///             otherwise a transform-failure case naming the part.
    public mutating func quantize(to factors: [Int]) throws(Error) {
        let quantizer = try Self._quantizer(factors)

        switch content {
        case let .absoluteBeat(parts, tempoMap):
            typealias PartType = Part<BeatTime, Frequency>

            content = try .absoluteBeat(Self.transformed(parts, kind: .quantize) { (part: inout PartType) throws(PartType.Error) in
                part.quantize(to: quantizer)
            }, tempoMap)

        case let .keyboardBeat(parts, tempoMap):
            typealias PartType = Part<BeatTime, NoteNumber>

            content = try .keyboardBeat(Self.transformed(parts, kind: .quantize) { (part: inout PartType) throws(PartType.Error) in
                part.quantize(to: quantizer)
            }, tempoMap)

        case let .standardBeat(parts, tempoMap):
            typealias PartType = Part<BeatTime, Pitch>

            content = try .standardBeat(Self.transformed(parts, kind: .quantize) { (part: inout PartType) throws(PartType.Error) in
                part.quantize(to: quantizer)
            }, tempoMap)

        default:
            throw Error.timeBasisMismatch(expected: .beat)
        }
    }

    // MARK: Private Type Methods

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
