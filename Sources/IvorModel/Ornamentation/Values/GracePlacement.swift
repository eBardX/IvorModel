// © 2026 John Gary Pusey (see LICENSE.md)

/// Where a grace figure before a note sounds: on the beat or before it.
///
/// On the beat, the figure takes its time from the main note; before the beat, from the note before.
public enum GracePlacement: String {
    /// The figure ends on the beat, taking its time from the note before.
    case beforeBeat

    /// The figure starts on the beat, taking its time from the main note.
    case onBeat
}

// MARK: - Codable

extension GracePlacement: Codable {
}

// MARK: - Sendable

extension GracePlacement: Sendable {
}
