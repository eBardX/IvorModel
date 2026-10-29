// © 2026 John Gary Pusey (see LICENSE.md)

public import IvorTiming
public import XestiNumbers

extension BeatDuration: TemplateDuration {

    // MARK: Public Instance Methods

    /// Returns the exact ratio of this duration to another.
    ///
    /// - Parameter other:  The duration to compare with.
    ///
    /// - Returns:  The ratio, or `nil` if `other` is zero.
    public func templateRatio(to other: Self) -> Number? {
        guard !other.isZero
        else { return nil }

        return numberValue / other.numberValue
    }
}
