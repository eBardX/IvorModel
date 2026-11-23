// © 2026 John Gary Pusey (see LICENSE.md)

/// Which side of the main note an ornament’s step partner lies on.
///
/// A trill’s partner is always above. A mordent’s partner can be on either side: above is the upper
/// mordent (main, upper, main) and below the lower one.
public enum PartnerSide: String {
    /// The partner is a step above the main note.
    case above

    /// The partner is a step below the main note.
    case below
}

// MARK: - Codable

extension PartnerSide: Codable {
}

// MARK: - Sendable

extension PartnerSide: Sendable {
}
