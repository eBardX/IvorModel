public import XestiTools

extension Template {
    public enum Error {
        case invalidLimit
        case invalidMaximumOrder
        case invalidOrder(Int)
        case partNotFound(Int)
        case unsupportedVersion(Int)
    }
}

// MARK: - EnhancedError

extension Template.Error: EnhancedError {
    public var category: Category? {
        Category("IvorModel")
    }

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
