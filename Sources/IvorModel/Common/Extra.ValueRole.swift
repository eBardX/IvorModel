// © 2026 John Gary Pusey (see LICENSE.md)

public import XestiTools

extension Extra {

    // MARK: Public Nested Types

    /// What one associated value of a known extra represents, so that an editor can label it (see
    /// ``Extra/ValueSlot``).
    public enum ValueRole {

        /// An abbreviated name, as of ``Extra/instrumentAbbreviation``.
        case abbreviation

        /// A combined 14-bit MIDI bank number, as of ``Extra/midiBank``.
        case bank

        /// A MIDI channel, as of ``Extra/midiChannel``.
        case channel

        /// MIDI clocks per metronome click, as of ``Extra/midiTimeSignature``.
        case clocksPerClick

        /// A duration in whole notes, as of ``Extra/rampDuration``.
        case duration

        /// A tempo a ramp ends at, as of ``Extra/rampEndTempo``.
        case endTempo

        /// A MIDI Expression Controller value, as of ``Extra/expressionValue``.
        case expression

        /// Fingering text, as of ``Extra/fingering``.
        case fingering

        /// An SMPTE frame rate, as of ``Extra/midiTimeCode``.
        case frameRate

        /// The text of a mark, as of ``Extra/dynamicMark``.
        case mark

        /// A mode name, as of ``Extra/keySignatureMode``.
        case mode

        /// A name, as of ``Extra/instrumentName``.
        case name

        /// A MIDI note number, as of ``Extra/midiUnpitched``.
        case noteNumber

        /// A combined 14-bit MIDI pan value, as of ``Extra/midiPan``.
        case pan

        /// A MIDI key pressure value, as of ``Extra/midiKeyPressure``.
        case pressure

        /// A MIDI program number, as of ``Extra/midiProgram``.
        case program

        /// The id of a slur, matching its start to its end, as of ``Extra/slurStart`` and
        /// ``Extra/slurEnd``.
        case slurID

        /// A tempo a ramp starts at, as of ``Extra/rampStartTempo``.
        case startTempo

        /// A display symbol, as of ``Extra/meterSymbol``.
        case symbol

        /// Literal text, as of ``Extra/articulation`` and ``Extra/tempoText``.
        case text

        /// Notated 32nd notes per MIDI quarter note, as of ``Extra/midiTimeSignature``.
        case thirtySecondsPerQuarter

        /// MIDI ticks per SMPTE frame, as of ``Extra/midiTimeCode``.
        case ticksPerFrame

        /// A MIDI key velocity, as of ``Extra/attackVelocity`` and ``Extra/releaseVelocity``.
        case velocity

        /// A volume, as of ``Extra/midiVolume``.
        case volume
    }
}

// MARK: - CaseIterable

extension Extra.ValueRole: CaseIterable {
}

// MARK: - Hashable

extension Extra.ValueRole: Hashable {
}

// MARK: - Sendable

extension Extra.ValueRole: Sendable {
}
