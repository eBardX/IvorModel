// © 2025–2026 John Gary Pusey (see LICENSE.md)

public import XestiTools

extension Extra {

    // MARK: Public Type Properties

    /// The combined 14-bit MIDI pan value (Control Change 10 MSB and
    /// Control Change 42 LSB, 0–16,383) in effect for a ``PanMap`` entry.
    /// Payload: a single `.int`.
    public static let midiPan = Self(name: "midiPan")
}
