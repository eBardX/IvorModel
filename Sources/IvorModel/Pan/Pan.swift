// © 2025–2026 John Gary Pusey (see LICENSE.md)

public import XestiNumbers

private import Foundation

/// A spatial pan position: the direction of a sound in 3-D space relative to
/// the listener, expressed as a horizontal and a vertical ``Angle`` in degrees.
///
/// The conventions follow MusicXML’s `pan` and `elevation`:
///
/// - `horizontal` — `0` is straight ahead, `-90` is hard left, `90` is hard
///   right, and `180` is directly behind.
/// - `vertical` — `0` is level with the listener, `90` is directly above, and
///   `-90` is directly below. Values beyond ±90 continue over (or under) the
///   listener toward the back, so `180` is also directly behind.
///
/// Because the vertical angle is not folded into ±90, a direction can be
/// written in more than one way — `(0, 180)` and `(180, 0)` are both directly
/// behind — and the difference matters to a ``PanMap``, which interpolates
/// each angle independently: moving from `(0, 0)` to `(0, 180)` passes
/// overhead, whereas moving to `(180, 0)` swings around the side. Pan
/// positions therefore keep the angles as written, and `==` compares those
/// angles. To compare directions instead, compare their ``normalized`` forms.
public struct Pan {

    // MARK: Public Initializers

    /// Creates a pan position from its horizontal and vertical angles.
    ///
    /// - Parameter horizontal: The horizontal angle, in degrees. Defaults to
    ///                         `0` (straight ahead).
    /// - Parameter vertical:   The vertical angle, in degrees. Defaults to `0`
    ///                         (level with the listener).
    public init(horizontal: Angle = 0,
                vertical: Angle = 0) {
        self.horizontal = horizontal
        self.vertical = vertical
    }

    /// Creates a pan position by parsing its plain string representation,
    /// returning `nil` if the string cannot be parsed.
    ///
    /// Parsing is lenient. Each angle is a number optionally followed by a
    /// degree sign and then by a label — `H` for horizontal or `V` for
    /// vertical, in either case — with optional whitespace throughout, and
    /// the angles may appear in either order. An unlabeled number is the
    /// horizontal angle, and an omitted angle is `0`. For example, `-45H 30V`,
    /// `30v -45h`, `-45°H 30°V`, `-45`, and `30V` are all accepted. A string
    /// that gives either angle more than once, or that contains anything
    /// else, is rejected.
    ///
    /// - Parameter plain:  The plain string representation of the pan position
    ///                     (as produced by `plain`).
    public init?(plain: String) {
        guard let (horizontal, vertical) = Self._parse(plain)
        else { return nil }

        self.init(horizontal: horizontal ?? 0,
                  vertical: vertical ?? 0)
    }

    /// Creates a level pan position from a stereo pan value, returning `nil`
    /// if the value is out of range.
    ///
    /// The stereo range maps linearly onto the frontal arc: `-1` is hard left
    /// (`-90`), `0` is straight ahead, and `1` is hard right (`90`).
    ///
    /// - Parameter stereo: A rational number in the range `[-1, 1]`.
    public init?(stereo: Number) {
        guard stereo.isRational,
              (-1...1) ~= stereo
        else { return nil }

        self.init(horizontal: Angle(stereo * 90))
    }

    // MARK: Public Instance Properties

    /// The horizontal angle of this pan position, in degrees.
    public let horizontal: Angle

    /// The vertical angle of this pan position, in degrees.
    public let vertical: Angle
}

// MARK: -

extension Pan {

    // MARK: Public Type Properties

    /// The pan position directly above the listener (`0`, `90`).
    public static let above = Self(vertical: 90)

    /// The pan position directly behind the listener (`180`, `0`).
    public static let behind = Self(horizontal: 180)

    /// The pan position directly below the listener (`0`, `-90`).
    public static let below = Self(vertical: -90)

    /// The pan position straight ahead of the listener (`0`, `0`).
    public static let center = Self()

    /// The pan position hard left of the listener (`-90`, `0`).
    public static let left = Self(horizontal: -90)

    /// The pan position hard right of the listener (`90`, `0`).
    public static let right = Self(horizontal: 90)

    // MARK: Public Instance Properties

    /// The canonical form of this pan position’s direction.
    ///
    /// The vertical angle is folded into the range `[-90, 90]`, turning the
    /// horizontal angle around by 180° when it is, and the horizontal angle
    /// is set to `0` directly above or below, where it has no meaning. Two
    /// pan positions denote the same direction exactly when their normalized
    /// forms are equal.
    public var normalized: Self {
        var hval = horizontal.numberValue
        var vval = vertical.numberValue

        if vval > 90 {
            hval += 180
            vval = 180 - vval
        } else if vval < -90 {
            hval += 180
            vval = -180 - vval
        }

        if abs(vval) == 90 {
            hval = 0
        }

        return Self(horizontal: Angle(hval),
                    vertical: Angle(vval))
    }

    /// The plain string representation of this pan position: the horizontal
    /// angle labeled `H`, followed by a space and the vertical angle labeled
    /// `V` (for example, `-45H 30V`). The vertical angle is omitted when it is
    /// `0` (for example, `-45H`).
    public var plain: String {
        guard !vertical.numberValue.isZero
        else { return "\(horizontal.plain)H" }

        return "\(horizontal.plain)H \(vertical.plain)V"
    }

    /// The stereo fold-down of this pan position, in the range `[-1, 1]`.
    ///
    /// This is the position’s lateral angle — its angle away from the median
    /// plane, which is what the interaural cues that stereo panning imitates
    /// depend on — scaled so that `-90` is `-1` and `90` is `1`. A level
    /// position behind the listener therefore folds onto its mirror image in
    /// front (`135` has the same stereo value as `45`), and a position
    /// directly above or below folds to `0`. For a level position the result
    /// is exact (for exact angles), and the inverse of ``init(stereo:)``.
    public var stereo: Number {
        let direction = normalized
        let hval = direction.horizontal.numberValue

        guard direction.vertical.numberValue.isZero
        else { return Self._lateralDegrees(horizontal: hval.doubleValue,
                                           vertical: direction.vertical.doubleValue) / 90 }

        if hval > 90 {
            return (180 - hval) / 90
        }

        if hval < -90 {
            return (-180 - hval) / 90
        }

        return hval / 90
    }

    // MARK: Private Type Methods

    private static func _lateralDegrees(horizontal: Double,
                                        vertical: Double) -> Number {
        let lateral = sin(horizontal * .pi / 180) * cos(vertical * .pi / 180)

        return Number(asin(min(max(lateral, -1), 1)) * 180 / .pi)
    }

    private static func _isLabel(_ char: Character) -> Bool {
        "HVhv".contains(char)
    }

    private static func _parse(_ plain: String) -> (horizontal: Angle?, vertical: Angle?)? {
        var horizontal: Angle?
        var vertical: Angle?
        var rest = plain.drop { $0.isWhitespace }

        guard !rest.isEmpty
        else { return nil }

        while !rest.isEmpty {
            let numberText = rest.prefix { !$0.isWhitespace && $0 != "°" && !_isLabel($0) }

            guard let angle = Angle(plain: String(numberText))
            else { return nil }

            rest = rest.dropFirst(numberText.count).drop { $0.isWhitespace }

            if rest.first == "°" {
                rest = rest.dropFirst().drop { $0.isWhitespace }
            }

            switch rest.first {
            case "v",
                 "V":
                guard vertical == nil
                else { return nil }

                vertical = angle
                rest = rest.dropFirst()

            case "h",
                 "H":
                guard horizontal == nil
                else { return nil }

                horizontal = angle
                rest = rest.dropFirst()

            default:
                guard horizontal == nil
                else { return nil }

                horizontal = angle
            }

            rest = rest.drop { $0.isWhitespace }
        }

        return (horizontal, vertical)
    }
}

// MARK: - Codable

extension Pan: Codable {
    /// Creates a pan position by decoding from the provided decoder.
    ///
    /// A pan position is encoded as a two-element array of its horizontal and
    /// vertical angles. A lone number is also accepted — the stereo pan value
    /// a document saved before pan positions became spatial holds — and is
    /// decoded as ``init(stereo:)`` would.
    ///
    /// - Parameter decoder:    The decoder to read from.
    ///
    /// - Throws:   `DecodingError` if the encoded data is invalid or corrupted.
    public init(from decoder: any Decoder) throws {
        if var container = try? decoder.unkeyedContainer() {
            self.horizontal = try container.decode(Angle.self)
            self.vertical = try container.decode(Angle.self)

            return
        }

        let container = try decoder.singleValueContainer()
        let stereo = try container.decode(Number.self)

        guard let pan = Self(stereo: stereo)
        else { throw DecodingError.dataCorruptedError(in: container,
                                                      debugDescription: "Invalid stereo pan value: \(stereo)") }

        self = pan
    }

    /// Encodes this pan position into the provided encoder.
    ///
    /// - Parameter encoder:    The encoder to write to.
    ///
    /// - Throws:   `EncodingError` if the value cannot be encoded.
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.unkeyedContainer()

        try container.encode(horizontal)
        try container.encode(vertical)
    }
}

// MARK: - CustomStringConvertible

extension Pan: CustomStringConvertible {
    /// The plain string representation of this pan position.
    public var description: String {
        plain
    }
}

// MARK: - Hashable

extension Pan: Hashable {
}

// MARK: - Sendable

extension Pan: Sendable {
}
