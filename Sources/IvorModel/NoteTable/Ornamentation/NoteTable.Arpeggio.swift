// © 2026 John Gary Pusey (see LICENSE.md)

public import XestiNumbers

extension NoteTable {

    // MARK: Public Nested Types

    /// One tone’s part in a rolled chord.
    ///
    /// Each tone of a roll carries its own arpeggio. Tones anywhere in the work that share an
    /// attack and a ``group`` are one roll, so a roll across two parts plays as one gesture; they
    /// must agree on direction and execution. The ``group`` and ``direction`` are the sign; the
    /// ``execution``, if any, is how the roll is played.
    public struct Arpeggio {

        // MARK: Public Initializers

        /// Creates an arpeggio with the provided group, direction and execution.
        ///
        /// - Parameter group:      The number joining this tone to the others of its roll.
        /// - Parameter direction:  Which way the roll goes, or `nil` if the sign shows none (it
        ///                         plays up). Defaults to `nil`.
        /// - Parameter execution:  How the roll is played, or `nil` to follow the rules.
        ///                         Defaults to `nil`.
        public init(group: ArpeggioGroup,
                    direction: ArpeggioDirection? = nil,
                    execution: ArpeggioExecution? = nil) {
            self.direction = direction
            self.execution = execution
            self.group = group
        }

        // MARK: Public Instance Properties

        /// Which way the roll goes, or `nil` if the sign shows none (it plays up). Part of the
        /// sign.
        public let direction: ArpeggioDirection?

        /// How the roll is played, or `nil` to follow the rules. Part of the execution.
        public let execution: ArpeggioExecution?

        /// The number joining this tone to the others of its roll. Part of the sign.
        public let group: ArpeggioGroup
    }
}

// MARK: -

extension NoteTable.Arpeggio {

    // MARK: Public Instance Methods

    /// Returns this arpeggio with a per-tone spread scaled by a factor, or `nil` if the scaled
    /// duration is zero or can’t be computed.
    ///
    /// - Parameter factor: The factor, such as `2` for an augmentation.
    ///
    /// - Returns:  The scaled arpeggio, or `nil`.
    public func scaled(by factor: Number) -> Self? {
        guard let execution
        else { return self }

        return execution.scaled(by: factor).map {
            Self(group: group,
                 direction: direction,
                 execution: $0)
        }
    }
}

// MARK: - Codable

extension NoteTable.Arpeggio: Codable {
}

// MARK: - Hashable

extension NoteTable.Arpeggio: Hashable {
}

// MARK: - Sendable

extension NoteTable.Arpeggio: Sendable {
}
