// © 2026 John Gary Pusey (see LICENSE.md)

extension Work {

    // MARK: Public Nested Types

    /// How a work was generated from a template: enough to generate it again, or to generate a
    /// variation with one setting changed.
    ///
    /// Generating from the same template with the same ``options`` and ``seed`` gives the same
    /// notes.
    public struct Generation {

        // MARK: Public Initializers

        /// Creates a new generation record.
        ///
        /// - Parameter templateID:     The ID of the template the work was generated from.
        /// - Parameter templateName:   The name of that template when the work was generated.
        /// - Parameter options:        The recipe the work was generated with.
        /// - Parameter seed:           The seed the work was generated with.
        public init(templateID: TemplateID,
                    templateName: String,
                    options: Template.AnyGenerationOptions,
                    seed: UInt64) {
            self.options = options
            self.seed = seed
            self.templateID = templateID
            self.templateName = templateName
        }

        // MARK: Public Instance Properties

        /// The recipe the work was generated with.
        public let options: Template.AnyGenerationOptions

        /// The seed the work was generated with.
        public let seed: UInt64

        /// The ID of the template the work was generated from. The template may since have been
        /// deleted.
        public let templateID: TemplateID

        /// The name of the template when the work was generated, for display if the template
        /// has since been renamed or deleted.
        public let templateName: String
    }
}

// MARK: - Codable

extension Work.Generation: Codable {
}

// MARK: - Hashable

extension Work.Generation: Hashable {
}

// MARK: - Sendable

extension Work.Generation: Sendable {
}
