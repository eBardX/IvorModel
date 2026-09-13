// © 2025–2026 John Gary Pusey (see LICENSE.md)

public import XestiTools

private import Foundation

/// A unique identity represented as a validated, prefixed string.
///
/// A conforming type need only declare its `stringValue` property, the
/// initializer that stores an already-validated string, and its two-character
/// prefix and validation pattern; `init()`, `init?(stringValue:)`, and
/// `isValid(_:)` are supplied here.
public protocol UniqueID: StringRepresentable {

    // MARK: Public Initializers

    /// Creates a new instance from a string value already known to be valid.
    ///
    /// - Parameter stringValue:    The string identifying this instance.
    init(uncheckedStringValue stringValue: String)

    // MARK: Public Type Properties

    /// The regular expression that a valid string value must wholly match.
    static var validPattern: Regex<Substring> { get }

    /// The two-character prefix identifying this type's string values.
    static var validPrefix: String { get }
}

// MARK: -

extension UniqueID {

    // MARK: Public Initializers

    /// Creates a new, unique identity.
    public init() {
        self.init(uncheckedStringValue: Self.validPrefix + UUID().base62String)
    }

    /// Creates an identity from a string value, returning `nil` if the string
    /// is invalid.
    ///
    /// - Parameter stringValue:    The string identifying this instance.
    public init?(stringValue: String) {
        guard Self.isValid(stringValue)
        else { return nil }

        self.init(uncheckedStringValue: stringValue)
    }

    // MARK: Public Type Methods

    /// Returns a Boolean value indicating whether the provided string is a
    /// valid identity.
    ///
    /// - Parameter stringValue:    The string to validate.
    ///
    /// - Returns:  `true` if `stringValue` is valid; otherwise, `false`.
    public static func isValid(_ stringValue: String) -> Bool {
        stringValue.wholeMatch(of: validPattern) != nil
    }
}
