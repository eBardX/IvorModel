// © 2025–2026 John Gary Pusey (see LICENSE.md)

public import XestiTools

extension Work {
    /// An error thrown by ``Work`` operations.
    public enum Error {
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
        case let .unsupportedVersion(version):
            "Unsupported Ivor work version: \(version)"
        }
    }
}

// MARK: - Sendable

extension Work.Error: Sendable {
}
