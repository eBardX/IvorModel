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
}
