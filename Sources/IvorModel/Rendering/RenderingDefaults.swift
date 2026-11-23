// © 2026 John Gary Pusey (see LICENSE.md)

public import IvorTiming

internal import XestiNumbers
internal import XestiTools

/// The built-in defaults rendering falls back on when neither an ornament’s own execution nor
/// the part’s or work’s interpretation rules say how to play it.
///
/// Most are MuseScore’s. The trill rate and the main-note start are Ivor’s own: most files give
/// no start note, and modern practice starts on the main note.
public enum RenderingDefaults {
}

// MARK: -

extension RenderingDefaults {

    // MARK: Public Type Properties

    /// How long a lone appoggiatura is, as a share of its main note: half.
    public static let appoggiaturaShare = Proportion(numberValue: Number(numerator: 1,
                                                                         denominator: 2)).require()

    /// Which tone of a rolled chord falls on the beat: the first.
    public static let arpeggioAnchor = ArpeggioAnchor.firstOnBeat

    /// Which way a rolled chord rolls: up.
    public static let arpeggioDirection = ArpeggioDirection.up

    /// The most each next tone of a rolled chord starts after the one before: 60 milliseconds.
    public static let arpeggioMaximumPerTone = PositiveDuration(WallDuration(numberValue: Number(numerator: 3,
                                                                                                 denominator: 50)).require()).require()

    /// The pause at a caesura: 2 seconds, in every part.
    public static let caesuraPause = PositiveDuration(WallDuration(numberValue: 2).require()).require()

    /// How long a lone appoggiatura is, as a share of its main note in compound meter, when the
    /// main note is longer than an eighth: two-thirds.
    public static let compoundAppoggiaturaShare = Proportion(numberValue: Number(numerator: 2,
                                                                                 denominator: 3)).require()

    /// How long each fermata shape holds, as a stretch of its span: very short 1.25, short 1.5,
    /// normal 2, long 3, very long 4.
    public static let fermataStretches: [FermataShape: FermataStretch] = [.veryShort: _stretch(5, 4),
                                                                          .short: _stretch(3, 2),
                                                                          .normal: _stretch(2, 1),
                                                                          .long: _stretch(3, 1),
                                                                          .veryLong: _stretch(4, 1)]

    /// The most of its main note a grace figure of acciaccaturas, or of several notes, may take:
    /// half.
    public static let graceMaximumShare = Proportion(numberValue: Number(numerator: 1,
                                                                         denominator: 2)).require()

    /// How long each grace note is in a beat work, when nothing else says: a sixty-fourth.
    public static let gracePerNoteBeat = PositiveDuration(BeatDuration(numberValue: Number(numerator: 1,
                                                                                           denominator: 64)).require()).require()

    /// How long each grace note is in a wall work, when nothing else says: 40 milliseconds.
    public static let gracePerNoteWall = PositiveDuration(WallDuration(numberValue: Number(numerator: 1,
                                                                                           denominator: 25)).require()).require()

    /// Where a grace figure before its note falls: on the beat, delaying the main note.
    public static let gracePlacement = GracePlacement.onBeat

    /// The most of its main note a mordent’s alternation may take: half.
    public static let mordentMaximumShare = Proportion(numberValue: Number(numerator: 1,
                                                                           denominator: 2)).require()

    /// How fast trills, mordents and unmeasured tremolos alternate: 12 notes per second.
    public static let ornamentRate = NotesPerSecond(numberValue: 12).require()

    /// Which note an ornament starts on: its main note.
    public static let ornamentStart = OrnamentStart.main

    /// How far a step partner with no written pitch lies from its main note: the diatonic step
    /// in the key, for spelled pitches in a beat work with a key; otherwise a whole tone.
    public static let partnerRule = PartnerRule.diatonic

    // MARK: Private Type Methods

    private static func _stretch(_ numerator: Int,
                                 _ denominator: Int) -> FermataStretch {
        FermataStretch(numberValue: Number(numerator: numerator,
                                           denominator: denominator)).require()
    }
}
