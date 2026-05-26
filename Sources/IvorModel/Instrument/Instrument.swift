// © 2025–2026 John Gary Pusey (see LICENSE.md)

public import XestiTools

/// An instrument designation represented as a validated string.
public struct Instrument: StringRepresentable {

    // MARK: Public Type Properties

    /// The default instrument.
    public static let vanilla = Self("Vanilla")

    // MARK: Public Initializers

    /// Creates an instrument from a string value, returning `nil` if the string is invalid.
    ///
    /// - Parameter stringValue:    The string designating the instrument.
    public init?(stringValue: String) {
        guard Self.isValid(stringValue)
        else { return nil }

        self.stringValue = stringValue
    }

    // MARK: Public Instance Properties

    /// The string value designating this instrument.
    public let stringValue: String
}
