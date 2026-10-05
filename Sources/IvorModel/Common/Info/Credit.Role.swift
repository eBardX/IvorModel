// © 2026 John Gary Pusey (see LICENSE.md)

public import XestiTools

extension Credit {

    // MARK: Public Nested Types

    /// A kind of creative contribution.
    ///
    /// The standard roles are available as type properties. Any other role, such as
    /// `"transcriber"` or `"editor"`, can be created from its string value.
    public struct Role {

        // MARK: Public Initializers

        /// Creates a role from a string value, returning `nil` if the string is invalid.
        ///
        /// - Parameter stringValue:    The string naming the role. It must be non-empty and have
        ///                             its whitespace already normalized to a single line.
        public init?(stringValue: String) {
            guard Self.isValid(stringValue)
            else { return nil }

            self.stringValue = stringValue
        }

        // MARK: Public Instance Properties

        /// The string value naming this role.
        public let stringValue: String
    }
}

// MARK: -

extension Credit.Role {

    // MARK: Public Type Properties

    /// The arranger of the work.
    public static let arranger = Self("arranger")

    /// The composer of the work.
    public static let composer = Self("composer")

    /// The writer of the work’s words.
    public static let lyricist = Self("lyricist")
}

// MARK: - StringRepresentable

extension Credit.Role: StringRepresentable {

    // MARK: Public Type Methods

    /// Returns a Boolean value indicating whether the provided string value is a valid role.
    ///
    /// A valid role is non-empty and already has its whitespace normalized to a single line, so
    /// that `" composer"` can’t produce a role that looks like ``composer`` but isn’t equal to it.
    ///
    /// - Parameter stringValue:    The string value to check for validity.
    ///
    /// - Returns:  `true` if `stringValue` is a valid role; `false` otherwise.
    public static func isValid(_ stringValue: String) -> Bool {
        !stringValue.isEmpty && stringValue == stringValue.normalizingWhitespace()
    }
}
