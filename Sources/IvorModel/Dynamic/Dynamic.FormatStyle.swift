// © 2025–2026 John Gary Pusey (see LICENSE.md)

public import Foundation

private import XestiNumbers

extension Dynamic {

    // MARK: Public Nested Types

    /// A format style that produces an attributed string representation of a ``Dynamic`` value.
    public struct FormatStyle {

        // MARK: Public Initializers

        /// Creates a format style with the given locale.
        ///
        /// - Parameter locale:     The locale to use for formatting. Defaults to `.autoupdatingCurrent`.
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

extension Dynamic.FormatStyle: FormatStyle {

    // MARK: Public Instance Methods

    /// Returns an attributed string representation of the given dynamic level.
    ///
    /// - Parameter value:  The ``Dynamic`` value to format.
    ///
    /// - Returns:  An `AttributedString` representation of the dynamic level's numeric value.
    public func format(_ value: Dynamic) -> AttributedString {
        baseStyle.format(value.numberValue)
    }
}

// MARK: -

extension Dynamic {
    /// Returns an attributed string representation of this dynamic level using the default format style.
    ///
    /// - Returns:  An `AttributedString` representation of the dynamic level.
    public func formatted() -> AttributedString {
        FormatStyle().format(self)
    }
}
