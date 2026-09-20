// © 2025–2026 John Gary Pusey (see LICENSE.md)

public import XestiTools

extension Extra {

    // MARK: Public Type Properties

    /// The literal text of a dynamics mark that falls outside ``Dynamic``'s
    /// ten named levels (e.g. `"sfz"`, `"rfz"`), attached to a ``DynamicMap``
    /// entry inserted at the previously-held level so the mark isn't
    /// silently dropped. Payload: a single `.string`.
    public static let dynamicMark = Self(name: "dynamicMark")
}
