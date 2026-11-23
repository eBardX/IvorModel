// © 2026 John Gary Pusey (see LICENSE.md)

public import IvorTiming

extension FermataRules {

    // MARK: Public Nested Types

    /// How much longer a fermata’s held span lasts, in time-neutral units: the cases of
    /// ``FermataExecution/Hold`` that need no converting between beat and wall time.
    public enum Hold {

        /// The span lasts this many seconds longer (at the local tempo in a beat work).
        case seconds(PositiveDuration<WallDuration>)

        /// The span lasts this factor times its written length.
        case stretch(FermataStretch)
    }
}

// MARK: - Codable

extension FermataRules.Hold: Codable {

    // MARK: Public Initializers

    /// Creates a hold by decoding its one case, `{"seconds": s}` or `{"stretch": f}`.
    ///
    /// - Parameter decoder:    The decoder to read from.
    ///
    /// - Throws:   `DecodingError` if the encoded data is invalid or corrupted.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CaseCodingKey.self)
        let key = try CaseCodingKey.caseKey(of: container, typeName: "FermataRules.Hold")

        switch key.stringValue {
        case Self.secondsKey:
            self = try .seconds(container.decode(PositiveDuration<WallDuration>.self, forKey: key))

        case Self.stretchKey:
            self = try .stretch(container.decode(FermataStretch.self, forKey: key))

        default:
            throw CaseCodingKey.unknownCase(key, in: container, typeName: "FermataRules.Hold")
        }
    }

    // MARK: Public Instance Methods

    /// Encodes this hold as its one case, `{"seconds": s}` or `{"stretch": f}`.
    ///
    /// - Parameter encoder:    The encoder to write to.
    ///
    /// - Throws:   `EncodingError` if the value cannot be encoded.
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CaseCodingKey.self)

        switch self {
        case let .seconds(duration):
            try container.encode(duration, forKey: CaseCodingKey(Self.secondsKey))

        case let .stretch(stretch):
            try container.encode(stretch, forKey: CaseCodingKey(Self.stretchKey))
        }
    }

    // MARK: Private Type Properties

    private static var secondsKey: String {
        "seconds"
    }

    private static var stretchKey: String {
        "stretch"
    }
}

// MARK: - Hashable

extension FermataRules.Hold: Hashable {
}

// MARK: - Sendable

extension FermataRules.Hold: Sendable {
}
