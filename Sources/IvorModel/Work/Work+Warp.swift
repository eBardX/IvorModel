// © 2025–2026 John Gary Pusey (see LICENSE.md)

public import IvorTiming

extension Work {

    // MARK: Public Instance Methods

    /// Returns a new work with beat-time content converted to wall time, using this work's own
    /// tempo map — a fixed-media export at the tempo curve currently in effect. `nil` for
    /// wall-time content, which has no tempo map to convert with.
    ///
    /// Always succeeds, even on a locked work: this returns an independent, unlocked copy rather
    /// than mutating `self`, so ``Work/isLocked`` — which only protects `self.content` from
    /// direct reassignment — does not apply here.
    public func warped() -> Work? {
        guard let newContent = Self._warped(content)
        else { return nil }

        return Work(name: name,
                    content: newContent)
    }

    // MARK: Private Type Methods

    private static func _warped(_ content: Content) -> Content? {
        switch content {
        case let .absoluteBeat(parts, tempoMap):
            let timeConverter = TimeConverter(tempoMap: tempoMap)

            return .absoluteWall(parts.map { part in
                convertBeatTimes(in: part,
                                 using: timeConverter)
            })

        case let .keyboardBeat(parts, tempoMap):
            let timeConverter = TimeConverter(tempoMap: tempoMap)

            return .keyboardWall(parts.map { part in
                convertBeatTimes(in: part,
                                 using: timeConverter)
            })

        case let .standardBeat(parts, tempoMap):
            let timeConverter = TimeConverter(tempoMap: tempoMap)

            return .standardWall(parts.map { part in
                convertBeatTimes(in: part,
                                 using: timeConverter)
            })

        default:
            return nil
        }
    }
}

// MARK: -

extension Work {

    // MARK: Public Instance Methods

    /// Returns a new work with wall-time content converted to beat time using the given tempo
    /// map — re-deriving editable beat-time content from a wall-time recording, e.g. a tapped-in
    /// or detected tempo map. `nil` for beat-time content, which is already beat time.
    ///
    /// Unlike ``Work/convert(timeBasis:pitchNotation:context:)``'s own wall-to-beat conversion,
    /// which always produces content backed by a fresh, empty tempo map, the beat-time content
    /// this method returns carries `tempoMap` itself forward as its own tempo map — the point of
    /// this method is to hand back editable beat-time content that stays coherent with the very
    /// tempo curve used to derive its beat positions.
    ///
    /// Always succeeds, even on a locked work — see ``warped()``'s doc comment for why.
    ///
    /// - Parameter tempoMap:   The tempo map to convert wall times to beat times with.
    public func unwarped(using tempoMap: TempoMap) -> Work? {
        guard let newContent = Self._unwarped(content,
                                              using: tempoMap)
        else { return nil }

        return Work(name: name,
                    content: newContent)
    }

    // MARK: Private Type Methods

    private static func _unwarped(_ content: Content,
                                  using tempoMap: TempoMap) -> Content? {
        let timeConverter = TimeConverter(tempoMap: tempoMap)

        switch content {
        case let .absoluteWall(parts):
            return .absoluteBeat(parts.map { part in
                convertWallTimes(in: part,
                                 using: timeConverter)
            },
                                 tempoMap)

        case let .keyboardWall(parts):
            return .keyboardBeat(parts.map { part in
                convertWallTimes(in: part,
                                 using: timeConverter)
            },
                                 tempoMap)

        case let .standardWall(parts):
            return .standardBeat(parts.map { part in
                convertWallTimes(in: part,
                                 using: timeConverter)
            },
                                 tempoMap)

        default:
            return nil
        }
    }
}

// MARK: -

extension Work {

    // MARK: Public Instance Methods

    /// Returns a new work with beat-time, absolute-pitch content converted to wall time, using
    /// this work's own tempo map, with note pitches varispeed-shifted to reflect the tempo in
    /// effect at each note's attack and release. `nil` for any content other than `.absoluteBeat`
    /// — no other pitch notation has an exact representation for a continuous pitch shift (see
    /// ``NoteTable/varispeeded(using:normalTempo:)``).
    ///
    /// The parameter maps (`dynamicMap`/`instrumentMap`/`panMap`) go through the same plain time
    /// conversion ``warped()`` uses — none of them carries a pitch axis, so none is
    /// varispeed-shifted; only note pitches are.
    ///
    /// Always succeeds, even on a locked work — see ``warped()``'s doc comment for why.
    ///
    /// - Parameter normalTempo:   The reference tempo used for pitch shifting. Defaults to
    ///                            `.default`.
    public func varispeeded(normalTempo: Tempo = .default) -> Work? {
        guard case let .absoluteBeat(parts, tempoMap) = content
        else { return nil }

        let timeConverter = TimeConverter(tempoMap: tempoMap)
        let newParts = parts.map { part in
            Part(name: part.name,
                 noteTable: part.noteTable.varispeeded(using: tempoMap,
                                                       normalTempo: normalTempo),
                 dynamicMap: Self.convertBeatTimes(in: part.dynamicMap,
                                                   using: timeConverter),
                 instrumentMap: Self.convertBeatTimes(in: part.instrumentMap,
                                                      using: timeConverter),
                 panMap: Self.convertBeatTimes(in: part.panMap,
                                               using: timeConverter))
        }

        return Work(name: name,
                    content: .absoluteWall(newParts))
    }
}
