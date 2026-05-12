public import XestiTools

extension Work {
    public enum Error {
        case unsupportedVersion(Int)
    }
}

// MARK: - EnhancedError

extension Work.Error: EnhancedError {
    public var category: Category? {
        Category("IvorModel")
    }

    public var message: String {
        switch self {
        case let .unsupportedVersion(version):
            "Unsupported Ivor work version: \(version)"
        }
    }
}

// MARK: - Sendable

extension Work.Error: Sendable {
}
