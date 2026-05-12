public import XestiNumbers

public struct Position: NumberRepresentable {   // Pan (stereo) or Location (3D) ???

    // MARK: Public Type Properties

    public static let left   = Self(-1)
    public static let center = Self(0)
    public static let right  = Self(1)

    // MARK: Public Type Methods

    public static func isValid(_ numberValue: Number) -> Bool {
        numberValue.isRational && (-1...1) ~= numberValue
    }

    // MARK: Public Initializers

    public init?(numberValue: Number) {
        guard Self.isValid(numberValue)
        else { return nil }

        self.numberValue = numberValue
    }

    // MARK: Public Instance Properties

    public let numberValue: Number
}
