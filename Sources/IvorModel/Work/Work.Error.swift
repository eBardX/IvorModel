// © 2025–2026 John Gary Pusey (see LICENSE.md)

public import XestiTools

extension Work {
    /// An error thrown by ``Work`` operations.
    public enum Error {
        /// The conversion context is missing a keyboard map.
        case missingKeyboardMap

        /// The conversion context is missing a pitch speller.
        case missingPitchSpeller

        /// The conversion context is missing a pitch standard.
        case missingPitchStandard

        /// The conversion context is missing a tuning system.
        case missingTuningSystem

        /// The work was encoded with an unsupported version number.
        case unsupportedVersion(Int)
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
        case .missingKeyboardMap:
            "A keyboard map is required for this conversion."

        case .missingPitchSpeller:
            "A pitch speller is required for this conversion."

        case .missingPitchStandard:
            "A pitch standard is required for this conversion."

        case .missingTuningSystem:
            "A tuning system is required for this conversion."

        case let .unsupportedVersion(version):
            "Unsupported Ivor work version: \(version)"
        }
    }
}

// MARK: - Sendable

extension Work.Error: Sendable {
}
