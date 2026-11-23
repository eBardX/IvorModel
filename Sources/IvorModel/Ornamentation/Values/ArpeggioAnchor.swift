// © 2026 John Gary Pusey (see LICENSE.md)

/// Which tone of an arpeggio sounds on the beat.
///
/// The other tones come before it or after it, spread by the arpeggio’s execution.
public enum ArpeggioAnchor: String {
    /// The first tone of the roll sounds on the beat, and the rest follow it.
    case firstOnBeat

    /// The last tone of the roll sounds on the beat, and the rest come before it.
    case lastOnBeat
}

// MARK: - Codable

extension ArpeggioAnchor: Codable {
}

// MARK: - Sendable

extension ArpeggioAnchor: Sendable {
}
