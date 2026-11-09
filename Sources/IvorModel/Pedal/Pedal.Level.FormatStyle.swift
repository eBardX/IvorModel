// © 2026 John Gary Pusey (see LICENSE.md)

public import Foundation

private import XestiNumbers

extension Pedal.Level {

    // MARK: Public Nested Types

    /// A format style that produces an attributed string representation of a ``Pedal/Level``
    /// value.
    public struct FormatStyle {

        // MARK: Public Initializers

        /// Creates a format style with the given locale.
        ///
        /// - Parameter locale: The locale to use for formatting. Defaults to `.autoupdatingCurrent`.
        public init(locale: Locale = .autoupdatingCurrent) {
            self.baseStyle = Number.FormatStyle(locale: locale)
                .decimalPrecision(0...3)
                .fractionDisplay(strategy: .simple(alwaysShowDenominator: false))
                .attributed
            self.locale = locale
        }

        // MARK: Public Instance Properties

        /// The locale used for formatting.
        public let locale: Locale

        // MARK: Private Instance Properties

        private let baseStyle: Number.FormatStyle.Attributed
    }
}

// MARK: - FormatStyle

extension Pedal.Level.FormatStyle: FormatStyle {

    // MARK: Public Instance Methods

    /// Returns an attributed string representation of the given pedal level.
    ///
    /// - Parameter value:  The ``Pedal/Level`` value to format.
    ///
    /// - Returns:  An `AttributedString` representation of the pedal level’s numeric value.
    public func format(_ value: Pedal.Level) -> AttributedString {
        baseStyle.format(value.numberValue)
    }
}

// MARK: -

extension Pedal.Level {

    // MARK: Public Instance Methods

    /// Returns an attributed string representation of this pedal level using the default format
    /// style.
    ///
    /// - Returns:  An `AttributedString` representation of the pedal level.
    public func formatted() -> AttributedString {
        FormatStyle().format(self)
    }
}
