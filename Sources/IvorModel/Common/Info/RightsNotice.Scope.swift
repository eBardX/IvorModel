// © 2026 John Gary Pusey (see LICENSE.md)

public import XestiTools

extension RightsNotice {

    // MARK: Public Nested Types

    /// The part of a work that a rights notice covers.
    ///
    /// The standard scopes are available as type properties. Any other scope can be created from
    /// its string value.
    public struct Scope {

        // MARK: Public Initializers

        /// Creates a scope from a string value, returning `nil` if the string is invalid.
        ///
        /// - Parameter stringValue:    The string naming the scope. It must be non-empty and have
        ///                             its whitespace already normalized to a single line.
        public init?(stringValue: String) {
            guard Self.isValid(stringValue)
            else { return nil }

            self.stringValue = stringValue
        }

        // MARK: Public Instance Properties

        /// The string value naming this scope.
        public let stringValue: String
    }
}

// MARK: -

extension RightsNotice.Scope {

    // MARK: Public Type Properties

    /// The notice covers an arrangement of the work.
    public static let arrangement = Self("arrangement")

    /// The notice covers the music of the work.
    public static let music = Self("music")

    /// The notice covers a transcription of the work, such as an ABC
    /// `Z:abc-copyright` field.
    public static let transcription = Self("transcription")

    /// The notice covers the words of the work.
    public static let words = Self("words")
}

// MARK: - StringRepresentable

extension RightsNotice.Scope: StringRepresentable {

    // MARK: Public Type Methods

    /// Returns a Boolean value indicating whether the provided string value is a valid scope.
    ///
    /// A valid scope is non-empty and already has its whitespace normalized to a single line, so
    /// that `" music"` can’t produce a scope that looks like ``music`` but isn’t equal to it.
    ///
    /// - Parameter stringValue:    The string value to check for validity.
    ///
    /// - Returns:  `true` if `stringValue` is a valid scope; `false` otherwise.
    public static func isValid(_ stringValue: String) -> Bool {
        !stringValue.isEmpty && stringValue == stringValue.normalizingWhitespace()
    }
}
