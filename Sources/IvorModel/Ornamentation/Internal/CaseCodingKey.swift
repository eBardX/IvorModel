// © 2026 John Gary Pusey (see LICENSE.md)

// The one key of a single-key container that codes an enum case with a payload:
// `{"share": "1/2"}`, `{"perSecond": 12}`. A case without a payload is coded
// with `true` as its value, so every case of such an enum has the same shape.
internal struct CaseCodingKey {

    // MARK: Internal Initializers

    internal init(_ stringValue: String) {
        self.stringValue = stringValue
    }

    // MARK: Internal Instance Properties

    internal let stringValue: String
}

// MARK: -

extension CaseCodingKey {

    // MARK: Internal Type Methods

    // The case key of a single-key container, or a `dataCorrupted` error if the
    // container holds no key or more than one.
    internal static func caseKey(of container: KeyedDecodingContainer<Self>,
                                 typeName: String) throws -> Self {
        guard container.allKeys.count == 1,
              let key = container.allKeys.first
        else { throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: container.codingPath,
                                                                       debugDescription: "Expected exactly one case of \(typeName)")) }

        return key
    }

    // A `dataCorrupted` error for a case key that `typeName` doesn't have.
    internal static func unknownCase(_ key: Self,
                                     in container: KeyedDecodingContainer<Self>,
                                     typeName: String) -> DecodingError {
        DecodingError.dataCorrupted(DecodingError.Context(codingPath: container.codingPath + [key],
                                                          debugDescription: "Unknown case of \(typeName): \(key.stringValue)"))
    }
}

// MARK: - CodingKey

extension CaseCodingKey: CodingKey {

    // MARK: Internal Initializers

    internal init?(intValue: Int) {
        nil
    }

    internal init?(stringValue: String) {
        self.init(stringValue)
    }

    // MARK: Internal Instance Properties

    internal var intValue: Int? {
        nil
    }
}
