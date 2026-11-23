// © 2026 John Gary Pusey (see LICENSE.md)

public import XestiNumbers

extension NoteTable {

    // MARK: Public Nested Types

    /// How one arpeggio is played: the composer’s instructions for this roll.
    ///
    /// Every field is optional; one left out comes from the work’s or part’s interpretation
    /// rules, or else from a built-in default.
    public struct ArpeggioExecution {

        // MARK: Public Initializers

        /// Creates an arpeggio execution with the provided fields, each `nil` by default.
        ///
        /// - Parameter spread: How far apart the tones start.
        /// - Parameter anchor: Which tone sounds on the beat.
        public init(spread: Spread? = nil,
                    anchor: ArpeggioAnchor? = nil) {
            self.anchor = anchor
            self.spread = spread
        }

        // MARK: Public Instance Properties

        /// Which tone sounds on the beat, or `nil` to take it from the rules.
        public let anchor: ArpeggioAnchor?

        /// How far apart the tones start, or `nil` to take it from the rules.
        public let spread: Spread?
    }
}

// MARK: -

extension NoteTable.ArpeggioExecution {

    // MARK: Public Instance Properties

    /// A Boolean value indicating whether every field is `nil`.
    public var isEmpty: Bool {
        anchor == nil && spread == nil
    }

    // MARK: Public Instance Methods

    /// Returns this execution with a per-tone spread scaled by a factor, or `nil` if the scaled
    /// duration is zero or can’t be computed.
    ///
    /// - Parameter factor: The factor, such as `2` for an augmentation.
    ///
    /// - Returns:  The scaled execution, or `nil`.
    public func scaled(by factor: Number) -> Self? {
        guard let spread
        else { return self }

        return spread.scaled(by: factor).map { Self(spread: $0, anchor: anchor) }
    }
}

// MARK: - Codable

extension NoteTable.ArpeggioExecution: Codable {
}

// MARK: - Hashable

extension NoteTable.ArpeggioExecution: Hashable {
}

// MARK: - Sendable

extension NoteTable.ArpeggioExecution: Sendable {
}
