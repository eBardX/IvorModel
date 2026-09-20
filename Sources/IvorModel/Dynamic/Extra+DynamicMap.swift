// © 2025–2026 John Gary Pusey (see LICENSE.md)

public import XestiTools

extension Extra {

    // MARK: Public Type Properties

    /// The literal text of a dynamics mark that falls outside ``Dynamic``'s
    /// ten named levels (e.g. `"sfz"`, `"rfz"`), attached to a ``DynamicMap``
    /// entry inserted at the previously-held level so the mark isn't
    /// silently dropped. Payload: a single `.string`.
    public static let dynamicMark = Self(name: "dynamicMark")

    /// The MIDI Expression Controller value (Control Change 11, 0–127) in
    /// effect at a ``DynamicMap`` entry, layered on top of note-on velocity.
    /// Payload: a single `.int`.
    public static let expressionValue = Self(name: "expressionValue")

    /// The pre-quantization velocity (0–127, MIDI-style scale) a
    /// ``DynamicMap`` entry's ``Dynamic`` level was derived from. Payload: a
    /// single `.int`.
    public static let velocity = Self(name: "velocity")
}
