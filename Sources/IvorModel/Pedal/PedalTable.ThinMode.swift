// © 2026 John Gary Pusey (see LICENSE.md)

extension PedalTable {

    // MARK: Public Nested Types

    /// How ``PedalTable/thin(_:)`` reduces a pedal table’s entries.
    public enum ThinMode {
        /// Keeps a level only where it differs from the last kept level by at least `tolerance`,
        /// where it crosses the threshold at which the pedal counts as down
        /// (``Pedal/Level/isDown``), or where it is exactly ``Pedal/Level/off`` or
        /// ``Pedal/Level/on``. A gradual sweep keeps a step for about every `tolerance` of
        /// travel.
        case merge(tolerance: Pedal.Level)

        /// Snaps every level to ``Pedal/Level/on`` if the pedal counts as down
        /// (``Pedal/Level/isDown``) and to ``Pedal/Level/off`` otherwise, leaving a plain
        /// down/up switch.
        case snap
    }
}

// MARK: - Equatable

extension PedalTable.ThinMode: Equatable {
}

// MARK: - Sendable

extension PedalTable.ThinMode: Sendable {
}
