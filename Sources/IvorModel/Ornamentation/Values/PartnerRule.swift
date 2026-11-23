// © 2026 John Gary Pusey (see LICENSE.md)

/// How far a step partner with no written pitch lies from the main note.
///
/// A written partner pitch, when there is one, takes precedence over the rule.
public enum PartnerRule: String {
    /// The next letter in the key, with the accidental the key gives it.
    case diatonic

    /// A half step.
    case halfStep

    /// A whole step.
    case wholeStep
}

// MARK: - Codable

extension PartnerRule: Codable {
}

// MARK: - Sendable

extension PartnerRule: Sendable {
}
