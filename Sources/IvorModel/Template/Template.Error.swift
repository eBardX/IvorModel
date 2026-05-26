// © 2025–2026 John Gary Pusey (see LICENSE.md)

public import XestiTools

extension Template {
    /// An error thrown by ``Template`` operations.
    public enum Error {
        /// The generation limit is not a positive integer.
        case invalidLimit

        /// The maximum pattern depth is not a positive integer.
        case invalidMaximumOrder

        /// The requested pattern depth exceeds the maximum supported depth.
        case invalidOrder(Int)

        /// No part was found at the requested index.
        case partNotFound(Int)

        /// The template was encoded with an unsupported version number.
        case unsupportedVersion(Int)
    }
}

// MARK: - EnhancedError

extension Template.Error: EnhancedError {
    /// The error category for this error.
    public var category: Category? {
        Category("IvorModel")
    }

    /// The human-readable message for this error.
    public var message: String {
        switch self {
        case .invalidLimit:
            "Limit must be positive (> 0)"

        case .invalidMaximumOrder:
            "Maximum order must be positive (> 0)"

        case let .invalidOrder(maxOrder):
            "Order must be between 0 and \(maxOrder) (inclusive)"

        case let .partNotFound(index):
            "Ivor part not found at index \(index)"

        case let .unsupportedVersion(version):
            "Unsupported Ivor template version: \(version)"
        }
    }
}

// MARK: - Sendable

extension Template.Error: Sendable {
}
