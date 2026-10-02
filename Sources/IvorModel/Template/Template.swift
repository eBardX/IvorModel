// © 2025–2026 John Gary Pusey (see LICENSE.md)

public import IvorTiming
public import IvorTuning

private import Foundation
private import XestiMarkov
private import XestiTools

/// An analysis of a ``Work`` that captures its musical essence and can generate new, derived works.
public struct Template {

    // MARK: Public Initializers

    /// Creates a new template with the given name and content.
    ///
    /// - Parameter name:     The display name of the template. Its whitespace is normalized to
    ///                       a single line.
    /// - Parameter content:  The ``Template/Content`` holding the analysis data.
    public init(name: String,
                content: Content) {
        self.content = content
        self.isLocked = false
        self.name = name.normalizingWhitespace()
        self.templateID = TemplateID()
        self.version = Self.currentVersion
    }

    // MARK: Public Instance Properties

    /// The analysis data stored in this template.
    public let content: Content

    /// The unique ID of this template.
    public let templateID: TemplateID

    /// The file format version of this template.
    public let version: Int

    /// A Boolean value indicating whether this template is locked.
    ///
    /// A template’s ``content`` is always immutable, regardless of lock state; locking protects
    /// the template against renaming and deletion instead. ``rename(to:)`` throws
    /// ``Template/Error/templateIsLocked`` on a locked template, and
    /// ``Project/removeTemplate(_:)`` refuses to remove it. Setting `isLocked` itself is always
    /// permitted, so a locked template can always be unlocked.
    public var isLocked: Bool

    /// The display name of this template, with whitespace normalized to a single line.
    ///
    /// To change it, use ``rename(to:)``.
    public internal(set) var name: String
}

// MARK: -

extension Template {

    // MARK: Public Type Properties

    /// The current template file format version.
    public static let currentVersion = 1

    // MARK: Public Instance Properties

    /// The maximum pattern depth supported by this template.
    public var maximumOrder: Int {
        accept(_MaximumOrderVisitor())
    }

    /// Metrics describing how this template’s Markov chain was trained.
    public var metrics: Metrics {
        accept(_MetricsVisitor())
    }

    /// The pitch notation used by this template.
    public var pitchNotation: PitchNotation {
        content.pitchNotation
    }

    /// The time basis used by this template.
    public var timeBasis: TimeBasis {
        content.timeBasis
    }

    // MARK: Public Instance Methods

    /// Calls the given visitor with this template’s Markov chain, at its
    /// concrete time and pitch types.
    ///
    /// - Parameter visitor:    The visitor to call.
    ///
    /// - Returns:  The result of the visit.
    public func accept<Visitor: ContentVisitor>(_ visitor: Visitor) -> Visitor.Result {
        switch content {
        case let .absoluteBeat(markovChain):
            visitor.visit(markovChain)

        case let .absoluteWall(markovChain):
            visitor.visit(markovChain)

        case let .keyboardBeat(markovChain):
            visitor.visit(markovChain)

        case let .keyboardWall(markovChain):
            visitor.visit(markovChain)

        case let .standardBeat(markovChain):
            visitor.visit(markovChain)

        case let .standardWall(markovChain):
            visitor.visit(markovChain)
        }
    }

    /// Changes the display name of this template.
    ///
    /// - Parameter name:   The new display name. Its whitespace is normalized to a single line.
    ///
    /// - Throws:   ``Template/Error/templateIsLocked`` if this template is locked.
    public mutating func rename(to name: String) throws(Error) {
        guard !isLocked
        else { throw Error.templateIsLocked }

        self.name = name.normalizingWhitespace()
    }

    // MARK: Private Nested Types

    private struct _MaximumOrderVisitor: ContentVisitor {
        func visit(_ markovChain: MarkovChain<NoteEvent<some TimeProtocol, some PitchProtocol>>) -> Int {
            markovChain.maximumOrder
        }
    }

    private struct _MetricsVisitor: ContentVisitor {
        func visit(_ markovChain: MarkovChain<NoteEvent<some TimeProtocol, some PitchProtocol>>) -> Metrics {
            let metrics = markovChain.metrics()
            let order = markovChain.maximumOrder
            let orderMetrics = metrics.orderMetrics[order]

            return Metrics(branchingRatio: orderMetrics.branchingRatio,
                           order: order,
                           recommendedOrder: metrics.recommendedOrder,
                           stateCount: metrics.distinctStates,
                           transitionCount: orderMetrics.totalTransitions)
        }
    }
}

// MARK: - Codable

extension Template: Codable {

    // MARK: Public Initializers

    /// Creates a template by decoding from the provided decoder.
    ///
    /// - Parameter decoder:    The decoder to read from.
    ///
    /// - Throws:   `DecodingError` if the encoded data is invalid or corrupted;
    ///             otherwise, ``Template/Error/unsupportedVersion(_:)`` if the version is
    ///             not supported.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.content = try container.decode(Content.self,
                                            forKey: .content)

        self.isLocked = try container.decode(Bool.self,
                                             forKey: .isLocked)

        self.name = try container.decode(String.self,
                                         forKey: .name).normalizingWhitespace()

        self.templateID = try container.decode(TemplateID.self,
                                               forKey: .templateID)

        self.version = try container.decode(Int.self,
                                            forKey: .version)

        guard version == Self.currentVersion
        else { throw Error.unsupportedVersion(version) }
    }

    // MARK: Public Instance Methods

    /// Encodes this template into the provided encoder.
    ///
    /// - Parameter encoder:    The encoder to write to.
    ///
    /// - Throws:   `EncodingError` if the value cannot be encoded.
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        //
        // Maintain order:
        //
        try container.encode(templateID,
                             forKey: .templateID)

        try container.encode(version,
                             forKey: .version)

        try container.encode(isLocked,
                             forKey: .isLocked)

        try container.encode(name,
                             forKey: .name)

        try container.encode(content,
                             forKey: .content)
    }

    // MARK: Private Nested Types

    private enum CodingKeys: String, CodingKey {
        case content
        case isLocked
        case name
        case templateID
        case version
    }
}

// MARK: - Comparable

extension Template: Comparable {

    // MARK: Public Type Methods

    /// Returns a Boolean value indicating whether the left template compares less than the right.
    ///
    /// - Parameter lhs:    The left-hand template.
    /// - Parameter rhs:    The right-hand template.
    ///
    /// - Returns:  `true` if `lhs` precedes `rhs` when ordered by name then template ID.
    public static func < (lhs: Self,
                          rhs: Self) -> Bool {
        (lhs.name, lhs.templateID) < (rhs.name, rhs.templateID)
    }
}

// MARK: - Equatable

extension Template: Equatable {

    // MARK: Public Type Methods

    /// Returns a Boolean value indicating whether two templates are equal.
    ///
    /// - Parameter lhs:    The left-hand template.
    /// - Parameter rhs:    The right-hand template.
    ///
    /// - Returns:  `true` if both templates have the same name and template ID.
    public static func == (lhs: Self,
                           rhs: Self) -> Bool {
        (lhs.name, lhs.templateID) == (rhs.name, rhs.templateID)
    }
}

// MARK: - Sendable

extension Template: Sendable {
}
