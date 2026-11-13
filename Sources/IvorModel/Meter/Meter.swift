// © 2026 John Gary Pusey (see LICENSE.md)

public import IvorTiming
public import XestiNumbers

private import Foundation

/// A meter: one or more numerator groups over a positive integer denominator, or *free*.
///
/// A meter with a single numerator, such as 3/4 or 6/8, is in *simple form*; one with two or more,
/// such as 2+2+3/8, is *grouped*. Any positive integer denominator is allowed, so 4/3 and 7/12 are
/// meters too. A *free* meter has no bar length and no pulse.
///
/// A meter never changes timing: ``BeatTime`` and ``BeatDuration`` count
/// whole notes whatever the meter. It only says where the barlines and the felt beats — the
/// ``pulse`` — fall.
///
/// Display-only symbols, such as C for common time, aren’t part of a meter. They’re an extra on the
/// ``MeterTable`` entry (``Extra/meterSymbol``).
public struct Meter {

    // MARK: Public Initializers

    /// Creates a metered meter from its numerator groups and denominator.
    ///
    /// - Parameter numerators:     The numerator groups, in order: one for a simple-form meter,
    ///                             two or more for a grouped one.
    /// - Parameter denominator:    The denominator.
    ///
    /// - Returns:  A new meter, or `nil` if `numerators` is empty, or if any numerator or the
    ///             denominator is zero.
    public init?(numerators: [UInt],
                 denominator: UInt) {
        guard !numerators.isEmpty,
              !numerators.contains(0),
              denominator > 0
        else { return nil }

        self.init(uncheckedNumerators: numerators,
                  denominator: denominator)
    }

    /// Creates a meter by parsing its plain string representation.
    ///
    /// The forms accepted are those ``plain`` produces — `"3/4"`, `"2+2+3/8"` and `"free"` — with
    /// optional spaces around `+` and `/`.
    ///
    /// - Parameter plain:  The plain string representation of the meter.
    ///
    /// - Returns:  A new meter, or `nil` if `plain` can’t be parsed or isn’t a valid meter.
    public init?(plain: String) {
        let trimmed = plain.trimmingCharacters(in: .whitespaces)

        if trimmed == Self.freePlain {
            self = .free
            return
        }

        let halves = trimmed.split(separator: "/",
                                   omittingEmptySubsequences: false)

        guard halves.count == 2,
              let denominator = Self._parseUInt(halves[1])
        else { return nil }

        var numerators: [UInt] = []

        for group in halves[0].split(separator: "+",
                                     omittingEmptySubsequences: false) {
            guard let numerator = Self._parseUInt(group)
            else { return nil }

            numerators.append(numerator)
        }

        self.init(numerators: numerators,
                  denominator: denominator)
    }

    // MARK: Public Instance Properties

    /// The denominator of this meter, or `nil` if it’s free.
    public let denominator: UInt?

    /// The numerator groups of this meter, in order, or an empty array if it’s free.
    public let numerators: [UInt]

    // MARK: Private Initializers

    private init(uncheckedNumerators numerators: [UInt],
                 denominator: UInt?) {
        self.denominator = denominator
        self.numerators = numerators
    }
}

// MARK: -

extension Meter {

    // MARK: Public Type Properties

    /// The free meter: no bar length and no pulse.
    public static let free = Self(uncheckedNumerators: [],
                                  denominator: nil)

    // MARK: Public Instance Properties

    /// The length of one full bar of this meter, in whole notes: the sum of the numerators over
    /// the denominator, or `nil` if this meter is free.
    ///
    /// For example, 6/8 has a bar length of 3/4, and 2+2+3/8 one of 7/8.
    public var barLength: BeatDuration? {
        guard let denominator
        else { return nil }

        return BeatDuration(Number(numerator: numerators.reduce(0, +),
                                   denominator: denominator))
    }

    /// The length of each beat of this meter, if its beats are all the same length; otherwise —
    /// for an uneven grouped meter such as 3+2/8, or a free meter — `nil`.
    public var evenPulse: BeatDuration? {
        let pulse = pulse

        guard let first = pulse.first,
              pulse.allSatisfy({ $0 == first })
        else { return nil }

        return first
    }

    /// A Boolean value indicating whether this meter is free.
    public var isFree: Bool {
        denominator == nil
    }

    /// The plain string representation of this meter, such as `"3/4"`, `"2+2+3/8"` or `"free"`.
    public var plain: String {
        guard let denominator
        else { return Self.freePlain }

        return numerators.map(String.init).joined(separator: "+") + "/" + String(denominator)
    }

    /// The felt beats of one full bar of this meter, as a list of their lengths in whole notes, or
    /// an empty array if this meter is free.
    ///
    /// The pulse follows these rules:
    ///
    /// - A grouped meter has one beat per group, each *g*/*d* long: 3+2/8 is felt as ♩. + ♩.
    /// - A simple-form meter *n*/*d*:
    ///   - with *n* = 3 and *d* ≥ 8 has **one** beat of 3/*d*: 3/8, 3/12 and 3/16 are felt in one;
    ///   - otherwise, with *n* a multiple of 3 greater than 3, is compound, with *n*/3 beats of
    ///     3/*d*: 6/8 is 2 × ♩., 6/4 is 2 × 𝅗𝅥., and 6/12 is 2 × ♩;
    ///   - otherwise has *n* beats of 1/*d*: 5/8 is 5 × ♪, 3/4 is 3 × ♩, and 4/3 is 4 × 1/3.
    public var pulse: [BeatDuration] {
        guard let denominator
        else { return [] }

        if numerators.count > 1 {
            return numerators.map {
                BeatDuration(Number(numerator: $0,
                                    denominator: denominator))
            }
        }

        let numerator = numerators[0]

        if numerator == 3,
           denominator >= 8 {
            return [BeatDuration(Number(numerator: 3,
                                        denominator: denominator))]
        }

        if numerator > 3,
           numerator.isMultiple(of: 3) {
            return Array(repeating: BeatDuration(Number(numerator: 3,
                                                        denominator: denominator)),
                         count: Int(numerator / 3))
        }

        return Array(repeating: BeatDuration(Number(numerator: 1,
                                                    denominator: denominator)),
                     count: Int(numerator))
    }

    // MARK: Public Instance Methods

    /// Returns this meter re-notated so that one bar is a given factor as long, as augmentation
    /// and diminution need.
    ///
    /// For a factor *p*/*q* in lowest terms, if *d*·*q*/*p* is a whole number, the numerators are
    /// kept and that becomes the denominator: 3/4 × 2 is 3/2, and 6/8 × 4/3 is 6/6. Otherwise,
    /// every numerator is multiplied by *p* and the denominator by *q*: 3/4 × 3/2 is 9/8, and
    /// 2+2+3/8 × 3/2 is 6+6+9/16. A simple-form meter stays simple, and a grouped one stays
    /// grouped. The pulse is re-derived by the usual rules, so it can change: 3/4 ÷ 2 is 3/8, felt
    /// in one. A free meter stays free.
    ///
    /// - Parameter factor: The factor by which to scale the bar length.
    ///
    /// - Returns:  The scaled meter.
    ///
    /// - Precondition: `factor` must be a positive rational number.
    public func scaled(by factor: Number) -> Self {
        precondition(factor.isRational && factor.isPositive,
                     "Meter scaling factor must be a positive rational number")

        guard let denominator
        else { return self }

        let num = factor.numerator.uintValue
        let den = factor.denominator.uintValue
        let product = denominator * den

        if product.isMultiple(of: num) {
            return Self(uncheckedNumerators: numerators,
                        denominator: product / num)
        }

        return Self(uncheckedNumerators: numerators.map { $0 * num },
                    denominator: product)
    }

    // MARK: Private Type Properties

    private static let freePlain = "free"

    // MARK: Private Type Methods

    private static func _parseUInt(_ text: Substring) -> UInt? {
        let trimmed = text.trimmingCharacters(in: .whitespaces)

        guard !trimmed.isEmpty,
              trimmed.allSatisfy({ ("0"..."9").contains($0) })
        else { return nil }

        return UInt(trimmed)
    }
}

// MARK: - Codable

extension Meter: Codable {

    // MARK: Public Initializers

    /// Creates a meter by decoding its plain string representation from the provided decoder.
    ///
    /// - Parameter decoder:    The decoder to read from.
    ///
    /// - Throws:   `DecodingError` if the encoded data isn’t a valid plain string representation
    ///             of a meter.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let plain = try container.decode(String.self)

        guard let meter = Self(plain: plain)
        else { throw DecodingError.dataCorruptedError(in: container,
                                                      debugDescription: "Invalid meter: \(plain)") }

        self = meter
    }

    // MARK: Public Instance Methods

    /// Encodes the plain string representation of this meter into the provided encoder.
    ///
    /// - Parameter encoder:    The encoder to write to.
    ///
    /// - Throws:   `EncodingError` if the value can’t be encoded.
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()

        try container.encode(plain)
    }
}

// MARK: - CustomStringConvertible

extension Meter: CustomStringConvertible {

    // MARK: Public Instance Properties

    /// A textual representation of this meter: its plain string representation.
    public var description: String {
        plain
    }
}

// MARK: - Hashable

extension Meter: Hashable {
}

// MARK: - Sendable

extension Meter: Sendable {
}
