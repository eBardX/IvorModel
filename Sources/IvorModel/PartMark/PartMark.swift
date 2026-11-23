// © 2026 John Gary Pusey (see LICENSE.md)

public import IvorTiming
public import XestiNumbers

/// A sign in a part that stops the music but isn’t on a note: a fermata over a rest or a bar
/// line, or over a span the composer picks, and a caesura.
///
/// With the fermatas on notes, part marks are the only way a part affects the work’s timeline:
/// rendering turns fermata holds and caesura pauses into time that every part waits for.
public enum PartMark<TimeType: TimeProtocol> {

    /// A caesura: a moment at which every part pauses. It has no span. Its execution, if any,
    /// gives the pause; `nil` follows the rules.
    case caesura(CaesuraExecution<TimeType>?)

    /// A fermata held over `span`, from the mark’s time. A fermata over a bar line spans the last
    /// event before it.
    case fermata(Fermata<TimeType>, span: PositiveDuration<TimeType.DurationType>)
}

// MARK: -

extension PartMark {

    // MARK: Public Instance Properties

    /// The span a fermata is held over, or `nil` for a caesura, which is a moment.
    public var span: TimeType.DurationType? {
        switch self {
        case .caesura:
            nil

        case let .fermata(_, span):
            span.duration
        }
    }

    // MARK: Public Instance Methods

    /// Returns this mark with its lengths in the work’s own time — a fermata’s span, and any
    /// added hold or pause — scaled by a factor, or `nil` if a scaled length is zero or can’t be
    /// computed.
    ///
    /// - Parameter factor: The factor, such as `2` for an augmentation.
    ///
    /// - Returns:  The scaled mark, or `nil`.
    public func scaled(by factor: Number) -> Self? {
        switch self {
        case let .caesura(execution):
            guard let execution
            else { return self }

            return execution.scaled(by: factor).map { .caesura($0) }

        case let .fermata(fermata, span):
            guard let fermata = fermata.scaled(by: factor),
                  let span = span.scaled(by: factor)
            else { return nil }

            return .fermata(fermata, span: span)
        }
    }

    /// Returns this mark with a fermata’s span replaced, or the mark unchanged if it is a
    /// caesura.
    ///
    /// - Parameter span:   The new span.
    ///
    /// - Returns:  The mark with its new span.
    public func withSpan(_ span: PositiveDuration<TimeType.DurationType>) -> Self {
        switch self {
        case .caesura:
            self

        case let .fermata(fermata, _):
            .fermata(fermata, span: span)
        }
    }
}

// MARK: - Codable

extension PartMark: Codable {

    // MARK: Public Initializers

    /// Creates a mark by decoding its one case: `{"caesura": true}`, `{"caesura": {…}}` with an
    /// execution, or `{"fermata": [fermata, span]}`.
    ///
    /// - Parameter decoder:    The decoder to read from.
    ///
    /// - Throws:   `DecodingError` if the encoded data is invalid or corrupted.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CaseCodingKey.self)
        let key = try CaseCodingKey.caseKey(of: container, typeName: "PartMark")

        switch key.stringValue {
        case Self.caesuraKey:
            if let flag = try? container.decode(Bool.self, forKey: key) {
                guard flag
                else { throw DecodingError.dataCorruptedError(forKey: key,
                                                              in: container,
                                                              debugDescription: "Expected true or a caesura execution") }

                self = .caesura(nil)
            } else {
                self = try .caesura(container.decode(CaesuraExecution<TimeType>.self, forKey: key))
            }

        case Self.fermataKey:
            var fermata = try container.nestedUnkeyedContainer(forKey: key)

            self = try .fermata(fermata.decode(Fermata<TimeType>.self),
                                span: fermata.decode(PositiveDuration<TimeType.DurationType>.self))

        default:
            throw CaseCodingKey.unknownCase(key, in: container, typeName: "PartMark")
        }
    }

    // MARK: Public Instance Methods

    /// Encodes this mark as its one case: `{"caesura": true}`, `{"caesura": {…}}` with an
    /// execution, or `{"fermata": [fermata, span]}`.
    ///
    /// - Parameter encoder:    The encoder to write to.
    ///
    /// - Throws:   `EncodingError` if the value cannot be encoded.
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CaseCodingKey.self)

        switch self {
        case let .caesura(execution):
            if let execution {
                try container.encode(execution, forKey: CaseCodingKey(Self.caesuraKey))
            } else {
                try container.encode(true, forKey: CaseCodingKey(Self.caesuraKey))
            }

        case let .fermata(fermata, span):
            var nested = container.nestedUnkeyedContainer(forKey: CaseCodingKey(Self.fermataKey))

            try nested.encode(fermata)
            try nested.encode(span)
        }
    }

    // MARK: Private Type Properties

    private static var caesuraKey: String {
        "caesura"
    }

    private static var fermataKey: String {
        "fermata"
    }
}

// MARK: - Hashable

extension PartMark: Hashable {
}

// MARK: - Sendable

extension PartMark: Sendable {
}
