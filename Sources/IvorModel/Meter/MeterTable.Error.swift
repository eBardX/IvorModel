// © 2026 John Gary Pusey (see LICENSE.md)

public import IvorTiming
public import XestiNumbers
public import XestiTools

extension MeterTable {

    // MARK: Public Nested Types

    /// An error thrown by ``MeterTable`` operations.
    public enum Error {
        /// An entry that would land on a beat time another entry already occupies.
        case entryExists(BeatTime)

        /// An augmentation factor that is not a positive rational number ≥ 1.
        case invalidAugmentationFactor(Number)

        /// A diminution factor that is not a positive rational number ≥ 1.
        case invalidDiminutionFactor(Number)

        /// A pickup that the meter table can’t hold: a non-zero pickup without a metered entry at
        /// time 0, one not shorter than that entry’s bar length, or one that runs past the second
        /// entry — or an edit that would leave the current pickup in one of those states.
        case invalidPickup
    }
}

// MARK: - EnhancedError

extension MeterTable.Error: EnhancedError {

    // MARK: Public Instance Properties

    /// The error category for this error.
    public var category: Category? {
        Category("IvorModel")
    }

    /// The human-readable message for this error.
    public var message: String {
        switch self {
        case let .entryExists(beatTime):
            "Meter table entry already exists, beat time: \(beatTime)"

        case let .invalidAugmentationFactor(factor):
            "Invalid augmentation factor: \(factor)"

        case let .invalidDiminutionFactor(factor):
            "Invalid diminution factor: \(factor)"

        case .invalidPickup:
            "Invalid pickup: needs a metered entry at time 0, and must be shorter than its bar and end by the next entry"
        }
    }
}

// MARK: - Equatable

extension MeterTable.Error: Equatable {
}

// MARK: - Sendable

extension MeterTable.Error: Sendable {
}
