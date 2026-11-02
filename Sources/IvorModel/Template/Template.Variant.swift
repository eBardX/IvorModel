// © 2026 John Gary Pusey (see LICENSE.md)

public import XestiNumbers

extension Template {

    // MARK: Public Nested Types

    /// One transformed form of the part a template was analyzed from — see
    /// ``AnalysisOptions/Variants``.
    public struct Variant {

        // MARK: Public Instance Properties

        /// A Boolean value indicating whether the form is inverted.
        public let isInverted: Bool

        /// A Boolean value indicating whether the form is in retrograde.
        public let isRetrograde: Bool

        /// The form’s time factor, or `nil` for ×1.
        public let timeFactor: Number?

        /// The form’s transposition, or `nil` for none.
        public let transposition: AnalysisOptions.Transposition?

        // MARK: Internal Initializers

        internal init(isInverted: Bool,
                      isRetrograde: Bool,
                      timeFactor: Number?,
                      transposition: AnalysisOptions.Transposition?) {
            self.isInverted = isInverted
            self.isRetrograde = isRetrograde
            self.timeFactor = timeFactor
            self.transposition = transposition
        }
    }
}

// MARK: - Codable

extension Template.Variant: Codable {
}

// MARK: - Hashable

extension Template.Variant: Hashable {
}

// MARK: - Sendable

extension Template.Variant: Sendable {
}
