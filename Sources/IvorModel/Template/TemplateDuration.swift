// © 2026 John Gary Pusey (see LICENSE.md)

public import IvorTiming
public import XestiNumbers

/// A duration type that a template can analyze in relative terms: as a ratio to the previous
/// duration.
///
/// ``BeatDuration`` and ``WallDuration`` conform.
public protocol TemplateDuration: DurationProtocol {

    // MARK: Public Instance Methods

    /// Returns the ratio of this duration to another, as a template records it.
    ///
    /// Ratios that a template should treat as the same are equal: for ``WallDuration``, the ratio
    /// is rounded to the nearest whole power of 1.01, so that ratios within about 1% match.
    ///
    /// - Parameter other:  The duration to compare with.
    ///
    /// - Returns:  The ratio, or `nil` if `other` is zero.
    func templateRatio(to other: Self) -> Number?
}
