// © 2025–2026 John Gary Pusey (see LICENSE.md)

public import IvorTiming
public import IvorTuning
public import XestiTools

extension Work {
    /// An error thrown by ``Work`` operations.
    public enum Error {
        /// A failure that occurred in a part’s dynamic map while carrying it along with a
        /// transform.
        case dynamicMapTransformFailure(TransformKind, partID: PartID, detail: String)

        /// A failure that occurred in a part’s instrument map while carrying it along with a
        /// transform.
        case instrumentMapTransformFailure(TransformKind, partID: PartID, detail: String)

        /// The conversion context is missing a keyboard map.
        case missingKeyboardMap

        /// The conversion context is missing a pitch speller.
        case missingPitchSpeller

        /// The conversion context is missing a pitch standard.
        case missingPitchStandard

        /// The conversion context is missing a tuning system.
        case missingTuningSystem

        /// A failure that occurred in a part’s pan map while carrying it along with a transform.
        case panMapTransformFailure(TransformKind, partID: PartID, detail: String)

        /// The requested transform was invoked with a pitch notation that does not match the
        /// work’s own.
        case pitchNotationMismatch(expected: PitchNotation)

        /// A failure that occurred in the work’s tempo map while carrying it along with a
        /// whole-work transform.
        case tempoMapTransformFailure(TransformKind, detail: String)

        /// The requested transform was invoked with a time basis that does not match the work’s
        /// own.
        case timeBasisMismatch(expected: TimeBasis)

        /// A failure that occurred in a part’s note table while applying a transform.
        case transformFailure(TransformKind, partID: PartID, detail: String)

        /// The context’s tuning system does not support standard pitch notation.
        case unsupportedStandardConversion

        /// The work was encoded with an unsupported version number.
        case unsupportedVersion(Int)

        /// The work is locked, so its content cannot be modified.
        case workIsLocked
    }
}

// MARK: - EnhancedError

extension Work.Error: EnhancedError {
    /// The error category for this error.
    public var category: Category? {
        Category("IvorModel")
    }

    /// The human-readable message for this error.
    public var message: String {
        switch self {
        case let .dynamicMapTransformFailure(kind, partID, detail):
            "Dynamic map failure during \(kind) of part \(partID.stringValue): \(detail)"

        case let .instrumentMapTransformFailure(kind, partID, detail):
            "Instrument map failure during \(kind) of part \(partID.stringValue): \(detail)"

        case .missingKeyboardMap:
            "A keyboard map is required for this conversion."

        case .missingPitchSpeller:
            "A pitch speller is required for this conversion."

        case .missingPitchStandard:
            "A pitch standard is required for this conversion."

        case .missingTuningSystem:
            "A tuning system is required for this conversion."

        case let .panMapTransformFailure(kind, partID, detail):
            "Pan map failure during \(kind) of part \(partID.stringValue): \(detail)"

        case let .pitchNotationMismatch(expected):
            "This transform requires \(expected) pitch notation."

        case let .tempoMapTransformFailure(kind, detail):
            "Tempo map failure during \(kind): \(detail)"

        case let .timeBasisMismatch(expected):
            "This transform requires \(expected) time basis."

        case let .transformFailure(kind, partID, detail):
            "Note table failure during \(kind) of part \(partID.stringValue): \(detail)"

        case .unsupportedStandardConversion:
            "The tuning system does not support standard pitch notation."

        case let .unsupportedVersion(version):
            "Unsupported Ivor work version: \(version)"

        case .workIsLocked:
            "The work is locked and cannot be modified."
        }
    }
}

// MARK: - Equatable

extension Work.Error: Equatable {
}

// MARK: - Sendable

extension Work.Error: Sendable {
}
