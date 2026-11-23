// © 2026 John Gary Pusey (see LICENSE.md)

internal import IvorTuning

//
// A pitch type rendering can find an ornament's step partner for, when no pitch is written: a
// half step, a whole step, or the diatonic step in the key (resolutions 6 and 7 of the
// grace-notes plan). Only spelled pitches have a diatonic step; the others use a whole tone, as
// a spelled pitch does with no key or an atonal one.
//
internal protocol RenderablePitch: PitchProtocol {

    // MARK: Internal Instance Methods

    func partner(on side: PartnerSide,
                 rule: PartnerRule,
                 key: Key?) -> Self?
}
