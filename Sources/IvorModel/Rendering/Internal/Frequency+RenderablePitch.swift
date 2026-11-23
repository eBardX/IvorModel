// © 2026 John Gary Pusey (see LICENSE.md)

internal import IvorTuning
internal import XestiNumbers

// MARK: - RenderablePitch

extension Frequency: RenderablePitch {

    // MARK: Internal Instance Methods

    //
    // Frequencies have no spelling, so a diatonic step is a whole tone (resolution 6 of the
    // grace-notes plan): 200 cents, or 100 for a half step.
    //
    internal func partner(on side: PartnerSide,
                          rule: PartnerRule,
                          key: Key?) -> Self? {
        transposed(by: DirectedInterval(interval: Ratio(cents: rule == .halfStep ? 100 : 200),
                                        direction: side == .above ? .ascending : .descending))
    }
}
