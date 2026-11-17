// © 2026 John Gary Pusey (see LICENSE.md)

public import IvorTiming
public import XestiNumbers
public import XestiTools

extension KeySignatureTable {

    // MARK: Public Nested Types

    /// An error thrown by ``KeySignatureTable`` operations.
    public enum Error {
        /// An entry that would land on a beat time another entry already occupies.
        case entryExists(BeatTime)

        /// An augmentation factor that is not a positive rational number ≥ 1.
        case invalidAugmentationFactor(Number)

        /// A diminution factor that is not a positive rational number ≥ 1.
        case invalidDiminutionFactor(Number)
    }
}

// MARK: - EnhancedError

extension KeySignatureTable.Error: EnhancedError {

    // MARK: Public Instance Properties

    /// The error category for this error.
    public var category: Category? {
        Category("IvorModel")
    }

    /// The human-readable message for this error.
    public var message: String {
        switch self {
        case let .entryExists(beatTime):
            "Key signature table entry already exists, beat time: \(beatTime)"

        case let .invalidAugmentationFactor(factor):
            "Invalid augmentation factor: \(factor)"

        case let .invalidDiminutionFactor(factor):
            "Invalid diminution factor: \(factor)"
        }
    }
}

// MARK: - Equatable

extension KeySignatureTable.Error: Equatable {
}

// MARK: - Sendable

extension KeySignatureTable.Error: Sendable {
}
