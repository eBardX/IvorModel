// © 2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import IvorSMPTE
import IvorTiming
import Testing
import XestiNumbers
import XestiTools

struct WallDurationIvorTests {
}

// MARK: -

extension WallDurationIvorTests {
    @Test
    func init_smpteTime() throws {
        let time1 = try #require(SMPTETime(string: "00:00:00:00", frameRate: .fps25))
        let time2 = try #require(SMPTETime(string: "00:01:30:00", frameRate: .fps25))
        let time3 = try #require(SMPTETime(string: "00:01:00;02", frameRate: .fps2997Drop))

        #expect(WallDuration(smpteTime: time1) == .zero)
        #expect(WallDuration(smpteTime: time2) == WallDuration(90_000_000))
        #expect(WallDuration(smpteTime: time3) == WallDuration(60_060_000))
    }

    @Test
    func init_smpteTime_roundsToMicrosecond() throws {
        let time = try #require(SMPTETime(string: "00:00:00:01", frameRate: .fps2997))

        // 1001/30000 seconds is 33,366.67 µs.
        #expect(WallDuration(smpteTime: time) == WallDuration(33_367))
    }

    @Test(arguments: [SMPTEFrameRate.fps24, .fps25, .fps2997Drop, .fps30])
    func init_smpteTime_roundTrip(frameRate: SMPTEFrameRate) throws {
        for string in ["00:00:00:01", "00:00:59:01", "00:01:00:02", "00:10:00:00", "01:23:45:06.78"] {
            let time = try #require(SMPTETime(string: string, frameRate: frameRate))

            #expect(SMPTETime(frameRate: frameRate, duration: WallDuration(smpteTime: time)) == time)
        }
    }
}
