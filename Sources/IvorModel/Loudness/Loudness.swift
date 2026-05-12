public import XestiNumbers

public struct Loudness: NumberRepresentable {    // Volume or Dynamic ???

    // MARK: Public Type Properties

    public static let ffff = Self(Number(numerator: 10,
                                         denominator: 10))
    public static let fff  = Self(Number(numerator: 9,
                                         denominator: 10))
    public static let ff   = Self(Number(numerator: 8,
                                         denominator: 10))
    public static let f    = Self(Number(numerator: 7,
                                         denominator: 10))
    public static let mf   = Self(Number(numerator: 6,
                                         denominator: 10))
    public static let mp   = Self(Number(numerator: 5,
                                         denominator: 10))
    public static let p    = Self(Number(numerator: 4,
                                         denominator: 10))
    public static let pp   = Self(Number(numerator: 3,
                                         denominator: 10))
    public static let ppp  = Self(Number(numerator: 2,
                                         denominator: 10))
    public static let pppp = Self(Number(numerator: 1,
                                         denominator: 10))

    // MARK: Public Type Methods

    public static func isValid(_ numberValue: Number) -> Bool {
        numberValue.isRational && (0...1) ~= numberValue
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
