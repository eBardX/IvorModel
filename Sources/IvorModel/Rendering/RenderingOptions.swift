// © 2026 John Gary Pusey (see LICENSE.md)

/// Options for rendering a work’s ornamentation into plain notes (see
/// ``Work/rendered(options:)``).
public struct RenderingOptions {

    // MARK: Public Initializers

    /// Creates rendering options.
    ///
    /// - Parameter fermataMode:    How fermata holds and caesura pauses are rendered. Defaults to
    ///                             ``FermataMode/tempoChanges``.
    public init(fermataMode: FermataMode = .tempoChanges) {
        self.fermataMode = fermataMode
    }

    // MARK: Public Instance Properties

    /// How fermata holds and caesura pauses are rendered.
    public let fermataMode: FermataMode
}

// MARK: - Equatable

extension RenderingOptions: Equatable {
}

// MARK: - Sendable

extension RenderingOptions: Sendable {
}
