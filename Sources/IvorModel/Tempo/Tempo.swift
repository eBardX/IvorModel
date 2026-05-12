public import XestiNumbers
public import XestiTools

public struct Tempo: UIntRepresentable {

    // MARK: Public Type Properties

    public static let `default` = Self(60)

    // MARK: Public Type Methods

    public static func isValid(_ uintValue: UInt) -> Bool {
        uintValue > 0
    }

    // MARK: Public Initializers

    public init?(uintValue: UInt) {
        guard Self.isValid(uintValue)
        else { return nil }

        self.uintValue = uintValue
    }

    // MARK: Public Instance Properties

    public let uintValue: UInt
}

// MARK: -

extension Tempo {

    // MARK: Public Instance Properties

    public var doubleValue: Double {
        Double(uintValue)
    }

    public var numberValue: Number {
        Number(uintValue)
    }
}
