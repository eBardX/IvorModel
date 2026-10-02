// © 2026 John Gary Pusey (see LICENSE.md)

public import IvorSMPTE
public import IvorTiming

private import XestiNumbers
private import XestiTools

// Converts between a work's wall time and the SMPTE timecode that labels it.
extension SMPTETimeConverter {

    // MARK: Public Instance Methods

    /// Returns the timecode at the given wall time, measured from the start
    /// timecode.
    ///
    /// The result is rounded to the nearest hundredth of a frame, and wraps
    /// around to 00:00:00:00 after 24 hours of timecode. To label a work’s
    /// wall times, create the converter from the work’s
    /// ``Work/smpteStartTime``.
    ///
    /// - Parameter time:   The wall time to convert.
    ///
    /// - Returns:  The ``SMPTETime`` at `time`.
    public func smpteTime(at time: WallTime) -> SMPTETime {
        smpteTime(at: SMPTEExactSeconds(time.numberValue))
    }

    /// Returns the wall time of the given timecode, measured from the start
    /// timecode.
    ///
    /// The result is rounded to the nearest microsecond. Because timecode
    /// wraps around after 24 hours, a timecode earlier than the start
    /// timecode is treated as occurring on the following day.
    ///
    /// - Parameter time:   The timecode to convert. Its frame rate must match
    ///                     this converter’s `frameRate`.
    ///
    /// - Returns:  The wall time of `time`.
    ///
    /// - Precondition: `time`’s frame rate must equal this converter’s
    ///                 `frameRate`.
    public func wallTime(at time: SMPTETime) -> WallTime {
        //
        // Can't fail: the seconds are never negative, and timecode wraps around after 24 hours,
        // far short of the largest wall time.
        //
        guard let wallTime = WallTime(numberValue: seconds(at: time).numberValue)
        else { preconditionFailure("Unrepresentable wall time for \(time)") }

        return wallTime
    }
}
