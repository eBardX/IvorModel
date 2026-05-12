public import XestiTools

extension NoteTable {

    // MARK: Public Instance Properties

    public var isEmpty: Bool {
        notes.isEmpty
    }

    // MARK: Public Instance Methods

    public func forEach(_ body: (TimeType, DurationType, PitchType, PitchType, Extras?) -> Void) {
        notes.forEach {
            body($0.attack,
                 $0.duration,
                 $0.startPitch,
                 $0.endPitch,
                 $0.extras)
        }
    }

    public mutating func insert(attack: TimeType,
                                duration: DurationType,
                                pitch: PitchType,
                                extras: Extras? = nil) {
        insert(attack: attack,
               duration: duration,
               startPitch: pitch,
               endPitch: pitch,
               extras: extras)
    }

    public mutating func insert(attack: TimeType,
                                duration: DurationType,
                                startPitch: PitchType,
                                endPitch: PitchType,
                                extras: Extras? = nil) {
        notes.insert(Note(attack: attack,
                          duration: duration,
                          startPitch: startPitch,
                          endPitch: endPitch,
                          extras: extras),
                     at: indexForInserting(attack: attack,
                                           duration: duration,
                                           startPitch: startPitch,
                                           endPitch: endPitch))

        if extras != nil {
            hasExtras = true
        }

        if startPitch != endPitch {
            hasPortamento = true
        }

        isMonophonic = Self.determineIsMonophonic(notes)
        pitchRange = Self.determinePitchRange(notes)
        timeRange = Self.determineTimeRange(notes)
    }

    public func inserting(attack: TimeType,
                          duration: DurationType,
                          pitch: PitchType,
                          extras: Extras? = nil) -> Self {
        inserting(attack: attack,
                  duration: duration,
                  startPitch: pitch,
                  endPitch: pitch,
                  extras: extras)
    }

    public func inserting(attack: TimeType,
                          duration: DurationType,
                          startPitch: PitchType,
                          endPitch: PitchType,
                          extras: Extras? = nil) -> Self {
        var new = self

        new.insert(attack: attack,
                   duration: duration,
                   startPitch: startPitch,
                   endPitch: endPitch,
                   extras: extras)

        return new
    }

    public mutating func merge(with other: Self) {
        guard !other.notes.isEmpty
        else { return }

        guard !notes.isEmpty
        else { self = other; return }

        notes.append(contentsOf: other.notes)
        notes.sort()

        hasExtras = hasExtras || other.hasExtras
        hasPortamento = hasPortamento || other.hasPortamento
        isMonophonic = Self.determineIsMonophonic(notes)
        pitchRange = Self.mergePitchRanges(pitchRange,
                                           other.pitchRange)
        timeRange = Self.mergeTimeRanges(timeRange,
                                         other.timeRange)
    }

    public func merging(with other: Self) -> Self {
        var new = self

        new.merge(with: other)

        return new
    }

    public mutating func remove(attack: TimeType,
                                duration: DurationType,
                                pitch: PitchType,
                                extras: Extras? = nil) {
        remove(attack: attack,
               duration: duration,
               startPitch: pitch,
               endPitch: pitch,
               extras: extras)
    }

    public mutating func remove(attack: TimeType,
                                duration: DurationType,
                                startPitch: PitchType,
                                endPitch: PitchType,
                                extras: Extras? = nil) {
        guard let index = indexMatching(attack: attack,
                                        duration: duration,
                                        startPitch: startPitch,
                                        endPitch: endPitch,
                                        extras: extras)
        else { return }

        notes.remove(at: index)

        if extras != nil {
            hasExtras = Self.determineHasExtras(notes)
        }

        if startPitch != endPitch {
            hasPortamento = Self.determineHasPortamento(notes)
        }

        isMonophonic = Self.determineIsMonophonic(notes)
        pitchRange = Self.determinePitchRange(notes)
        timeRange = Self.determineTimeRange(notes)
    }

    public func removing(attack: TimeType,
                         duration: DurationType,
                         pitch: PitchType,
                         extras: Extras? = nil) -> Self {
        removing(attack: attack,
                 duration: duration,
                 startPitch: pitch,
                 endPitch: pitch,
                 extras: extras)
    }

    public func removing(attack: TimeType,
                         duration: DurationType,
                         startPitch: PitchType,
                         endPitch: PitchType,
                         extras: Extras? = nil) -> Self {
        var new = self

        new.remove(attack: attack,
                   duration: duration,
                   startPitch: startPitch,
                   endPitch: endPitch,
                   extras: extras)

        return new
    }
}
