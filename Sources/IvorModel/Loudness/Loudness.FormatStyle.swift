public import Foundation

private import XestiNumbers

extension  Loudness {

    // MARK: Public Nested Types

    public struct FormatStyle {

        // MARK: Public Initializers

        public init(locale: Locale = .autoupdatingCurrent) {
            self.baseStyle = Number.FormatStyle(locale: locale)
                .decimalPrecision(0...3)
                .fractionDisplay(strategy: .simple(alwaysShowDenominator: false))
                .attributed
            self.locale = locale
        }

        // MARK: Public Instance Properties

        public let locale: Locale

        // MARK: Private Instance Properties

        private let baseStyle: Number.FormatStyle.Attributed
    }
}

// MARK: - FormatStyle

extension  Loudness.FormatStyle: FormatStyle {

    // MARK: Public Instance Methods

    public func format(_ value: Loudness) -> AttributedString {
        baseStyle.format(value.numberValue)
    }
}

// MARK: -

extension  Loudness {
    public func formatted() -> AttributedString {
        FormatStyle().format(self)
    }
}
