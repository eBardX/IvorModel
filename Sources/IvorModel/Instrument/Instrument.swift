public import XestiTools

public struct Instrument: StringRepresentable {

    // MARK: Public Type Properties

    public static let vanilla = Self("Vanilla")

    // MARK: Public Initializers

    public init?(stringValue: String) {
        guard Self.isValid(stringValue)
        else { return nil }

        self.stringValue = stringValue
    }

    // MARK: Public Instance Properties

    public let stringValue: String
}
