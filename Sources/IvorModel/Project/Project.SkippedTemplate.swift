// © 2026 John Gary Pusey (see LICENSE.md)

extension Project {

    // MARK: Public Nested Types

    /// A template in a project’s file that couldn’t be read — saved in an older format, say — and
    /// so was left out when the project was loaded.
    ///
    /// A template can be analyzed again from its work, so it isn’t kept: saving the project drops
    /// it.
    public struct SkippedTemplate {

        // MARK: Internal Initializers

        internal init(templateID: TemplateID,
                      name: String?,
                      reason: String) {
            self.name = name
            self.reason = reason
            self.templateID = templateID
        }

        // MARK: Public Instance Properties

        /// The template’s name, if it could be read on its own; otherwise, `nil`.
        public let name: String?

        /// Why the template couldn’t be read.
        public let reason: String

        /// The template’s ID.
        public let templateID: TemplateID
    }
}

// MARK: - Hashable

extension Project.SkippedTemplate: Hashable {
}

// MARK: - Sendable

extension Project.SkippedTemplate: Sendable {
}
