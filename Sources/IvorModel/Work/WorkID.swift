// © 2025–2026 John Gary Pusey (see LICENSE.md)

public import XestiTools

private import Foundation

/// A unique ID for a ``Work``, represented as a validated string.
public struct WorkID: StringRepresentable {

    // MARK: Public Type Methods

    /// Returns a Boolean value indicating whether the provided string is a valid work ID.
    ///
    /// - Parameter stringValue:    The string to validate.
    ///
    /// - Returns:  `true` if `stringValue` is valid; otherwise, `false`.
    public static func isValid(_ stringValue: String) -> Bool {
        stringValue.wholeMatch(of: validPattern) != nil
    }

    // MARK: Public Initializers

    /// Creates a work ID from a string value, returning `nil` if the string is invalid.
    ///
    /// - Parameter stringValue:    The string identifying the work.
    public init?(stringValue: String) {
        guard Self.isValid(stringValue)
        else { return nil }

        self.stringValue = stringValue
    }

    // MARK: Public Instance Properties

    /// The string value of this work ID.
    public let stringValue: String

    // MARK: Private Type Properties

    private nonisolated(unsafe) static let validPattern = /W\$[0-9A-Za-z]{22}/

    private static let validPrefix = "W$"
}

// MARK: - (convenience)

extension WorkID {

    // MARK: Public Initializers

    /// Creates a new, unique work ID.
    public init() {
        self.init(Self.validPrefix + UUID().base62String)
    }
}
