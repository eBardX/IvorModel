// © 2025–2026 John Gary Pusey (see LICENSE.md)

public import XestiTools

extension Template {
    /// An error thrown by ``Template`` operations.
    public enum Error {
        /// The generation options don’t match the template’s pitch notation and time basis, or
        /// the analysis options don’t match the work’s.
        case incompatibleOptions

        /// The generation contrast is not positive and finite.
        case invalidContrast

        /// The generation length, or a cadence’s minimum length, is not positive.
        case invalidLimit

        /// The maximum pattern depth is not a positive integer.
        case invalidMaximumOrder

        /// The generation mixing has a blend weight outside 0 to 1 (exclusive), a morph length
        /// that is not positive, or an invalid morph curve.
        case invalidMixing

        /// The requested pattern depth exceeds the maximum supported depth.
        case invalidOrder(Int)

        /// An analysis tolerance is not positive and finite, or a quantization grid has no
        /// factors or a factor that is not positive.
        case invalidTolerance

        /// No part was found at the requested index.
        case partNotFound(Int)

        /// The template is locked, so it cannot be modified.
        case templateIsLocked

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
        case .incompatibleOptions:
            "Options must match the pitch notation and time basis"

        case .invalidContrast:
            "Contrast must be positive (> 0)"

        case .invalidLimit:
            "Limit must be positive (> 0)"

        case .invalidMaximumOrder:
            "Maximum order must be positive (> 0)"

        case .invalidMixing:
            "Blend weight must be between 0 and 1 (exclusive), and morph length must be positive"

        case let .invalidOrder(maxOrder):
            "Order must be between 0 and \(maxOrder) (inclusive)"

        case .invalidTolerance:
            "Tolerance must be positive (> 0)"

        case let .partNotFound(index):
            "Ivor part not found at index \(index)"

        case .templateIsLocked:
            "The template is locked and cannot be modified."

        case let .unsupportedVersion(version):
            "Unsupported Ivor template version: \(version)"
        }
    }
}

// MARK: - Equatable

extension Template.Error: Equatable {
}

// MARK: - Sendable

extension Template.Error: Sendable {
}
