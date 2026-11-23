// © 2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import IvorTiming
import Testing
import XestiNumbers

struct FermataConverterTests {
}

// MARK: -

extension FermataConverterTests {
    private typealias Converter = FermataConverter<BeatTime, BeatTime>

    @Test
    func caesuraExecution_convertsThePause() throws {
        let execution = CaesuraExecution<BeatTime>(pause: .added(positiveBeats(1, 4)))

        #expect(try doublingFermataConverter().caesuraExecution(execution) == CaesuraExecution(pause: .added(positiveBeats(1, 2))))
    }

    @Test
    func caesuraExecution_withoutAPause() throws {
        #expect(try doublingFermataConverter().caesuraExecution(CaesuraExecution()) == CaesuraExecution())
    }

    @Test
    func fermata_keepsTheShapeAndConvertsTheExecution() throws {
        let fermata = Fermata<BeatTime>(shape: .long,
                                        execution: FermataExecution(hold: .added(positiveBeats(1, 4))))
        let converted = try doublingFermataConverter().fermata(fermata)

        #expect(converted == Fermata(shape: .long,
                                     execution: FermataExecution(hold: .added(positiveBeats(1, 2)))))
    }

    @Test
    func fermataExecution_convertsHoldAndPauseAndKeepsIsPlayed() throws {
        let execution = FermataExecution<BeatTime>(hold: .added(positiveBeats(1, 8)),
                                                   pauseAfter: .added(positiveBeats(1, 4)),
                                                   isPlayed: false)
        let converted = try doublingFermataConverter().fermataExecution(execution)

        #expect(converted == FermataExecution(hold: .added(positiveBeats(1, 4)),
                                              pauseAfter: .added(positiveBeats(1, 2)),
                                              isPlayed: false))
    }

    @Test
    func hold_added() throws {
        #expect(try doublingFermataConverter().hold(.added(positiveBeats(1, 4))) == .added(positiveBeats(1, 2)))
    }

    @Test
    func hold_secondsIsUnchanged() throws {
        #expect(try doublingFermataConverter().hold(.seconds(positiveSeconds(2))) == .seconds(positiveSeconds(2)))
    }

    @Test
    func hold_stretchIsUnchanged() throws {
        let stretch = fermataStretch(frac(3, 2))

        #expect(try doublingFermataConverter().hold(.stretch(stretch)) == .stretch(stretch))
    }

    @Test
    func initAt_aSpanThatConvertsToZeroThrows() {
        let converter = Converter(at: 1) { _ in beatTime(3) }

        #expect(throws: ConversionFailure.self) {
            try converter.positive(positiveBeats(1))
        }
    }

    @Test
    func initAt_convertsEachLengthStartingAtTheTime() throws {
        //
        // Squaring times: a whole note from 1 ends at 2, spanning 4 − 1 = 3; from 0, it spans 1.
        //
        let square = { (time: BeatTime) in beatTime(time.numberValue * time.numberValue) }

        #expect(try Converter(at: 1, times: square).positive(positiveBeats(1)) == positiveBeats(3))
        #expect(try Converter(at: 0, times: square).positive(positiveBeats(1)) == positiveBeats(1))
    }

    @Test
    func initDuration_storesTheConversion() throws {
        #expect(try doublingFermataConverter().duration(beats(frac(1, 4))) == beats(frac(1, 2)))
    }

    @Test
    func partMark_caesura() throws {
        let mark = PartMark<BeatTime>.caesura(CaesuraExecution(pause: .seconds(positiveSeconds(1))))

        #expect(try doublingFermataConverter().partMark(mark) == mark)
    }

    @Test
    func partMark_fermataConvertsItsSpan() throws {
        #expect(try doublingFermataConverter().partMark(quarterFermataMark(1)) == quarterFermataMark(2))
    }

    @Test
    func pause_added() throws {
        #expect(try doublingFermataConverter().pause(.added(positiveBeats(1, 4))) == .added(positiveBeats(1, 2)))
    }

    @Test
    func pause_secondsIsUnchanged() throws {
        #expect(try doublingFermataConverter().pause(.seconds(positiveSeconds(3))) == .seconds(positiveSeconds(3)))
    }

    @Test
    func positive_aThrowingConversionPropagates() {
        let converter = Converter { _ in throw ConversionFailure() }

        #expect(throws: ConversionFailure.self) {
            try converter.partMark(quarterFermataMark(1))
        }
    }

    @Test
    func positive_aZeroLengthThrows() {
        let converter = Converter { _ in beats(0) }

        #expect(throws: ConversionFailure.self) {
            try converter.positive(positiveBeats(1))
        }
    }
}
