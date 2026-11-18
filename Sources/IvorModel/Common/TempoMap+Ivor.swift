// © 2026 John Gary Pusey (see LICENSE.md)

internal import IvorTiming
internal import XestiTools

extension TempoMap {

    // MARK: Internal Instance Methods

    //
    // This tempo map with the names of its entries' extras normalized (see
    // `Extras.normalizingNames()`).  The tempo map lives in IvorTiming, which knows nothing of
    // Ivor's extras, so a decoded work does this for it.
    //
    internal func normalizingExtraNames() -> TempoMap {
        var result = self

        for entry in self {
            let extras = entry.extras?.normalizingNames()

            if extras != entry.extras {
                result.update(entryID: entry.entryID,
                              tempo: entry.tempo,
                              extras: extras)
            }
        }

        return result
    }
}
