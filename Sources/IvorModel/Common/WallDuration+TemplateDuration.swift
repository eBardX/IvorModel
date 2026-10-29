// © 2026 John Gary Pusey (see LICENSE.md)

public import IvorTiming
public import XestiNumbers

private import Foundation

extension WallDuration: TemplateDuration {

    // MARK: Public Instance Methods

    /// Returns the ratio of this duration to another, rounded to the nearest whole power of 1.01.
    ///
    /// - Parameter other:  The duration to compare with.
    ///
    /// - Returns:  The ratio, or `nil` if either duration is zero.
    public func templateRatio(to other: Self) -> Number? {
        guard !isZero,
              !other.isZero
        else { return nil }

        let steps = (log(doubleValue / other.doubleValue) / log(1.01)).rounded()

        return Number(pow(1.01, steps))
    }
}
