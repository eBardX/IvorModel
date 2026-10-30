// © 2026 John Gary Pusey (see LICENSE.md)

public import XestiNumbers

extension Template.AnalysisOptions {

    // MARK: Public Nested Types

    /// Transformed copies of the part to analyze along with it, so that one template learns a
    /// family of related forms.
    ///
    /// The variants are every combination of the choices: each transposition (and none), inverted
    /// or not, in retrograde or not, and at each time factor (and ×1). The original is always one
    /// of them. For example, 11 transpositions with inversion and retrograde give the 48 forms of
    /// a tone row.
    ///
    /// Each variant is made from the part’s note table, after the timing tolerance: inverted
    /// around the part’s own pitch range, then transposed, then reversed within the part’s own time
    /// range, then scaled in time from the part’s start. It is then sliced into note events like the
    /// original, and becomes a sequence of its own. A variant whose states are the same as an
    /// earlier one’s isn’t trained again, and one that can’t be made — a transposition out of
    /// range, say — is left out; ``Template/analysisSummary`` records both.
    public struct Variants {

        // MARK: Public Initializers

        /// Creates a new set of variants.
        ///
        /// - Parameter transpositions: The transpositions to add, besides none. Defaults to none.
        /// - Parameter inverts:        Whether to add inverted forms. Defaults to `false`.
        /// - Parameter retrogrades:    Whether to add forms in retrograde. Defaults to `false`.
        /// - Parameter timeFactors:    The time factors to add, besides ×1. Defaults to none.
        public init(transpositions: [Transposition] = [],
                    inverts: Bool = false,
                    retrogrades: Bool = false,
                    timeFactors: [Number] = []) {
            self.inverts = inverts
            self.retrogrades = retrogrades
            self.timeFactors = timeFactors
            self.transpositions = transpositions
        }

        // MARK: Public Instance Properties

        /// Whether to add inverted forms.
        public var inverts: Bool

        /// Whether to add forms in retrograde.
        public var retrogrades: Bool

        /// The time factors to add, besides ×1. A factor above 1 augments, and one below 1
        /// diminishes. Each must be rational, positive and other than 1, and appear once.
        public var timeFactors: [Number]

        /// The transpositions to add, besides none. Each must suit the work’s pitch notation, be
        /// other than a unison, and appear once.
        public var transpositions: [Transposition]
    }
}

// MARK: -

extension Template.AnalysisOptions.Variants {

    // MARK: Public Type Properties

    /// No variants: the part alone, as earlier versions analyzed it.
    public static let none = Self()

    // MARK: Public Instance Properties

    /// The number of sequences these variants make, the original included.
    public var sequenceCount: Int {
        (1 + transpositions.count) * (inverts ? 2 : 1) * (retrogrades ? 2 : 1) * (1 + timeFactors.count)
    }

    // MARK: Internal Instance Properties

    //
    // Every combination, the original first: by inversion, then transposition, then retrograde,
    // then time factor.
    //
    internal var all: [Template.Variant] {
        var result: [Template.Variant] = []

        for isInverted in inverts ? [false, true] : [false] {
            for transposition in [nil] + transpositions.map(Optional.some) {
                for isRetrograde in retrogrades ? [false, true] : [false] {
                    for timeFactor in [nil] + timeFactors.map(Optional.some) {
                        result.append(Template.Variant(isInverted: isInverted,
                                                       isRetrograde: isRetrograde,
                                                       timeFactor: timeFactor,
                                                       transposition: transposition))
                    }
                }
            }
        }

        return result
    }

    // MARK: Internal Instance Methods

    internal func validate() throws(Template.Error) {
        guard Set(timeFactors).count == timeFactors.count,
              Set(transpositions).count == transpositions.count,
              timeFactors.allSatisfy({ $0.isRational && $0 > 0 && $0 != 1 }),
              !transpositions.contains(where: \.isUnison)
        else { throw .invalidVariants }
    }
}

// MARK: - Codable

extension Template.AnalysisOptions.Variants: Codable {
}

// MARK: - Hashable

extension Template.AnalysisOptions.Variants: Hashable {
}

// MARK: - Sendable

extension Template.AnalysisOptions.Variants: Sendable {
}
