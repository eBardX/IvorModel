// © 2026 John Gary Pusey (see LICENSE.md)

internal import IvorTiming
internal import IvorTuning

private import XestiTools

extension Part {

    // MARK: Public Nested Types

    /// Descriptive metadata about a part.
    ///
    /// The part’s full name is ``Part/name``, not part of its metadata. ``abbreviation`` has its
    /// whitespace normalized to a single line, whether it is set through the initializer, by
    /// assignment, or by decoding, and becomes `nil` if it is then empty.
    public struct Metadata {

        // MARK: Public Initializers

        /// Creates metadata for a part.
        ///
        /// - Parameter abbreviation:   The abbreviated part name. Defaults to `nil`.
        /// - Parameter remarks:        Free-form notes about the part. Defaults to none.
        public init(abbreviation: String? = nil,
                    remarks: [Remark] = []) {
            //
            // `didSet` doesn't run during initialization, so normalize here too:
            //
            self.abbreviation = abbreviation?.normalizingWhitespace().nilIfEmpty
            self.remarks = remarks
        }

        // MARK: Public Instance Properties

        /// The abbreviated part name, as printed on systems after the first (MusicXML
        /// `part-abbreviation`, ABC `V: sname=`).
        public var abbreviation: String? {
            didSet { abbreviation = abbreviation?.normalizingWhitespace().nilIfEmpty }
        }

        /// Free-form notes about this part.
        public var remarks: [Remark]

        // MARK: Internal Initializers

        //
        // Copies metadata from a part of any other specialization — needed whenever a part is
        // rebuilt with a different time or pitch type, since `Part<T, P>.Metadata` is a distinct
        // type for each specialization, though its fields depend on neither.
        //
        internal init(_ other: Part<some TimeProtocol, some PitchProtocol>.Metadata) {
            self.abbreviation = other.abbreviation
            self.remarks = other.remarks
        }
    }
}

// MARK: - Codable

extension Part.Metadata: Codable {

    // MARK: Public Initializers

    /// Creates part metadata by decoding from the provided decoder.
    ///
    /// The decoded abbreviation is normalized exactly as by the public initializer.
    ///
    /// - Parameter decoder:    The decoder to read from.
    ///
    /// - Throws:   `DecodingError` if the encoded data is invalid or corrupted.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let abbreviation = try container.decodeIfPresent(String.self,
                                                         forKey: .abbreviation)

        let remarks = try container.decode([Remark].self,
                                           forKey: .remarks)

        self.init(abbreviation: abbreviation,
                  remarks: remarks)
    }

    // MARK: Public Instance Methods

    /// Encodes this part metadata into the provided encoder.
    ///
    /// - Parameter encoder:    The encoder to write to.
    ///
    /// - Throws:   `EncodingError` if the value cannot be encoded.
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        //
        // Maintain order:
        //
        try container.encodeIfPresent(abbreviation,
                                      forKey: .abbreviation)

        try container.encode(remarks,
                             forKey: .remarks)
    }

    // MARK: Private Nested Types

    private enum CodingKeys: String, CodingKey {
        case abbreviation
        case remarks
    }
}

// MARK: - Hashable

extension Part.Metadata: Hashable {
}

// MARK: - Sendable

extension Part.Metadata: Sendable {
}
