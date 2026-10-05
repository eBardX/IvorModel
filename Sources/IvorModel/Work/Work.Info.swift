// © 2026 John Gary Pusey (see LICENSE.md)

private import XestiTools

extension Work {

    // MARK: Public Nested Types

    /// Descriptive information about a work: its titles, dedication, credits, rights, and remarks.
    ///
    /// Every title has its whitespace normalized to a single line, whether it is set through the
    /// initializer, by assignment, or by decoding. An optional title that is empty once
    /// normalized becomes `nil`, and an element of ``subtitles`` or ``alternateTitles`` that is
    /// empty once normalized is removed. The ``dedication`` is normalized the same way, except
    /// line by line, so its line breaks are kept.
    public struct Info {

        // MARK: Public Initializers

        /// Creates descriptive information for a work.
        ///
        /// - Parameter title:              The main title of the work. Defaults to `nil`.
        /// - Parameter subtitles:          Subtitles, in display order. Defaults to none.
        /// - Parameter alternateTitles:    Alternate titles the work is also known by. Defaults
        ///                                 to none.
        /// - Parameter parentWorkTitle:    The title of the larger work this one belongs to.
        ///                                 Defaults to `nil`.
        /// - Parameter dedication:         To whom or what the work is dedicated. Defaults to
        ///                                 `nil`.
        /// - Parameter credits:            The people credited with the work, in source order.
        ///                                 Defaults to none.
        /// - Parameter rights:             Copyright and other rights notices, in source order.
        ///                                 Defaults to none.
        /// - Parameter remarks:            Free-form notes about the work. Defaults to none.
        public init(title: String? = nil,
                    subtitles: [String] = [],
                    alternateTitles: [String] = [],
                    parentWorkTitle: String? = nil,
                    dedication: String? = nil,
                    credits: [Credit] = [],
                    rights: [RightsNotice] = [],
                    remarks: [Remark] = []) {
            //
            // `didSet` doesn't run during initialization, so normalize here too:
            //
            self.alternateTitles = Self._normalized(alternateTitles)
            self.credits = credits
            self.dedication = Self._normalizedDedication(dedication)
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

        /// To whom or what the work is dedicated (e.g. `"To my teacher, R. Jones"`), or `nil`,
        /// with whitespace normalized line by line, so its line breaks are kept.
        public var dedication: String? {
            didSet { dedication = Self._normalizedDedication(dedication) }
        }

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

extension Work.Info {

    // MARK: Public Instance Properties

    /// The names credited as composers, in order.
    public var composers: [String] {
        credits.filter { $0.role == .composer }.map(\.name)
    }

    // MARK: Private Type Methods

    private static func _normalized(_ titles: [String]) -> [String] {
        titles.compactMap { $0.normalizingWhitespace().nilIfEmpty }
    }

    private static func _normalizedDedication(_ dedication: String?) -> String? {
        dedication?.normalizingWhitespace(lineByLine: true).nilIfEmpty
    }
}

// MARK: - Codable

extension Work.Info: Codable {

    // MARK: Public Initializers

    /// Creates work information by decoding from the provided decoder.
    ///
    /// Every decoded title, and the dedication, is normalized exactly as by the public initializer.
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

        let dedication = try container.decodeIfPresent(String.self,
                                                       forKey: .dedication)

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
                  dedication: dedication,
                  credits: credits,
                  rights: rights,
                  remarks: remarks)
    }

    // MARK: Public Instance Methods

    /// Encodes this work information into the provided encoder.
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

        try container.encodeIfPresent(dedication,
                                      forKey: .dedication)

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
        case dedication
        case parentWorkTitle
        case remarks
        case rights
        case subtitles
        case title
    }
}

// MARK: - Hashable

extension Work.Info: Hashable {
}

// MARK: - Sendable

extension Work.Info: Sendable {
}
