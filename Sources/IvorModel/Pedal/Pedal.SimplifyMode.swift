// © 2026 John Gary Pusey (see LICENSE.md)

extension Pedal {

    // MARK: Public Nested Types

    /// How ``PedalTable/simplify(_:)`` reduces a pedal table’s entries.
    public enum SimplifyMode {
        /// Keeps a level only where it differs from the last kept level by at least `tolerance`,
        /// where it crosses the threshold at which the pedal counts as down
        /// (``Pedal/Level/isDown``), or where it is exactly ``Pedal/Level/up`` or
        /// ``Pedal/Level/down``. A gradual sweep keeps a step for about every `tolerance` of
        /// travel.
        case merge(tolerance: Pedal.Level)

        /// Snaps every level to ``Pedal/Level/down`` if the pedal counts as down
        /// (``Pedal/Level/isDown``) and to ``Pedal/Level/up`` otherwise, leaving a plain
        /// down/up switch.
        case snap
    }
}

// MARK: - Equatable

extension Pedal.SimplifyMode: Equatable {
}

// MARK: - Sendable

extension Pedal.SimplifyMode: Sendable {
}
