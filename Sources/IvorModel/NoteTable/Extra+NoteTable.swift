// © 2025–2026 John Gary Pusey (see LICENSE.md)

public import XestiTools

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

    /// The MIDI Polyphonic Key Pressure (Control Change-adjacent channel
    /// message, 0–127) peak value on a ``NoteTable`` note. Payload: a
    /// single `.int`.
    public static let midiKeyPressure = Self(name: "midiKeyPressure")

    /// A mordent ornament on a ``NoteTable`` note. Bare flag, no payload.
    public static let mordent = Self(name: "mordent")

    /// A pizzicato articulation on a ``NoteTable`` note. Bare flag, no
    /// payload.
    public static let pizzicato = Self(name: "pizzicato")

    /// This ``NoteTable`` note ends a slur. When the originating format can
    /// express overlapping/crossing slurs (MusicXML, Guido), payload is a
    /// single `.string` id matching the corresponding ``slurStart``; when
    /// it can't (ABC, always well-nested), this is a bare flag instead.
    public static let slurEnd = Self(name: "slurEnd")

    /// This ``NoteTable`` note begins a slur. When the originating format
    /// can express overlapping/crossing slurs (MusicXML, Guido), payload is
    /// a single `.string` id matching the corresponding ``slurEnd``; when
    /// it can't (ABC, always well-nested), this is a bare flag instead.
    public static let slurStart = Self(name: "slurStart")

    /// A staccato articulation on a ``NoteTable`` note. Bare flag, no
    /// payload.
    public static let staccato = Self(name: "staccato")

    /// A tenuto articulation on a ``NoteTable`` note. Bare flag, no payload.
    public static let tenuto = Self(name: "tenuto")

    /// A trill ornament on a ``NoteTable`` note. Bare flag, no payload.
    public static let trill = Self(name: "trill")

    /// A turn ornament on a ``NoteTable`` note. Bare flag, no payload.
    public static let turn = Self(name: "turn")

    /// An up-bow articulation on a ``NoteTable`` note. Bare flag, no
    /// payload.
    public static let upBow = Self(name: "upBow")
}
