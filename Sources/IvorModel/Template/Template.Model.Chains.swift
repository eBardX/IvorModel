// © 2026 John Gary Pusey (see LICENSE.md)

public import XestiMarkov

extension Template.Model {

    // MARK: Public Nested Types

    /// A model’s Markov chains: one joint chain, or a duration chain and a pitch chain.
    public enum Chains {
        /// One chain whose states record each event’s pitches and duration together.
        case joint(MarkovChain<Template.State<TimeType, PitchType>>)

        /// A duration chain, whose states record every event’s duration and whether it is a
        /// rest, and a pitch chain, whose states record the pitches of the sounding events. Both
        /// have the same maximum order.
        case separate(duration: MarkovChain<Template.State<TimeType, PitchType>>,
                      pitch: MarkovChain<Template.State<TimeType, PitchType>>)
    }
}

// MARK: -

extension Template.Model.Chains {

    // MARK: Public Instance Properties

    /// The maximum pattern depth of the chains.
    public var maximumOrder: Int {
        switch self {
        case let .joint(markovChain):
            markovChain.maximumOrder

        case let .separate(duration, pitch):
            max(duration.maximumOrder, pitch.maximumOrder)
        }
    }

    /// The roles of the chains: ``Template/ChainRole/joint`` alone, or
    /// ``Template/ChainRole/duration`` then ``Template/ChainRole/pitch``.
    public var roles: [Template.ChainRole] {
        switch self {
        case .joint:
            [.joint]

        case .separate:
            [.duration, .pitch]
        }
    }

    // MARK: Public Instance Methods

    /// Returns the chain with the given role.
    ///
    /// - Parameter role:   The role of the chain to return.
    ///
    /// - Returns:  The chain with `role`, or `nil` if there is none.
    public func chain(for role: Template.ChainRole) -> MarkovChain<Template.State<TimeType, PitchType>>? {
        switch (self, role) {
        case let (.joint(markovChain), .joint):
            markovChain

        case let (.separate(duration, _), .duration):
            duration

        case let (.separate(_, pitch), .pitch):
            pitch

        default:
            nil
        }
    }
}

// MARK: - Codable

extension Template.Model.Chains: Codable {
}

// MARK: - Sendable

extension Template.Model.Chains: Sendable {
}
