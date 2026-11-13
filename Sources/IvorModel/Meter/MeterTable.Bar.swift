// © 2026 John Gary Pusey (see LICENSE.md)

public import IvorTiming

extension MeterTable {

    // MARK: Public Nested Types

    /// One bar of the grid a ``MeterTable`` implies.
    public struct Bar {

        // MARK: Public Instance Properties

        /// The beat times at which the bar’s beats start, within ``range``, or an empty array in a
        /// free bar. A pickup bar lists only the beats that start inside it.
        public let beatStarts: [BeatTime]

        /// A Boolean value indicating whether this bar is the pickup bar, bar 0.
        public let isPickup: Bool

        /// A Boolean value indicating whether this bar is a short bar: one cut off by the next
        /// meter entry before it reaches its full bar length.
        public let isShort: Bool

        /// The meter of the bar.
        public let meter: Meter

        /// The bar number: 0 for the pickup bar, and counting from 1 after it.
        public let number: Int

        /// The actual extent of the bar; a short bar’s is cut off.
        ///
        /// A free bar that runs on for ever, after the last entry, ends at the upper bound of the
        /// query that returned it.
        public let range: Range<BeatTime>

        // MARK: Internal Initializers

        internal init(number: Int,
                      range: Range<BeatTime>,
                      meter: Meter,
                      isPickup: Bool,
                      isShort: Bool,
                      beatStarts: [BeatTime]) {
            self.beatStarts = beatStarts
            self.isPickup = isPickup
            self.isShort = isShort
            self.meter = meter
            self.number = number
            self.range = range
        }
    }
}

// MARK: - Hashable

extension MeterTable.Bar: Hashable {
}

// MARK: - Sendable

extension MeterTable.Bar: Sendable {
}
