// © 2026 John Gary Pusey (see LICENSE.md)

public import IvorSMPTE
public import IvorTiming

private import XestiNumbers

// Expresses a wall-time duration as SMPTE timecode.
extension SMPTETime {

    // MARK: Public Initializers

    /// Creates a new `SMPTETime` instance holding the given duration as the
    /// timecode that long after midnight (00:00:00:00).
    ///
    /// The duration is rounded to the nearest hundredth of a frame, and wraps
    /// around to 00:00:00:00 after 24 hours of timecode. Unlike a time, a
    /// duration ignores any SMPTE start time; use
    /// ``WallDuration/init(smpteTime:)`` to convert it back.
    ///
    /// - Parameter frameRate:  The SMPTE frame rate.
    /// - Parameter duration:   The duration to express.
    public init(frameRate: SMPTEFrameRate,
                duration: WallDuration) {
        self.init(frameRate: frameRate,
                  elapsedSeconds: SMPTEExactSeconds(duration.numberValue))
    }
}
