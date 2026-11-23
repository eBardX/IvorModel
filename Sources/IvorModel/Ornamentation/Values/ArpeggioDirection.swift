// © 2026 John Gary Pusey (see LICENSE.md)

/// Which way an arpeggio rolls its chord.
///
/// An arpeggio with no direction plays up.
public enum ArpeggioDirection: String {
    /// From the highest tone to the lowest.
    case down

    /// From the lowest tone to the highest.
    case up
}

// MARK: - Codable

extension ArpeggioDirection: Codable {
}

// MARK: - Sendable

extension ArpeggioDirection: Sendable {
}
