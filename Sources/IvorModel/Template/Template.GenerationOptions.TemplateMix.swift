// © 2026 John Gary Pusey (see LICENSE.md)

extension Template.GenerationOptions {

    // MARK: Public Nested Types

    /// A way of generating from other templates together with this one.
    ///
    /// The other templates must have this template’s pitch notation, time basis and state recipe,
    /// and be able to generate at the recipe’s orders; their tolerances may differ. Templates with
    /// no states in common don’t mix: generation stays in whichever one knows the current context.
    /// A mix can’t be combined with ``Template/GenerationOptions/mixing``, which mixes orders.
    public enum TemplateMix {
        /// Blends the other templates with this one at fixed weights. Each share is another
        /// template’s weight; this template gets what’s left. For example, a share of 0.4 is 60%
        /// this template and 40% the other.
        case blend([Share])

        /// Morphs from this template to another over the given number of note events, following
        /// the given curve.
        case morph(to: Template.OtherTemplate, over: Int, curve: Template.MorphCurve)
    }
}

// MARK: -

extension Template.GenerationOptions.TemplateMix {

    // MARK: Public Instance Properties

    /// The other templates the mix uses, in order.
    public var otherTemplates: [Template.OtherTemplate] {
        switch self {
        case let .blend(shares):
            shares.map(\.template)

        case let .morph(other, _, _):
            [other]
        }
    }

    // MARK: Internal Instance Methods

    internal func validate() throws(Template.Error) {
        switch self {
        case let .blend(shares):
            let total = shares.reduce(0) { $0 + $1.weight }

            guard !shares.isEmpty,
                  shares.allSatisfy({ $0.weight.isFinite && $0.weight > 0 }),
                  total < 1
            else { throw .invalidMixing }

        case let .morph(_, steps, curve):
            guard steps > 0,
                  curve.isValid
            else { throw .invalidMixing }
        }
    }
}

// MARK: - Codable

extension Template.GenerationOptions.TemplateMix: Codable {
}

// MARK: - Hashable

extension Template.GenerationOptions.TemplateMix: Hashable {
}

// MARK: - Sendable

extension Template.GenerationOptions.TemplateMix: Sendable {
}
