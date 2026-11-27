// © 2025–2026 John Gary Pusey (see LICENSE.md)

public import IvorTiming

private import IvorTuning

extension Work {

    // MARK: Public Instance Methods

    /// Returns a new work with beat-time content converted to wall time, using this work’s own
    /// tempo map — a fixed-media export at the tempo curve currently in effect. `nil` for
    /// wall-time content, which has no tempo map to convert with. The new work keeps this
    /// work’s ``Work/smpteStartTime``, ``Work/info``, ``Work/extras``,
    /// ``Work/interpretationRules`` and ``Work/realizations``, and its parts keep their IDs,
    /// extras and interpretation rules. The meter table and key table are dropped, since wall
    /// time has no bars. Part marks and ornamentation convert with the notes, each written
    /// length at the tempo where it starts, and a measured tremolo gains a rate in notes per
    /// second, so it keeps its speed.
    ///
    /// Always succeeds, even on a locked work: this returns an independent, unlocked copy rather
    /// than mutating `self`, so ``Work/isLocked`` — which only protects `self` from being
    /// modified — does not apply here.
    ///
    /// Fermatas and caesuras are kept as signs by default. With `appliesFermataHolds`, their holds
    /// and pauses first slow the tempo, as ``RenderingOptions/FermataMode/tempoChanges`` does,
    /// and are then removed (see ``rendered(options:)``).
    ///
    /// - Parameter appliesFermataHolds:    Whether to turn fermata holds and caesura pauses into
    ///                                     time and remove their signs. Defaults to `false`.
    ///
    /// - Returns:  The converted work, or `nil` for wall-time content.
    public func warped(appliesFermataHolds: Bool = false) -> Work? {
        let source = appliesFermataHolds ? applyingTimeline(mode: .tempoChanges).work : self

        guard let newContent = Self.warpedContent(source.content)
        else { return nil }

        return Work(name: name,
                    content: newContent,
                    smpteStartTime: smpteStartTime,
                    info: info,
                    extras: extras,
                    interpretationRules: interpretationRules,
                    realizations: realizations)
    }

    // MARK: Internal Type Methods

    //
    // `content` converted to wall time with its own tempo map, or `nil` if it's already in wall
    // time. `convert(timeBasis:pitchNotation:context:dropsUnconvertibleNotes:appliesFermataHolds:)` uses it too.
    //
    internal static func warpedContent(_ content: Content) -> Content? {
        guard let body = content.body as? any BeatTimeBody
        else { return nil }

        return Content(body: _warpedBody(body))
    }
}

// MARK: -

extension Work {

    // MARK: Public Instance Methods

    /// Returns a new work with wall-time content converted to beat time using the given tempo
    /// map — re-deriving editable beat-time content from a wall-time recording, e.g. a tapped-in
    /// or detected tempo map. `nil` for beat-time content, which is already beat time. The new
    /// work keeps this work’s ``Work/smpteStartTime``, ``Work/info``, ``Work/extras``,
    /// ``Work/interpretationRules`` and ``Work/realizations``, and its parts keep their IDs,
    /// extras and interpretation rules. Part marks and ornamentation convert with the notes,
    /// each written length at the tempo where it starts.
    ///
    /// Unlike ``Work/convert(timeBasis:pitchNotation:context:dropsUnconvertibleNotes:appliesFermataHolds:)``’s own
    /// wall-to-beat conversion, which always produces content backed by a fresh, empty tempo map,
    /// the beat-time content this method returns carries `tempoMap` itself forward as its own tempo
    /// map — the point of this method is to hand back editable beat-time content that stays
    /// coherent with the very tempo curve used to derive its beat positions. Its meter table and
    /// key table start out empty.
    ///
    /// Always succeeds, even on a locked work — see ``warped(appliesFermataHolds:)``’s doc comment for why.
    ///
    /// - Parameter tempoMap:   The tempo map to convert wall times to beat times with.
    ///
    /// - Returns:  The converted work, or `nil` for beat-time content.
    public func unwarped(using tempoMap: TempoMap) -> Work? {
        guard let newContent = Self.unwarpedContent(content,
                                                    using: tempoMap)
        else { return nil }

        return Work(name: name,
                    content: newContent,
                    smpteStartTime: smpteStartTime,
                    info: info,
                    extras: extras,
                    interpretationRules: interpretationRules,
                    realizations: realizations)
    }

    // MARK: Internal Type Methods

    //
    // `content` converted to beat time with `tempoMap`, or `nil` if it's already in beat time.
    // `convert(timeBasis:pitchNotation:context:dropsUnconvertibleNotes:appliesFermataHolds:)` uses it too, with a
    // fresh, empty tempo map.
    //
    internal static func unwarpedContent(_ content: Content,
                                         using tempoMap: TempoMap) -> Content? {
        guard let body = content.body as? any WallTimeBody
        else { return nil }

        return Content(body: _unwarpedBody(body,
                                           using: tempoMap))
    }

    // MARK: Private Type Methods

    //
    // A beat-time body with `body`'s parts converted to beat time with `tempoMap`, which becomes
    // its tempo map; its meter and key tables start out empty.
    //
    private static func _unwarpedBody(_ body: some WallTimeBody,
                                      using tempoMap: TempoMap) -> any Work.Body {
        let timeConverter = TimeConverter(tempoMap: tempoMap)

        let parts = body.parts.map { part in
            convertWallTimes(in: part,
                             using: timeConverter)
        }

        return Work.BeatBody(parts: parts,
                             tempoMap: tempoMap)
    }

    //
    // A wall-time body with `body`'s parts, converted to wall time with its own tempo map.
    //
    private static func _warpedBody(_ body: some BeatTimeBody) -> any Work.Body {
        let timeConverter = TimeConverter(tempoMap: body.tempoMap)

        let parts = body.parts.map { part in
            convertBeatTimes(in: part,
                             using: timeConverter,
                             tempoMap: body.tempoMap)
        }

        return Work.WallBody(parts: parts)
    }
}

// MARK: -

extension Work {

    // MARK: Public Instance Methods

    /// Returns a new work with beat-time, absolute-pitch content converted to wall time, using
    /// this work’s own tempo map, with note pitches varispeed-shifted to reflect the tempo in
    /// effect at each note’s attack and release. `nil` for any content other than `.absoluteBeat`
    /// — no other pitch notation has an exact representation for a continuous pitch shift (see
    /// ``NoteTable/varispeeded(using:normalTempo:)``). The new work keeps this work’s
    /// ``Work/smpteStartTime``, ``Work/info``, ``Work/extras``, ``Work/interpretationRules`` and
    /// ``Work/realizations``, and its parts keep their IDs, extras and interpretation rules. Part
    /// marks and ornamentation convert with the notes, and grace pitches shift like the note’s
    /// own: a figure before it by the tempo at the attack, a figure after it by the tempo at the
    /// release.
    ///
    /// The parameter maps (`dynamicMap`, `panMap`) and the instrument table go through the same plain time
    /// conversion ``warped(appliesFermataHolds:)`` uses — none of them carries a pitch axis, so none is
    /// varispeed-shifted; only note pitches are.
    ///
    /// Works even on a locked work — see ``warped(appliesFermataHolds:)``’s doc comment for why.
    ///
    /// - Parameter normalTempo:    The reference tempo used for pitch shifting. Defaults to
    ///                             `.default`.
    ///
    /// - Returns:  The converted work, or `nil` for any content other than `.absoluteBeat`.
    ///
    /// - Throws:   ``Work/Error/transformFailure(kind:partID:detail:)`` with kind
    ///             ``Work/TransformKind/varispeed`` if shifting any note’s pitch by the tempo
    ///             ratio in effect produces a frequency outside the representable range.
    public func varispeeded(normalTempo: Tempo = .default) throws(Error) -> Work? {
        guard case let .absoluteBeat(parts, tempoMap, _, _) = content.cases
        else { return nil }

        let timeConverter = TimeConverter(tempoMap: tempoMap)
        var newParts: [Part<WallTime, Frequency>] = []

        for part in parts {
            let noteTable: NoteTable<WallTime, Frequency>

            do {
                noteTable = try part.noteTable.varispeeded(using: tempoMap,
                                                           normalTempo: normalTempo)
            } catch {
                throw .transformFailure(kind: .varispeed,
                                        partID: part.partID,
                                        detail: error.message)
            }

            newParts.append(Part(partID: part.partID,
                                 name: part.name,
                                 noteTable: noteTable,
                                 dynamicMap: Self.convertBeatTimes(in: part.dynamicMap,
                                                                   using: timeConverter),
                                 instrumentTable: Self.convertBeatTimes(in: part.instrumentTable,
                                                                        using: timeConverter),
                                 panMap: Self.convertBeatTimes(in: part.panMap,
                                                               using: timeConverter),
                                 pedals: part.pedals.mapValues { $0.mapTimes(timeConverter.wallTime(at:)) },
                                 markTable: part.markTable.convertedTimes(timeConverter.wallTime(at:)),
                                 interpretationRules: part.interpretationRules,
                                 extras: part.extras))
        }

        return Work(name: name,
                    content: .absoluteWall(newParts),
                    smpteStartTime: smpteStartTime,
                    info: info,
                    extras: extras,
                    interpretationRules: interpretationRules,
                    realizations: realizations)
    }
}
