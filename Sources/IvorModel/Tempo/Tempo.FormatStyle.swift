public import Foundation

private import XestiNumbers

extension Tempo {

    // MARK: Public Nested Types

    public struct FormatStyle {

        // MARK: Public Initializers

        public init(locale: Locale = .autoupdatingCurrent) {
            self.baseStyle = Number.FormatStyle(locale: locale)
                .decimalPrecision(0)
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

extension Tempo.FormatStyle: FormatStyle {

    // MARK: Public Instance Methods

    public func format(_ value: Tempo) -> AttributedString {
        baseStyle.format(value.numberValue)
    }
}

// MARK: -

extension Tempo {
    public func formatted() -> AttributedString {
        FormatStyle().format(self)
    }
}
