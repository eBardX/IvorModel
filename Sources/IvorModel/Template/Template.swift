// © 2025–2026 John Gary Pusey (see LICENSE.md)

public import IvorTiming
public import IvorTuning

private import Foundation
private import XestiMarkov
private import XestiTools

/// An analysis of a ``Work`` that captures its musical essence and can generate new, derived works.
public struct Template {

    // MARK: Public Initializers

    /// Creates a new template with the given name and content, recorded as an exact analysis
    /// at the content’s maximum order.
    ///
    /// - Parameter name:     The display name of the template. Its whitespace is normalized to
    ///                       a single line.
    /// - Parameter content:  The ``Template/Content`` holding the analysis data.
    public init(name: String,
                content: Content) {
        self.init(name: name,
                  content: content,
                  analysisOptions: AnalysisOptions(maximumOrder: Self._maximumOrder(of: content)))
    }

    /// Creates a new template with the given name and content, recording how it was analyzed.
    ///
    /// - Parameter name:               The display name of the template. Its whitespace is
    ///                                 normalized to a single line.
    /// - Parameter content:            The ``Template/Content`` holding the analysis data.
    /// - Parameter analysisOptions:    The recipe the content was analyzed with.
    /// - Parameter analysisSummary:    What the analysis made of the recipe’s variants. Defaults
    ///                                 to one sequence, with nothing merged or skipped.
    /// - Parameter sources:            The parts the template learned from. Defaults to none.
    public init(name: String,
                content: Content,
                analysisOptions: AnalysisOptions,
                analysisSummary: AnalysisSummary = AnalysisSummary(),
                sources: [Source] = []) {
        self.analysisOptions = analysisOptions
        self.analysisSummary = analysisSummary
        self.content = content
        self.sources = sources
        self.isLocked = false
        self.name = name.normalizingWhitespace()
        self.templateID = TemplateID()
        self.version = Self.currentVersion
    }

    // MARK: Public Instance Properties

    /// The recipe this template was analyzed with.
    public let analysisOptions: AnalysisOptions

    /// What the analysis made of the recipe’s variants.
    public let analysisSummary: AnalysisSummary

    /// The analysis data stored in this template.
    public let content: Content

    /// The parts this template learned from, in the order they were added.
    public let sources: [Source]

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

    /// The roles of this template’s Markov chains: ``ChainRole/joint`` alone, or
    /// ``ChainRole/duration`` then ``ChainRole/pitch``.
    public var chainRoles: [ChainRole] {
        accept(_ChainRolesVisitor())
    }

    /// The maximum pattern depth supported by this template.
    public var maximumOrder: Int {
        Self._maximumOrder(of: content)
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

    /// Calls the given visitor with this template’s model, at its concrete
    /// time and pitch types.
    ///
    /// - Parameter visitor:    The visitor to call.
    ///
    /// - Returns:  The result of the visit.
    public func accept<Visitor: ContentVisitor>(_ visitor: Visitor) -> Visitor.Result {
        switch content {
        case let .absoluteBeat(model):
            visitor.visit(model)

        case let .absoluteWall(model):
            visitor.visit(model)

        case let .keyboardBeat(model):
            visitor.visit(model)

        case let .keyboardWall(model):
            visitor.visit(model)

        case let .standardBeat(model):
            visitor.visit(model)

        case let .standardWall(model):
            visitor.visit(model)
        }
    }

    /// Returns metrics describing how this template’s Markov chain with the given role was
    /// trained.
    ///
    /// - Parameter role:   The role of the chain to describe.
    ///
    /// - Returns:  The metrics of the chain with `role`, or `nil` if this template has none.
    public func metrics(for role: ChainRole) -> Metrics? {
        accept(_MetricsVisitor(role: role))
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

    // MARK: Private Type Methods

    private static func _maximumOrder(of content: Content) -> Int {
        switch content {
        case let .absoluteBeat(model):
            model.chains.maximumOrder

        case let .absoluteWall(model):
            model.chains.maximumOrder

        case let .keyboardBeat(model):
            model.chains.maximumOrder

        case let .keyboardWall(model):
            model.chains.maximumOrder

        case let .standardBeat(model):
            model.chains.maximumOrder

        case let .standardWall(model):
            model.chains.maximumOrder
        }
    }

    // MARK: Private Nested Types

    private struct _ChainRolesVisitor: ContentVisitor {
        func visit<TimeType>(_ model: Model<TimeType, some Any>) -> [ChainRole] where TimeType.DurationType: TemplateDuration {
            model.chains.roles
        }
    }

    private struct _MetricsVisitor: ContentVisitor {
        let role: ChainRole

        func visit<TimeType>(_ model: Model<TimeType, some Any>) -> Metrics? where TimeType.DurationType: TemplateDuration {
            guard let markovChain = model.chains.chain(for: role)
            else { return nil }

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

        //
        // Checked first, so that a template saved in another format fails as unsupported rather
        // than as a missing or mismatched key — see `Project.load(from:)`, which skips it.
        //
        self.version = try container.decode(Int.self,
                                            forKey: .version)

        guard version == Self.currentVersion
        else { throw Error.unsupportedVersion(version) }

        self.analysisOptions = try container.decode(AnalysisOptions.self,
                                                    forKey: .analysisOptions)

        self.analysisSummary = try container.decode(AnalysisSummary.self,
                                                    forKey: .analysisSummary)

        self.content = try container.decode(Content.self,
                                            forKey: .content)

        self.isLocked = try container.decode(Bool.self,
                                             forKey: .isLocked)

        self.name = try container.decode(String.self,
                                         forKey: .name).normalizingWhitespace()

        self.sources = try container.decode([Source].self,
                                            forKey: .sources)

        self.templateID = try container.decode(TemplateID.self,
                                               forKey: .templateID)
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

        try container.encode(analysisOptions,
                             forKey: .analysisOptions)

        try container.encode(analysisSummary,
                             forKey: .analysisSummary)

        try container.encode(sources,
                             forKey: .sources)

        try container.encode(content,
                             forKey: .content)
    }

    // MARK: Private Nested Types

    private enum CodingKeys: String, CodingKey {
        case analysisOptions
        case analysisSummary
        case content
        case isLocked
        case name
        case sources
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
