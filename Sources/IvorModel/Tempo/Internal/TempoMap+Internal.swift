internal import IvorTiming
internal import XestiTools

private import XestiNumbers

extension TempoMap {

    // MARK: Internal Type Methods

    internal static func determineHasExtras(_ entries: [Entry]) -> Bool {
        entries.contains { $0.extras != nil }
    }

    // MARK: Internal Instance Methods

    internal func bestIndex(for beatTime: BeatTime) -> Int {
        guard let idx = entries.firstIndex(where: { beatTime < $0.beatTime })
        else { return entries.count - 1 }

        return idx - 1
    }

    internal func bestIndex(for wallTime: WallTime) -> Int {
        guard let idx = entries.firstIndex(where: { wallTime < $0.wallTime })
        else { return entries.count - 1 }

        return idx - 1
    }

    internal func indexForInserting(beatTime: BeatTime) -> Int {
        entries.firstIndex { beatTime < $0.beatTime } ?? entries.endIndex
    }

    internal func indexMatching(beatTime: BeatTime,
                                tempo: Tempo,
                                extras: Extras?) -> Int? {
        entries.firstIndex {
            (beatTime, tempo, extras) == ($0.beatTime, $0.tempo, $0.extras)
        }
    }

    internal mutating func rebuildDerivedFields() {
        guard !entries.isEmpty
        else { return }

        let refTempo = Tempo.default.numberValue

        for index in entries.indices {
            let startTempo = entries[index].tempo.numberValue

            let beatDuration: BeatDuration
            let tempoDelta: Number

            if index < entries.count - 1 {
                beatDuration = entries[index + 1].beatTime - entries[index].beatTime
                tempoDelta = entries[index + 1].tempo.numberValue - startTempo
            } else {
                beatDuration = 1
                tempoDelta = 0
            }

            let beatLength = beatDuration.numberValue
            let wallDuration: WallDuration

            if tempoDelta < 0 {
                let scale = sqrt(-tempoDelta / startTempo)

                wallDuration = WallDuration(beatLength * refTempo / sqrt(startTempo * -tempoDelta) * atanh(scale))
            } else if tempoDelta > 0 {
                let scale = sqrt(tempoDelta / startTempo)

                wallDuration = WallDuration(beatLength * refTempo / sqrt(startTempo * tempoDelta) * atan(scale))
            } else {
                wallDuration = WallDuration(beatLength * refTempo / startTempo)
            }

            let wallTime: WallTime = if index == 0 {
                WallTime(entries[0].beatTime.numberValue * refTempo / startTempo)
            } else {
                entries[index - 1].wallTime + entries[index - 1].wallDuration
            }

            entries[index].beatDuration = beatDuration
            entries[index].tempoDelta = tempoDelta
            entries[index].wallDuration = wallDuration
            entries[index].wallTime = wallTime
        }
    }
}
