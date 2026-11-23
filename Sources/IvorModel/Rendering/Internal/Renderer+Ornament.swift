// © 2026 John Gary Pusey (see LICENSE.md)

internal import IvorTiming
internal import XestiNumbers
internal import XestiTools

extension Renderer {

    // MARK: Internal Instance Methods

    //
    // A main note's span, from `start` to `end`, cut into the pieces its ornament sounds: the
    // main note alternating with its partner (resolution 15 of the grace-notes plan), then the
    // main note held for the rest. With no ornament, or a partner that can't be found, the note
    // is one piece.
    //
    // A span fill with a step partner is the odd number of equal notes nearest its time times
    // the rate, at least three, so it starts and ends on the main note (an even number, at least
    // two, when it starts on the partner); with a repeated or written partner, it's equal notes
    // at the rate. A count sounds the partner that many times at the rate, compressed if needed
    // to fit half the note.
    //
    internal func pieces(of index: Int,
                         from start: Number,
                         to end: Number) -> [Piece] {
        let source = sources[index]
        let plain = [Piece(end: end, partner: nil, start: start)]

        guard let ornament = source.ornamentation?.ornament
        else { return plain }

        let ornamentRules = _rules(for: ornament,
                                   part: source.part)
        let noteLength = _noteLength(of: ornament,
                                     rules: ornamentRules,
                                     at: start)

        guard let partner = _partner(of: ornament,
                                     source: source,
                                     rules: ornamentRules),
              noteLength > 0
        else { return plain }

        let execution = ornament.execution
        let startsOnPartner = (execution?.startNote ?? ornamentRules?.startNote ?? RenderingDefaults.ornamentStart) == .partner
        let isRepeat = if case .repeat = ornament.partner { true } else { false }
        let pattern = _pattern(of: ornament,
                               extent: execution?.extent ?? ornamentRules?.extent ?? Self._defaultExtent(of: ornament),
                               startsOnPartner: startsOnPartner,
                               length: end - start,
                               noteLength: noteLength)
        var pieces: [Piece] = []
        var time = start

        for isPartner in pattern.sequence {
            pieces.append(Piece(end: time + pattern.each,
                                partner: isPartner && !isRepeat ? partner : nil,
                                start: time))

            time += pattern.each
        }

        if time < end {
            if let last = pieces.last,
               last.partner == nil {
                pieces[pieces.count - 1].end = end
            } else {
                pieces.append(Piece(end: end, partner: nil, start: time))
            }
        }

        return pieces.isEmpty ? plain : pieces
    }

    // MARK: Private Type Methods

    //
    // A trill, a tremolo and an ornament with no sign fill their note; a mordent sounds its
    // partner once.
    //
    private static func _defaultExtent(of ornament: NoteTable<TimeType, PitchType>.Ornament) -> OrnamentExtent {
        if case .mordent? = ornament.sign {
            .count(AlternationCount(uintValue: 1).require())
        } else {
            .span(Proportion(numberValue: 1).require())
        }
    }

    private static func _evenNear(_ value: Number) -> Int {
        max(2, (round(value / 2) * 2).intValue)
    }

    private static func _oddNear(_ value: Number) -> Int {
        max(3, (round((value - 1) / 2) * 2 + 1).intValue)
    }

    // MARK: Private Instance Methods

    //
    // How long each alternating note lasts: the execution's rate, then — except for a measured
    // tremolo, which follows its strokes — the rules', then 12 notes per second.
    //
    private func _noteLength(of ornament: NoteTable<TimeType, PitchType>.Ornament,
                             rules: OrnamentRules?,
                             at time: Number) -> Number {
        switch ornament.execution?.rate {
        case let .noteValue(length):
            return TimeType.number(of: length.duration)

        case let .perSecond(rate):
            return clock.length(1 / rate.numberValue, time)

        case nil:
            break
        }

        if case let .tremolo(.measured(strokes))? = ornament.sign {
            return clock.subdivision(strokes) ?? clock.length(1 / RenderingDefaults.ornamentRate.numberValue, time)
        }

        return clock.length(1 / (rules?.rate ?? RenderingDefaults.ornamentRate).numberValue, time)
    }

    //
    // The pitches the main note alternates with: a step partner's written pitch, else the step
    // its rule gives from the start pitch (the execution's rule, the rules', or the diatonic step
    // in the key); the main pitch, for a repeat; or the written pitches.
    //
    private func _partner(of ornament: NoteTable<TimeType, PitchType>.Ornament,
                          source: Source,
                          rules: OrnamentRules?) -> [PitchType]? {
        switch ornament.partner {
        case let .pitches(pitches):
            return pitches

        case .repeat:
            return [source.startPitch]

        case let .step(side, written):
            if let written {
                return [written]
            }

            let rule = ornament.execution?.partnerRule ?? rules?.partnerRule ?? RenderingDefaults.partnerRule

            return source.startPitch.partner(on: side,
                                             rule: rule,
                                             key: clock.key(source.attack)).map { [$0] }
        }
    }

    //
    // Which notes the alternation sounds (`true` for the partner) and how long each lasts.
    //
    private func _pattern(of ornament: NoteTable<TimeType, PitchType>.Ornament,
                          extent: OrnamentExtent,
                          startsOnPartner: Bool,
                          length: Number,
                          noteLength: Number) -> (sequence: [Bool], each: Number) {
        switch extent {
        case let .count(alternations):
            let partners = Int(alternations.uintValue)
            let count = startsOnPartner ? 2 * partners - 1 : 2 * partners
            let sequence = (0..<count).map { startsOnPartner ? $0.isMultiple(of: 2) : !$0.isMultiple(of: 2) }
            let maximum = RenderingDefaults.mordentMaximumShare.numberValue * length / Number(count)

            return (sequence, min(noteLength, maximum))

        case let .span(share):
            let fill = share.numberValue * length
            let notes = fill / noteLength
            let count = switch ornament.partner {
            case .pitches:
                max(2, round(notes).intValue)

            case .repeat:
                max(1, round(notes).intValue)

            case .step where startsOnPartner:
                Self._evenNear(notes)

            case .step:
                Self._oddNear(notes)
            }
            let sequence = (0..<count).map { startsOnPartner ? $0.isMultiple(of: 2) : !$0.isMultiple(of: 2) }

            return (sequence, fill / Number(count))
        }
    }

    //
    // The rules for an ornament's kind: a trill's, a mordent's or a tremolo's; with no sign, the
    // trill rules for a step partner, else the tremolo rules. A measured tremolo's rate comes
    // from its strokes, not the rules (see `_noteLength`).
    //
    private func _rules(for ornament: NoteTable<TimeType, PitchType>.Ornament,
                        part: Int) -> OrnamentRules? {
        let partRules = rules[part]

        switch ornament.sign {
        case .mordent:
            return partRules.mordent

        case .tremolo:
            return partRules.tremolo

        case .trill:
            return partRules.trill

        case nil:
            if case .step = ornament.partner {
                return partRules.trill
            }

            return partRules.tremolo
        }
    }
}
