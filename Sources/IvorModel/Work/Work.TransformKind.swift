// © 2025–2026 John Gary Pusey (see LICENSE.md)

extension Work {

    // MARK: Public Nested Types

    /// One of the six standard note-table transforms, named for error reporting.
    public enum TransformKind {
        /// The `augment(by:...)` transform.
        case augment

        /// The `diminish(by:...)` transform.
        case diminish

        /// The `invert(around:...)` transform.
        case invert

        /// The `move(by:...)` transform.
        case move

        /// The `reverse(within:...)` transform.
        case reverse

        /// The `transpose(by:...)` transform.
        case transpose
    }
}

// MARK: - CustomStringConvertible

extension Work.TransformKind: CustomStringConvertible {

    /// The string representation of this transform kind (e.g., `"augment"`, `"invert"`).
    public var description: String {
        switch self {
        case .augment:
            "augment"

        case .diminish:
            "diminish"

        case .invert:
            "invert"

        case .move:
            "move"

        case .reverse:
            "reverse"

        case .transpose:
            "transpose"
        }
    }
}

// MARK: - Equatable

extension Work.TransformKind: Equatable {
}

// MARK: - Sendable

extension Work.TransformKind: Sendable {
}
