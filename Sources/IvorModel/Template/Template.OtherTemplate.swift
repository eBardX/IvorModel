// © 2026 John Gary Pusey (see LICENSE.md)

extension Template {

    // MARK: Public Nested Types

    /// Another template that a generation recipe mixes in — see
    /// ``GenerationOptions/TemplateMix``.
    ///
    /// A recipe is a value, so it names the template rather than holding it. The name is copied,
    /// so that it still reads sensibly after the template is renamed or deleted.
    public struct OtherTemplate {

        // MARK: Public Initializers

        /// Creates a new reference to another template.
        ///
        /// - Parameter templateID:     The template’s ID.
        /// - Parameter templateName:   The template’s name, when the recipe was made.
        public init(templateID: TemplateID,
                    templateName: String) {
            self.templateID = templateID
            self.templateName = templateName
        }

        /// Creates a new reference to the given template.
        ///
        /// - Parameter template:   The template.
        public init(_ template: Template) {
            self.init(templateID: template.templateID,
                      templateName: template.name)
        }

        // MARK: Public Instance Properties

        /// The template’s ID.
        public var templateID: TemplateID

        /// The template’s name, when the recipe was made.
        public var templateName: String
    }
}

// MARK: - Codable

extension Template.OtherTemplate: Codable {
}

// MARK: - Hashable

extension Template.OtherTemplate: Hashable {
}

// MARK: - Sendable

extension Template.OtherTemplate: Sendable {
}
