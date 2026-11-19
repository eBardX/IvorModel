// © 2026 John Gary Pusey (see LICENSE.md)

public import XestiTools

extension Extra {

    // MARK: Public Nested Types

    /// The kind of model value a known extra is attached to (see ``Extra/Definition``).
    public enum Target {

        /// An entry in a ``DynamicMap``.
        case dynamicEntry

        /// An entry in an ``InstrumentTable``.
        case instrumentEntry

        /// An entry in a ``KeyTable``.
        case keyEntry

        /// An entry in a ``MeterTable``.
        case meterEntry

        /// A note in a ``NoteTable``.
        case note

        /// An entry in a ``PanMap``.
        case panEntry

        /// A ``Part`` itself, in ``Part/extras``.
        case part

        /// An entry in a ``PedalTable``.
        case pedalEntry

        /// An entry in a tempo map.
        case tempoEntry

        /// A ``Work`` itself, in ``Work/extras``.
        case work
    }
}

// MARK: - CaseIterable

extension Extra.Target: CaseIterable {
}

// MARK: - Hashable

extension Extra.Target: Hashable {
}

// MARK: - Sendable

extension Extra.Target: Sendable {
}
