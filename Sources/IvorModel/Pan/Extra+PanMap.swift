// © 2025–2026 John Gary Pusey (see LICENSE.md)

public import XestiTools

extension Extra {

    // MARK: Public Type Properties

    /// The combined 14-bit MIDI pan value (Control Change 10 MSB and
    /// Control Change 42 LSB, 0–16,383) in effect for a ``PanMap`` entry.
    /// Payload: a single `.int`.
    public static let midiPan = Self(name: "midiPan")

    /// The unclamped pan degree (beyond MusicXML's own ±90° clamp to
    /// ``Pan``'s -1...1 scale) of a ``PanMap`` entry, as MusicXML's
    /// `<sound pan="...">`/`<midi-instrument><pan>` declares it. Payload: a
    /// single `.double`.
    public static let panDegree = Self(name: "panDegree")
}
