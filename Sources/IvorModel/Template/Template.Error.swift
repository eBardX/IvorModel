// © 2025–2026 John Gary Pusey (see LICENSE.md)

public import XestiTools

extension Template {
    /// An error thrown by ``Template`` operations.
    public enum Error {
        /// The generation options don’t match the template’s pitch notation and time basis, or
        /// the analysis options don’t match the work’s.
        case incompatibleOptions

        /// Templates mixed in generation differ in pitch notation, time basis or state recipe, or
        /// can’t generate at the recipe’s orders.
        case incompatibleTemplates

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

        /// The phrase to continue has no note events.
        case invalidPhrase

        /// The state recipe records neither pitch nor duration, or separates pitch and duration
        /// without recording both.
        case invalidStateRecipe

        /// An analysis tolerance is not positive and finite, or a quantization grid has no
        /// factors or a factor that is not positive.
        case invalidTolerance

        /// An analysis variant has a time factor that isn’t rational, positive and other than 1, or
        /// a unison transposition, or appears twice.
        case invalidVariants

        /// No part was found at the requested index.
        case partNotFound(Int)

        /// The template is locked, so it cannot be modified.
        case templateIsLocked

        /// A template that a generation recipe mixes in wasn’t supplied.
        case templateNotFound(TemplateID)

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

        case .incompatibleTemplates:
            "Templates mixed together must share pitch notation, time basis and what they learn, and support the order"

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

        case .invalidPhrase:
            "A phrase to continue must have at least one note or rest"

        case .invalidStateRecipe:
            "A template must learn pitches, durations or both; to learn them separately, it must learn both"

        case .invalidTolerance:
            "Tolerance must be positive (> 0)"

        case .invalidVariants:
            "Variants must have rational, positive time factors other than 1, transpositions other than a unison, and no duplicates"

        case let .partNotFound(index):
            "Ivor part not found at index \(index)"

        case .templateIsLocked:
            "The template is locked and cannot be modified."

        case let .templateNotFound(templateID):
            "Template \(templateID) to mix in wasn’t found"

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
