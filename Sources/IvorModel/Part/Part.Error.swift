// © 2025–2026 John Gary Pusey (see LICENSE.md)

public import XestiTools

extension Part {

    // MARK: Public Nested Types

    /// An error thrown by ``Part`` operations.
    public enum Error {
        /// A failure that occurred in the part’s dynamic map.
        case dynamicMapFailure(DynamicMap<TimeType>.Error)

        /// A failure that occurred in the part’s instrument table.
        case instrumentTableFailure(InstrumentTable<TimeType>.Error)

        /// A failure that occurred in the part’s note table.
        case noteTableFailure(NoteTable<TimeType, PitchType>.Error)

        /// A failure that occurred in the part’s pan map.
        case panMapFailure(PanMap<TimeType>.Error)

        /// A failure that occurred in one of the part’s pedal tables.
        case pedalTableFailure(Pedal, PedalTable<TimeType>.Error)
    }
}

// MARK: - EnhancedError

extension Part.Error: EnhancedError {

    // MARK: Public Instance Properties

    /// The error category for this error.
    public var category: Category? {
        Category("IvorModel")
    }

    /// The human-readable message for this error.
    public var message: String {
        switch self {
        case let .dynamicMapFailure(error):
            "Dynamic map failure: \(error.message)"

        case let .instrumentTableFailure(error):
            "Instrument table failure: \(error.message)"

        case let .noteTableFailure(error):
            "Note table failure: \(error.message)"

        case let .panMapFailure(error):
            "Pan map failure: \(error.message)"

        case let .pedalTableFailure(pedal, error):
            "Pedal table failure (\(pedal.rawValue)): \(error.message)"
        }
    }
}

// MARK: - Equatable

extension Part.Error: Equatable {
}

// MARK: - Sendable

extension Part.Error: Sendable {
}
