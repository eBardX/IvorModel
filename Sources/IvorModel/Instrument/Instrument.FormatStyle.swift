// © 2025–2026 John Gary Pusey (see LICENSE.md)

public import Foundation

extension Instrument {

    // MARK: Public Nested Types

    /// A format style that produces an attributed string representation of an ``Instrument`` value.
    public struct FormatStyle {

        // MARK: Public Initializers

        /// Creates a format style with the given locale.
        ///
        /// - Parameter locale:     The locale to use for formatting. Defaults to `.autoupdatingCurrent`.
        public init(locale: Locale = .autoupdatingCurrent) {
            self.locale = locale
        }

        // MARK: Public Instance Properties

        /// The locale used for formatting.
        public let locale: Locale
    }
}

// MARK: - FormatStyle

extension Instrument.FormatStyle: FormatStyle {

    // MARK: Public Instance Methods

    /// Returns an attributed string representation of the given instrument.
    ///
    /// - Parameter value:  The ``Instrument`` value to format.
    ///
    /// - Returns:  An `AttributedString` containing the instrument’s string value.
    public func format(_ value: Instrument) -> AttributedString {
        AttributedString(value.stringValue)
    }
}

// MARK: -

extension Instrument {
    /// Returns an attributed string representation of this instrument using the default format style.
    ///
    /// - Returns:  An `AttributedString` representation of the instrument.
    public func formatted() -> AttributedString {
        FormatStyle().format(self)
    }
}
