// © 2025–2026 John Gary Pusey (see LICENSE.md)

public import XestiNumbers
public import XestiTools

extension InstrumentMap {
    /// An error thrown by ``InstrumentMap`` operations.
    public enum Error {
        /// A failure that occurred while augmenting an entry.
        case augmentFailure(TimeType)

        /// A failure that occurred while diminishing an entry.
        case diminishFailure(TimeType)

        /// An anchor that does not contain the range of the entries it is being applied to.
        case invalidAnchor

        /// An augmentation factor that is not a positive rational number ≥ 1.
        case invalidAugmentationFactor(Number)

        /// A diminution factor that is not a positive rational number ≥ 1.
        case invalidDiminutionFactor(Number)

        /// A failure that occurred while moving an entry.
        case moveFailure(TimeType)

        /// A failure that occurred while reversing an entry.
        case reverseFailure(TimeType)
    }
}

// MARK: - EnhancedError

extension InstrumentMap.Error: EnhancedError {
    /// The error category for this error.
    public var category: Category? {
        Category("IvorModel")
    }

    /// The human-readable message for this error.
    public var message: String {
        switch self {
        case let .augmentFailure(time):
            "Unable to augment instrument map entry, time: \(time)"

        case let .diminishFailure(time):
            "Unable to diminish instrument map entry, time: \(time)"

        case .invalidAnchor:
            "Invalid anchor: does not contain the range of entries it is being applied to"

        case let .invalidAugmentationFactor(factor):
            "Invalid augmentation factor: \(factor)"

        case let .invalidDiminutionFactor(factor):
            "Invalid diminution factor: \(factor)"

        case let .moveFailure(time):
            "Unable to move instrument map entry, time: \(time)"

        case let .reverseFailure(time):
            "Unable to reverse instrument map entry, time: \(time)"
        }
    }
}

// MARK: - Equatable

extension InstrumentMap.Error: Equatable {
}

// MARK: - Sendable

extension InstrumentMap.Error: Sendable {
}
