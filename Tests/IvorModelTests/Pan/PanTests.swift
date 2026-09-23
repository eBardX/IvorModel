// © 2025–2026 John Gary Pusey (see LICENSE.md)

import Foundation
@testable import IvorModel
import Testing
import XestiNumbers

struct PanTests {
}

// MARK: -

extension PanTests {
    @Test
    func codable_decodesLegacyStereoValue() throws {
        let decoded = try JSONDecoder().decode(Pan.self, from: Data(#""-1/2""#.utf8))

        #expect(decoded == Pan(horizontal: -45))
    }

    @Test
    func codable_rejectsOutOfRangeLegacyStereoValue() {
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(Pan.self, from: Data(#""2""#.utf8))
        }
    }

    @Test
    func codable_roundTrip() throws {
        let original = Pan(horizontal: -45, vertical: 150)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Pan.self, from: data)

        #expect(decoded == original)
    }

    @Test
    func constants() {
        #expect(Pan.above == Pan(horizontal: 0, vertical: 90))
        #expect(Pan.behind == Pan(horizontal: 180, vertical: 0))
        #expect(Pan.below == Pan(horizontal: 0, vertical: -90))
        #expect(Pan.center == Pan(horizontal: 0, vertical: 0))
        #expect(Pan.left == Pan(horizontal: -90, vertical: 0))
        #expect(Pan.right == Pan(horizontal: 90, vertical: 0))
    }

    @Test
    func description() {
        #expect(Pan.left.description == "-90H")
        #expect(Pan.above.description == "0H 90V")
    }

    @Test
    func equality_comparesAnglesAsWritten() {
        #expect(Pan(horizontal: 0, vertical: 180) != Pan.behind)
    }

    @Test
    func init_stereo() {
        #expect(Pan(stereo: -1) == Pan.left)
        #expect(Pan(stereo: 0) == Pan.center)
        #expect(Pan(stereo: 1) == Pan.right)
        #expect(Pan(stereo: Number(numerator: 1, denominator: 2)) == Pan(horizontal: 45))
        #expect(Pan(stereo: 2) == nil)
        #expect(Pan(stereo: -2) == nil)
    }

    @Test
    func init_wrapsAngles() {
        #expect(Pan(horizontal: 270, vertical: -190) == Pan(horizontal: -90, vertical: 170))
    }

    @Test
    func normalized() {
        #expect(Pan(horizontal: 0, vertical: 180).normalized == Pan.behind)
        #expect(Pan(horizontal: 30, vertical: 150).normalized == Pan(horizontal: -150, vertical: 30))
        #expect(Pan(horizontal: 30, vertical: -120).normalized == Pan(horizontal: -150, vertical: -60))
        #expect(Pan(horizontal: 45, vertical: 90).normalized == Pan.above)
        #expect(Pan(horizontal: 45, vertical: -90).normalized == Pan.below)
        #expect(Pan(horizontal: 45, vertical: 30).normalized == Pan(horizontal: 45, vertical: 30))
    }

    @Test
    func plain() {
        #expect(Pan.center.plain == "0H")
        #expect(Pan.right.plain == "90H")
        #expect(Pan(horizontal: -45, vertical: 30).plain == "-45H 30V")
        #expect(Pan(horizontal: Pan.Angle(Number(numerator: 45, denominator: 2)), vertical: -10).plain == "45/2H -10V")
    }

    @Test
    func plain_parse_invalid() {
        #expect(Pan(plain: "") == nil)
        #expect(Pan(plain: "   ") == nil)
        #expect(Pan(plain: "H") == nil)
        #expect(Pan(plain: "°V") == nil)
        #expect(Pan(plain: "45 30") == nil)
        #expect(Pan(plain: "45H 30H") == nil)
        #expect(Pan(plain: "30V 45V") == nil)
        #expect(Pan(plain: "45H 30") == nil)
        #expect(Pan(plain: "45,30") == nil)
        #expect(Pan(plain: "45X") == nil)
        #expect(Pan(plain: "45HV") == nil)
        #expect(Pan(plain: "not a number") == nil)
    }

    @Test
    func plain_parse_lenient() {
        let expected = Pan(horizontal: -45, vertical: 30)

        #expect(Pan(plain: "-45H 30V") == expected)
        #expect(Pan(plain: "-45h 30v") == expected)
        #expect(Pan(plain: "30V -45H") == expected)
        #expect(Pan(plain: "-45h30v") == expected)
        #expect(Pan(plain: "  -45 H   30 V  ") == expected)
        #expect(Pan(plain: "-45°H 30°V") == expected)
        #expect(Pan(plain: "-45 ° H\u{00A0}30 ° V") == expected)
        #expect(Pan(plain: "-45 30V") == expected)
        #expect(Pan(plain: "30V -45") == expected)
    }

    @Test
    func plain_parse_omittedAngles() {
        #expect(Pan(plain: "90") == Pan.right)
        #expect(Pan(plain: "90°") == Pan.right)
        #expect(Pan(plain: "90H") == Pan.right)
        #expect(Pan(plain: "90V") == Pan.above)
        #expect(Pan(plain: "22.5") == Pan(horizontal: Pan.Angle(Number(numerator: 45, denominator: 2))))
    }

    @Test
    func plain_roundTrip() {
        for pan in [Pan.center,
                    .left,
                    .right,
                    .above,
                    .below,
                    .behind,
                    Pan(horizontal: -45, vertical: 30),
                    Pan(horizontal: Pan.Angle(Number(numerator: 1, denominator: 3)), vertical: -10)] {
            #expect(Pan(plain: pan.plain) == pan)
        }
    }

    @Test
    func stereo_level() {
        #expect(Pan.left.stereo == -1)
        #expect(Pan.center.stereo == 0)
        #expect(Pan.right.stereo == 1)
        #expect(Pan(horizontal: 45).stereo == Number(numerator: 1, denominator: 2))
        #expect(Pan(horizontal: 135).stereo == Number(numerator: 1, denominator: 2))
        #expect(Pan(horizontal: -135).stereo == Number(numerator: -1, denominator: 2))
        #expect(Pan.behind.stereo == 0)
        #expect(Pan(horizontal: 0, vertical: 180).stereo == 0)
    }

    @Test
    func stereo_elevated() {
        #expect(Pan.above.stereo == 0)
        #expect(Pan.below.stereo == 0)

        // (90, 60) lies 30° off the median plane: sin(90°)·cos(60°) = sin(30°).
        #expect(abs(Pan(horizontal: 90, vertical: 60).stereo.doubleValue - 1.0 / 3.0) < 1e-9)
    }
}
