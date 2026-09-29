// © 2026 John Gary Pusey (see LICENSE.md)

public import XestiTools

// The names of every `Extra` Ivor attaches to a model entry — a note, or a
// dynamic, instrument, pan, or tempo map entry — gathered in one place so
// that a name is never claimed twice. Each one’s documentation says which
// entries it’s attached to, and what its payload holds.
extension Extra {

    // MARK: Public Type Properties

    /// An accent articulation mark on a ``NoteTable`` note. Bare flag, no
    /// payload.
    public static let accent = Self(name: "accent")

    /// The literal text of an articulation, ornament, or technical mark
    /// that falls outside this vocabulary's closed Tier 1 names (e.g.
    /// `"staccatissimo"`, `"spiccato"`), attached to a ``NoteTable`` note.
    /// Payload: a single `.string`.
    public static let articulation = Self(name: "articulation")

    /// A breath-mark articulation on a ``NoteTable`` note. Bare flag, no
    /// payload.
    public static let breathMark = Self(name: "breathMark")

    /// A down-bow articulation on a ``NoteTable`` note. Bare flag, no
    /// payload.
    public static let downBow = Self(name: "downBow")

    /// The literal text of a dynamics mark that falls outside ``Dynamic``'s
    /// ten named levels (e.g. `"sfz"`, `"rfz"`), attached to a ``DynamicMap``
    /// entry inserted at the previously-held level so the mark isn't
    /// silently dropped. Payload: a single `.string`.
    public static let dynamicMark = Self(name: "dynamicMark")

    /// The MIDI Expression Controller value (Control Change 11, 0–127) in
    /// effect at a ``DynamicMap`` entry, layered on top of note-on velocity.
    /// Payload: a single `.int`.
    public static let expressionValue = Self(name: "expressionValue")

    /// A fermata on a ``NoteTable`` note. Bare flag, no payload.
    public static let fermata = Self(name: "fermata")

    /// The literal fingering text (e.g. `"1"`, `"2-3"`) on a ``NoteTable``
    /// note. Payload: a single `.string`.
    public static let fingering = Self(name: "fingering")

    /// A harmonic articulation on a ``NoteTable`` note. Bare flag, no
    /// payload.
    public static let harmonic = Self(name: "harmonic")

    /// A marcato articulation on a ``NoteTable`` note. Bare flag, no
    /// payload.
    public static let marcato = Self(name: "marcato")

    /// The MIDI bank number in effect for an ``InstrumentMap`` entry, as the
    /// combined 14-bit Bank Select value (Control Change 0 MSB and Control
    /// Change 32 LSB), numbered 1–16,384 to match MusicXML's own
    /// `<midi-bank>` convention. Payload: a single `.int`.
    public static let midiBank = Self(name: "midiBank")

    /// The MIDI channel (1–16) in effect for an ``InstrumentMap`` entry.
    /// Payload: a single `.int`.
    public static let midiChannel = Self(name: "midiChannel")

    /// The MIDI Polyphonic Key Pressure (Control Change-adjacent channel
    /// message, 0–127) peak value on a ``NoteTable`` note. Payload: a
    /// single `.int`.
    public static let midiKeyPressure = Self(name: "midiKeyPressure")

    /// The combined 14-bit MIDI pan value (Control Change 10 MSB and
    /// Control Change 42 LSB, 0–16,383) in effect for a ``PanMap`` entry.
    /// Payload: a single `.int`.
    public static let midiPan = Self(name: "midiPan")

    /// The General MIDI program number (1–128) in effect for an
    /// ``InstrumentMap`` entry, matching the 1-based convention both
    /// MusicXML's `<midi-program>` and ABC 2.1's `%%MIDI voice
    /// instrument=` directive use. Payload: a single `.int`.
    public static let midiProgram = Self(name: "midiProgram")

    /// The exact microseconds-per-quarter-note value of a MIDI tempo meta
    /// event, before it’s rounded to an integer BPM for a ``TempoMap``
    /// entry’s ``Tempo`` value. Payload: a single `.int`.
    public static let midiTempo = Self(name: "midiTempo")

    /// The SMPTE time division of a Standard MIDI File whose event times are
    /// measured in frames rather than beats. In a beat-time work it's attached
    /// to the ``TempoMap`` entry at beat zero; in a wall-time work, which has
    /// no tempo map, to each part's ``InstrumentMap`` entry at time zero.
    /// Payload: a `.string` holding the frame rate (a `SMPTEFrameRate`
    /// description, such as `"25"` or `"29.97DF"`), then an `.int` holding
    /// the number of ticks per frame.
    public static let midiTimeCode = Self(name: "midiTimeCode")

    /// The MIDI note number (1–128, MusicXML's 1-based convention) an
    /// unpitched ``InstrumentMap`` entry plays, as MusicXML's
    /// `<midi-instrument><midi-unpitched>` declares it. Payload: a single
    /// `.int`.
    public static let midiUnpitched = Self(name: "midiUnpitched")

    /// The MIDI Channel Volume (Control Change 7) in effect for an
    /// ``InstrumentMap`` entry, on MusicXML's 0–100 percent scale. Payload:
    /// a single `.double`.
    public static let midiVolume = Self(name: "midiVolume")

    /// A mordent ornament on a ``NoteTable`` note. Bare flag, no payload.
    public static let mordent = Self(name: "mordent")

    /// A pizzicato articulation on a ``NoteTable`` note. Bare flag, no
    /// payload.
    public static let pizzicato = Self(name: "pizzicato")

    /// The duration (in beats) of a JohnnySonic tempo ramp, attached to the
    /// ``TempoMap`` entry at the ramp’s start beat. Payload: a single
    /// `.double`.
    public static let rampDuration = Self(name: "rampDuration")

    /// The ending tempo (BPM) of a JohnnySonic tempo ramp, attached to the
    /// ``TempoMap`` entry at the ramp’s start beat. Payload: a single
    /// `.double`.
    public static let rampEndTempo = Self(name: "rampEndTempo")

    /// The starting tempo (BPM) of a JohnnySonic tempo ramp, attached to the
    /// ``TempoMap`` entry at the ramp’s start beat. Payload: a single
    /// `.double`.
    public static let rampStartTempo = Self(name: "rampStartTempo")

    /// This ``NoteTable`` note ends a slur. When the originating format can
    /// express overlapping/crossing slurs (MusicXML, Guido), payload is a
    /// single `.string` id matching the corresponding ``slurStart``; when
    /// it can't (ABC, always well-nested), this is a bare flag instead.
    public static let slurEnd = Self(name: "slurEnd")

    /// This ``NoteTable`` note starts a slur. When the originating format
    /// can express overlapping/crossing slurs (MusicXML, Guido), payload is
    /// a single `.string` id matching the corresponding ``slurEnd``; when
    /// it can't (ABC, always well-nested), this is a bare flag instead.
    public static let slurStart = Self(name: "slurStart")

    /// A staccato articulation on a ``NoteTable`` note. Bare flag, no
    /// payload.
    public static let staccato = Self(name: "staccato")

    /// The literal human-readable tempo text (e.g. `"Allegro"`) from an ABC
    /// `Q:` field or a Guido `\tempo` tag, attached to a ``TempoMap`` entry.
    /// Payload: a single `.string`.
    public static let tempoText = Self(name: "tempoText")

    /// A tenuto articulation on a ``NoteTable`` note. Bare flag, no payload.
    public static let tenuto = Self(name: "tenuto")

    /// A trill ornament on a ``NoteTable`` note. Bare flag, no payload.
    public static let trill = Self(name: "trill")

    /// A turn ornament on a ``NoteTable`` note. Bare flag, no payload.
    public static let turn = Self(name: "turn")

    /// An up-bow articulation on a ``NoteTable`` note. Bare flag, no
    /// payload.
    public static let upBow = Self(name: "upBow")

    /// The pre-quantization velocity (0–127, MIDI-style scale) a
    /// ``DynamicMap`` entry's ``Dynamic`` level was derived from. Payload: a
    /// single `.int`.
    public static let velocity = Self(name: "velocity")
}
