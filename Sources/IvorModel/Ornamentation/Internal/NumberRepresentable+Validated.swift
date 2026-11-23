// © 2026 John Gary Pusey (see LICENSE.md)

internal import XestiNumbers

extension NumberRepresentable {

    // MARK: Internal Initializers

    // Decodes a number and validates it, throwing `dataCorrupted` for one out of
    // range. `NumberRepresentable`'s own decoding stops execution instead, so the
    // ornamentation values decode through this.
    internal init(validatingFrom decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let numberValue = try container.decode(Number.self)

        guard let value = Self(numberValue: numberValue)
        else { throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: decoder.codingPath,
                                                                       debugDescription: "Invalid \(Self.self): \(numberValue)")) }

        self = value
    }
}
