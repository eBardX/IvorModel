public import Foundation

extension Instrument {

    // MARK: Public Nested Types

    public struct FormatStyle {

        // MARK: Public Initializers

        public init(locale: Locale = .autoupdatingCurrent) {
            self.locale = locale
        }

        // MARK: Public Instance Properties

        public let locale: Locale
    }
}

// MARK: - FormatStyle

extension Instrument.FormatStyle: FormatStyle {

    // MARK: Public Instance Methods

    public func format(_ value: Instrument) -> AttributedString {
        AttributedString(value.stringValue)
    }
}

// MARK: -

extension Instrument {
    public func formatted() -> AttributedString {
        FormatStyle().format(self)
    }
}
