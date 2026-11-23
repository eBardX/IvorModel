// © 2026 John Gary Pusey (see LICENSE.md)

/// The shape of a fermata sign, which sets how long it holds by default.
///
/// A fermata has no orientation: an inverted fermata, drawn below the staff, means the same as an
/// upright one, so only the shape is kept.
public enum FermataShape: String {
    /// A long fermata (square).
    case long

    /// A normal fermata.
    case normal

    /// A short fermata (triangular).
    case short

    /// A very long fermata (double square).
    case veryLong

    /// A very short fermata.
    case veryShort
}

// MARK: - Codable

extension FermataShape: Codable {
}

// MARK: - CodingKeyRepresentable

//
// So a dictionary keyed by shape, such as `FermataRules.holds`, encodes as an object keyed by
// the shape’s name rather than as an array of alternating keys and values.
//
extension FermataShape: CodingKeyRepresentable {
}

// MARK: - Sendable

extension FermataShape: Sendable {
}
