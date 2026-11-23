// © 2026 John Gary Pusey (see LICENSE.md)

/// Where a trill or mordent starts: on its main note or on its partner.
///
/// There is no start from below: a step partner’s side belongs to the ornament (see
/// ``PartnerSide``), and a Baroque *Triller von unten* is out of scope.
public enum OrnamentStart: String {
    /// The ornament starts on its main note.
    case main

    /// The ornament starts on its partner.
    case partner
}

// MARK: - Codable

extension OrnamentStart: Codable {
}

// MARK: - Sendable

extension OrnamentStart: Sendable {
}
