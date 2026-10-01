// © 2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import IvorSMPTE
import IvorTiming
import Testing
import XestiNumbers
import XestiTools

struct SMPTETimeConverterIvorTests {
}

// MARK: -

extension SMPTETimeConverterIvorTests {
    @Test
    func smpteTime_at() throws {
        let startTime = try #require(SMPTETime(string: "01:00:00:00", frameRate: .fps25))
        let converter = SMPTETimeConverter(startTime: startTime)

        #expect(converter.smpteTime(at: WallTime.zero) == startTime)
        #expect(converter.smpteTime(at: WallTime(1_500_000)).description == "01:00:01:12.50")
    }

    @Test
    func smpteTime_at_dropFrame() {
        let converter = SMPTETimeConverter(frameRate: .fps2997Drop)

        // 1,800 frames at 30000/1001 frames per second is exactly 60.06 seconds.
        #expect(converter.smpteTime(at: WallTime(60_060_000)).description == "00:01:00;02")
    }

    @Test
    func smpteTime_at_roundsToHundredthOfFrame() {
        let converter = SMPTETimeConverter(frameRate: .fps25)

        // A hundredth of a frame at 25 fps is 400 µs.
        #expect(converter.smpteTime(at: WallTime(40_199)).description == "00:00:00:01")
        #expect(converter.smpteTime(at: WallTime(40_201)).description == "00:00:00:01.01")
    }

    @Test
    func wallTime_at() throws {
        let startTime = try #require(SMPTETime(string: "01:00:00:00", frameRate: .fps25))
        let converter = SMPTETimeConverter(startTime: startTime)
        let time = try #require(SMPTETime(string: "01:00:01:12.50", frameRate: .fps25))

        #expect(converter.wallTime(at: startTime) == .zero)
        #expect(converter.wallTime(at: time) == WallTime(1_500_000))
    }

    @Test
    func wallTime_at_roundsToMicrosecond() throws {
        let converter = SMPTETimeConverter(frameRate: .fps2997)
        let time = try #require(SMPTETime(string: "00:00:00:01", frameRate: .fps2997))

        // 1001/30000 seconds is 33,366.67 µs.
        #expect(converter.wallTime(at: time) == WallTime(33_367))
    }

    @Test
    func wallTime_at_wraps() throws {
        let startTime = try #require(SMPTETime(string: "23:59:00:00", frameRate: .fps25))
        let converter = SMPTETimeConverter(startTime: startTime)
        let time = try #require(SMPTETime(string: "00:01:00:00", frameRate: .fps25))

        #expect(converter.wallTime(at: time) == WallTime(120_000_000))
    }

    @Test(arguments: [SMPTEFrameRate.fps24, .fps25, .fps2997Drop, .fps30])
    func wallTime_smpteTime_roundTrip(frameRate: SMPTEFrameRate) throws {
        let startTime = try #require(SMPTETime(string: "10:00:00:00", frameRate: frameRate))
        let converter = SMPTETimeConverter(startTime: startTime)

        for string in ["10:00:00:00", "10:00:59:01", "10:01:00:02", "10:10:00:00", "11:23:45:06.78"] {
            let time = try #require(SMPTETime(string: string, frameRate: frameRate))

            #expect(converter.smpteTime(at: converter.wallTime(at: time)) == time)
        }
    }
}
