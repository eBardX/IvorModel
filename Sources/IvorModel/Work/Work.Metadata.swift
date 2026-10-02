// © 2026 John Gary Pusey (see LICENSE.md)

private import XestiTools

extension Work {

    // MARK: Public Nested Types

    /// Descriptive metadata about a work: its titles, credits, rights, and remarks.
    ///
    /// Every title has its whitespace normalized to a single line, whether it is set through the
    /// initializer, by assignment, or by decoding. An optional title that is empty once
    /// normalized becomes `nil`, and an element of ``subtitles`` or ``alternateTitles`` that is
    /// empty once normalized is removed.
    public struct Metadata {

        // MARK: Public Initializers

        /// Creates metadata for a work.
        ///
        /// - Parameter title:              The main title of the work. Defaults to `nil`.
        /// - Parameter subtitles:          Subtitles, in display order. Defaults to none.
        /// - Parameter alternateTitles:    Alternate titles the work is also known by. Defaults
        ///                                 to none.
        /// - Parameter parentWorkTitle:    The title of the larger work this one belongs to.
        ///                                 Defaults to `nil`.
        /// - Parameter credits:            The people credited with the work, in source order.
        ///                                 Defaults to none.
        /// - Parameter rights:             Copyright and other rights notices, in source order.
        ///                                 Defaults to none.
        /// - Parameter remarks:            Free-form notes about the work. Defaults to none.
        public init(title: String? = nil,
                    subtitles: [String] = [],
                    alternateTitles: [String] = [],
                    parentWorkTitle: String? = nil,
                    credits: [Credit] = [],
                    rights: [RightsNotice] = [],
                    remarks: [Remark] = []) {
            //
            // `didSet` doesn't run during initialization, so normalize here too:
            //
            self.alternateTitles = Self._normalized(alternateTitles)
            self.credits = credits
            self.parentWorkTitle = parentWorkTitle?.normalizingWhitespace().nilIfEmpty
            self.remarks = remarks
            self.rights = rights
            self.subtitles = Self._normalized(subtitles)
            self.title = title?.normalizingWhitespace().nilIfEmpty
        }

        // MARK: Public Instance Properties

        /// Alternate titles the work is also known by (ABC 2.1 §3.1.2 calls these “alternative
        /// titles”).
        public var alternateTitles: [String] {
            didSet { alternateTitles = Self._normalized(alternateTitles) }
        }

        /// The people credited with the work, in source order.
        public var credits: [Credit]

        /// The title of the larger work this one belongs to, such as the symphony that a movement
        /// comes from (MusicXML `work-title` when a `movement-title` is also present).
        public var parentWorkTitle: String? {
            didSet { parentWorkTitle = parentWorkTitle?.normalizingWhitespace().nilIfEmpty }
        }

        /// Free-form notes about the work.
        public var remarks: [Remark]

        /// Copyright and other rights notices, in source order.
        public var rights: [RightsNotice]

        /// Subtitles, in display order.
        public var subtitles: [String] {
            didSet { subtitles = Self._normalized(subtitles) }
        }

        /// The main title of the work.
        public var title: String? {
            didSet { title = title?.normalizingWhitespace().nilIfEmpty }
        }
    }
}

// MARK: -

extension Work.Metadata {

    // MARK: Public Instance Properties

    /// The names credited as composers, in order.
    public var composers: [String] {
        credits.filter { $0.role == .composer }.map(\.name)
    }

    // MARK: Private Type Methods

    private static func _normalized(_ titles: [String]) -> [String] {
        titles.compactMap { $0.normalizingWhitespace().nilIfEmpty }
    }
}

// MARK: - Codable

extension Work.Metadata: Codable {

    // MARK: Public Initializers

    /// Creates work metadata by decoding from the provided decoder.
    ///
    /// Every decoded title is normalized exactly as by the public initializer.
    ///
    /// - Parameter decoder:    The decoder to read from.
    ///
    /// - Throws:   `DecodingError` if the encoded data is invalid or corrupted.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let alternateTitles = try container.decode([String].self,
                                                   forKey: .alternateTitles)

        let credits = try container.decode([Credit].self,
                                           forKey: .credits)

        let parentWorkTitle = try container.decodeIfPresent(String.self,
                                                            forKey: .parentWorkTitle)

        let remarks = try container.decode([Remark].self,
                                           forKey: .remarks)

        let rights = try container.decode([RightsNotice].self,
                                          forKey: .rights)

        let subtitles = try container.decode([String].self,
                                             forKey: .subtitles)

        let title = try container.decodeIfPresent(String.self,
                                                  forKey: .title)

        self.init(title: title,
                  subtitles: subtitles,
                  alternateTitles: alternateTitles,
                  parentWorkTitle: parentWorkTitle,
                  credits: credits,
                  rights: rights,
                  remarks: remarks)
    }

    // MARK: Public Instance Methods

    /// Encodes this work metadata into the provided encoder.
    ///
    /// - Parameter encoder:    The encoder to write to.
    ///
    /// - Throws:   `EncodingError` if the value cannot be encoded.
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        //
        // Maintain order:
        //
        try container.encodeIfPresent(title,
                                      forKey: .title)

        try container.encode(subtitles,
                             forKey: .subtitles)

        try container.encode(alternateTitles,
                             forKey: .alternateTitles)

        try container.encodeIfPresent(parentWorkTitle,
                                      forKey: .parentWorkTitle)

        try container.encode(credits,
                             forKey: .credits)

        try container.encode(rights,
                             forKey: .rights)

        try container.encode(remarks,
                             forKey: .remarks)
    }

    // MARK: Private Nested Types

    private enum CodingKeys: String, CodingKey {
        case alternateTitles
        case credits
        case parentWorkTitle
        case remarks
        case rights
        case subtitles
        case title
    }
}

// MARK: - Hashable

extension Work.Metadata: Hashable {
}

// MARK: - Sendable

extension Work.Metadata: Sendable {
}
