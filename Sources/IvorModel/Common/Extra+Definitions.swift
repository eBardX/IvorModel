// © 2026 John Gary Pusey (see LICENSE.md)

public import XestiTools

internal import IvorSMPTE

// The definition of every extra declared in `Extra+Ivor.swift`, as data: what each is attached
// to, and what its payload holds. An extra added there gets its definition here.
extension Extra {

    // MARK: Public Type Properties

    /// The definitions of every extra Ivor attaches to the model, sorted by name.
    public static let definitions: [Definition] = (flagDefinitions + valueDefinitions).sorted { $0.name < $1.name }

    // MARK: Public Type Methods

    /// Returns the definition of the known extra with the given name.
    ///
    /// - Parameter name:   The name to look up. It must match exactly, including case.
    ///
    /// - Returns:  The definition, or `nil` if no known extra has that name.
    public static func definition(named name: Name) -> Definition? {
        definitions.first { $0.name == name }
    }

    /// Returns the definitions of the known extras attached to the given kind of model value.
    ///
    /// - Parameter target: The kind of model value.
    ///
    /// - Returns:  The definitions, sorted by name.
    public static func definitions(for target: Target) -> [Definition] {
        definitions.filter { $0.targets.contains(target) }
    }

    // MARK: Private Type Properties

    //
    // The bare flags, all on notes.
    //
    private static let flagDefinitions: [Definition] = [accent,
                                                        breathMark,
                                                        downBow,
                                                        harmonic,
                                                        marcato,
                                                        pizzicato,
                                                        staccato,
                                                        tenuto,
                                                        turn,
                                                        upBow].map {
        Definition(name: $0.name,
                   targets: [.note])
    }

    private static let frameRates = ValueSpec.string(SMPTEFrameRate.allCases.map(\.description))

    private static let midiByte = ValueSpec.int(0...127)

    private static let text = ValueSpec.string(nil)

    private static let ticks = ValueSpec.int(1...255)

    //
    // Every extra with a payload.
    //
    private static let valueDefinitions: [Definition] = [Definition(name: articulation.name,
                                                                    targets: [.note],
                                                                    values: [ValueSlot(.text, text)]),
                                                         Definition(name: attackVelocity.name,
                                                                    targets: [.note],
                                                                    values: [ValueSlot(.velocity, midiByte)]),
                                                         Definition(name: dynamicMark.name,
                                                                    targets: [.dynamicEntry],
                                                                    values: [ValueSlot(.mark, text)]),
                                                         Definition(name: expressionValue.name,
                                                                    targets: [.dynamicEntry],
                                                                    values: [ValueSlot(.expression, midiByte)]),
                                                         Definition(name: fingering.name,
                                                                    targets: [.note],
                                                                    values: [ValueSlot(.fingering, text)]),
                                                         Definition(name: instrumentAbbreviation.name,
                                                                    targets: [.instrumentEntry],
                                                                    values: [ValueSlot(.abbreviation, text)]),
                                                         Definition(name: instrumentName.name,
                                                                    targets: [.instrumentEntry],
                                                                    values: [ValueSlot(.name, text)]),
                                                         Definition(name: meterSymbol.name,
                                                                    targets: [.meterEntry],
                                                                    values: [ValueSlot(.symbol, .string(["common", "cut"]))]),
                                                         Definition(name: midiBank.name,
                                                                    targets: [.instrumentEntry],
                                                                    values: [ValueSlot(.bank, .int(0...16_383))]),
                                                         Definition(name: midiChannel.name,
                                                                    targets: [.part],
                                                                    values: [ValueSlot(.channel, .int(1...16))]),
                                                         Definition(name: midiKeyPressure.name,
                                                                    targets: [.note],
                                                                    values: [ValueSlot(.pressure, midiByte)]),
                                                         Definition(name: midiPan.name,
                                                                    targets: [.panEntry],
                                                                    values: [ValueSlot(.pan, .int(0...16_383))]),
                                                         Definition(name: midiProgram.name,
                                                                    targets: [.instrumentEntry],
                                                                    values: [ValueSlot(.program, .int(1...128))]),
                                                         Definition(name: midiTimeCode.name,
                                                                    targets: [.work],
                                                                    values: [ValueSlot(.frameRate, frameRates),
                                                                             ValueSlot(.ticksPerFrame, ticks)]),
                                                         Definition(name: midiTimeSignature.name,
                                                                    targets: [.meterEntry],
                                                                    values: [ValueSlot(.clocksPerClick, ticks),
                                                                             ValueSlot(.thirtySecondsPerQuarter, ticks)]),
                                                         Definition(name: midiUnpitched.name,
                                                                    targets: [.instrumentEntry],
                                                                    values: [ValueSlot(.noteNumber, .int(1...128))]),
                                                         Definition(name: midiVolume.name,
                                                                    targets: [.instrumentEntry],
                                                                    values: [ValueSlot(.volume, .double(0...100))]),
                                                         Definition(name: rampDuration.name,
                                                                    targets: [.tempoEntry],
                                                                    values: [ValueSlot(.duration, .positiveDouble)]),
                                                         Definition(name: rampEndTempo.name,
                                                                    targets: [.tempoEntry],
                                                                    values: [ValueSlot(.endTempo, .positiveDouble)]),
                                                         Definition(name: rampStartTempo.name,
                                                                    targets: [.tempoEntry],
                                                                    values: [ValueSlot(.startTempo, .positiveDouble)]),
                                                         Definition(name: releaseVelocity.name,
                                                                    targets: [.note],
                                                                    values: [ValueSlot(.velocity, .int(1...127))]),
                                                         Definition(name: slurEnd.name,
                                                                    targets: [.note],
                                                                    values: [ValueSlot(.slurID, text)],
                                                                    minimumValueCount: 0),
                                                         Definition(name: slurStart.name,
                                                                    targets: [.note],
                                                                    values: [ValueSlot(.slurID, text)],
                                                                    minimumValueCount: 0),
                                                         Definition(name: tempoText.name,
                                                                    targets: [.tempoEntry],
                                                                    values: [ValueSlot(.text, text)])]
}
