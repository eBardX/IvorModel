// © 2025–2026 John Gary Pusey (see LICENSE.md)

public import XestiTools

extension Extra {

    // MARK: Public Type Properties

    /// The MIDI bank number in effect for an ``InstrumentMap`` entry, as the
    /// combined 14-bit Bank Select value (Control Change 0 MSB and Control
    /// Change 32 LSB), numbered 1–16,384 to match MusicXML's own
    /// `<midi-bank>` convention. Payload: a single `.int`.
    public static let midiBank = Self(name: "midiBank")

    /// The MIDI channel (1–16) in effect for an ``InstrumentMap`` entry.
    /// Payload: a single `.int`.
    public static let midiChannel = Self(name: "midiChannel")

    /// The General MIDI program number (1–128) in effect for an
    /// ``InstrumentMap`` entry, matching the 1-based convention both
    /// MusicXML's `<midi-program>` and ABC 2.1's `%%MIDI voice
    /// instrument=` directive use. Payload: a single `.int`.
    public static let midiProgram = Self(name: "midiProgram")

    /// The MIDI note number (1–128, MusicXML's 1-based convention) an
    /// unpitched ``InstrumentMap`` entry plays, as MusicXML's
    /// `<midi-instrument><midi-unpitched>` declares it. Payload: a single
    /// `.int`.
    public static let midiUnpitched = Self(name: "midiUnpitched")

    /// The MIDI Channel Volume (Control Change 7) in effect for an
    /// ``InstrumentMap`` entry, on MusicXML's 0–100 percent scale. Payload:
    /// a single `.double`.
    public static let midiVolume = Self(name: "midiVolume")
}
