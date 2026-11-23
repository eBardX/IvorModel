// © 2026 John Gary Pusey (see LICENSE.md)

public import XestiNumbers

extension NoteTable {

    // MARK: Public Nested Types

    /// How a grace figure, or one of its events, is played: where its time comes from, and how
    /// much.
    ///
    /// Every field is optional; one left out comes from the work’s or part’s interpretation
    /// rules, or else from a built-in default. The two amounts are MusicXML’s steal-time
    /// attributes. An execution on an event overrides the figure’s.
    public struct GraceExecution {

        // MARK: Public Initializers

        /// Creates a grace execution with the provided amounts, each `nil` by default.
        ///
        /// - Parameter fromPrevious:   The time taken from the neighbor on the figure’s side:
        ///                             the note before, for a figure before its main note
        ///                             (MusicXML’s `steal-time-previous`); the note after, for
        ///                             a figure after it.
        /// - Parameter fromMain:       The time taken from inside the main note (MusicXML’s
        ///                             `steal-time-following`): from its start for a figure
        ///                             before it, or from its end for a figure after it.
        public init(fromPrevious: Amount? = nil,
                    fromMain: Amount? = nil) {
            self.fromMain = fromMain
            self.fromPrevious = fromPrevious
        }

        // MARK: Public Instance Properties

        /// The time taken from inside the main note — its start for a figure before it, its end
        /// for a figure after it — or `nil` to take it from the rules.
        public let fromMain: Amount?

        /// The time taken from the neighbor on the figure’s side — the note before, for a
        /// figure before its main note; the note after, for a figure after it — or `nil` to
        /// take it from the rules.
        ///
        /// Reversing a part keeps both amounts as they are: the mirror image of time taken from
        /// the note before a figure is time taken from the note after it.
        public let fromPrevious: Amount?
    }
}

// MARK: -

extension NoteTable.GraceExecution {

    // MARK: Public Instance Properties

    /// A Boolean value indicating whether every field is `nil`.
    public var isEmpty: Bool {
        fromMain == nil && fromPrevious == nil
    }

    // MARK: Public Instance Methods

    /// Returns this execution with its durations scaled by a factor, or `nil` if a scaled
    /// duration is zero or can’t be computed. Shares are unchanged.
    ///
    /// - Parameter factor: The factor, such as `2` for an augmentation.
    ///
    /// - Returns:  The scaled execution, or `nil`.
    public func scaled(by factor: Number) -> Self? {
        var fromMain = fromMain
        var fromPrevious = fromPrevious

        if let amount = fromMain {
            guard let scaled = amount.scaled(by: factor)
            else { return nil }

            fromMain = scaled
        }

        if let amount = fromPrevious {
            guard let scaled = amount.scaled(by: factor)
            else { return nil }

            fromPrevious = scaled
        }

        return Self(fromPrevious: fromPrevious,
                    fromMain: fromMain)
    }
}

// MARK: - Codable

extension NoteTable.GraceExecution: Codable {
}

// MARK: - Hashable

extension NoteTable.GraceExecution: Hashable {
}

// MARK: - Sendable

extension NoteTable.GraceExecution: Sendable {
}
