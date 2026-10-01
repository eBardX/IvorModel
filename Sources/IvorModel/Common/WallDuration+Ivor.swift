// © 2026 John Gary Pusey (see LICENSE.md)

public import IvorSMPTE
public import IvorTiming

private import XestiTools

// Reads a wall-time duration from SMPTE timecode.
extension WallDuration {

    // MARK: Public Initializers

    /// Creates a new `WallDuration` instance holding the time elapsed from
    /// midnight (00:00:00:00) to the given timecode.
    ///
    /// The duration is rounded to the nearest microsecond. This is the
    /// inverse of ``IvorSMPTE/SMPTETime/init(frameRate:duration:)``.
    ///
    /// - Parameter smpteTime:  The timecode to convert.
    public init(smpteTime: SMPTETime) {
        self.init(smpteTime.elapsedSeconds.microseconds)
    }
}
