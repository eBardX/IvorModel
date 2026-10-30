// © 2026 John Gary Pusey (see LICENSE.md)

extension Template.GenerationOptions {

    // MARK: Public Nested Types

    /// Another template’s weight in a blend — see ``TemplateMix/blend(_:)``.
    public struct Share {

        // MARK: Public Initializers

        /// Creates a new share.
        ///
        /// - Parameter template:   The other template.
        /// - Parameter weight:     Its weight. Must be above 0, and all the shares together below 1.
        public init(template: Template.OtherTemplate,
                    weight: Double) {
            self.template = template
            self.weight = weight
        }

        // MARK: Public Instance Properties

        /// The other template.
        public var template: Template.OtherTemplate

        /// Its weight, above 0. All the shares together are below 1; this template gets the rest.
        public var weight: Double
    }
}

// MARK: - Codable

extension Template.GenerationOptions.Share: Codable {
}

// MARK: - Hashable

extension Template.GenerationOptions.Share: Hashable {
}

// MARK: - Sendable

extension Template.GenerationOptions.Share: Sendable {
}
