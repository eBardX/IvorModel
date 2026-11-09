// © 2026 John Gary Pusey (see LICENSE.md)

public import XestiNumbers
public import XestiTools

extension PedalTable {

    // MARK: Public Nested Types

    /// An error thrown by ``PedalTable`` operations.
    public enum Error {
        /// A failure that occurred while augmenting an entry.
        case augmentFailure(TimeType)

        /// A failure that occurred while diminishing an entry.
        case diminishFailure(TimeType)

        /// An anchor that does not fit what it is applied to: a time or time range that does not
        /// bound the entries being transformed, or an entry to insert before that is missing or
        /// at a different time.
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

extension PedalTable.Error: EnhancedError {

    // MARK: Public Instance Properties

    /// The error category for this error.
    public var category: Category? {
        Category("IvorModel")
    }

    /// The human-readable message for this error.
    public var message: String {
        switch self {
        case let .augmentFailure(time):
            "Unable to augment pedal table entry, time: \(time)"

        case let .diminishFailure(time):
            "Unable to diminish pedal table entry, time: \(time)"

        case .invalidAnchor:
            "Invalid anchor: does not bound the entries, or is not an entry at the insertion time"

        case let .invalidAugmentationFactor(factor):
            "Invalid augmentation factor: \(factor)"

        case let .invalidDiminutionFactor(factor):
            "Invalid diminution factor: \(factor)"

        case let .moveFailure(time):
            "Unable to move pedal table entry, time: \(time)"

        case let .reverseFailure(time):
            "Unable to reverse pedal table entry, time: \(time)"
        }
    }
}

// MARK: - Equatable

extension PedalTable.Error: Equatable {
}

// MARK: - Sendable

extension PedalTable.Error: Sendable {
}
