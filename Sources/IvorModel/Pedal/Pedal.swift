// © 2026 John Gary Pusey (see LICENSE.md)

/// A pedal or footswitch that a part can hold down or let up over time.
///
/// Each pedal has its own timeline in a part, so one can stay down while
/// another changes. The raw values are the keys under which a part’s pedal
/// tables are encoded, so they are part of the file format.
public enum Pedal: String {
    /// The legato footswitch, which joins each note to the next.
    case legato

    /// The portamento footswitch, which makes each note glide from the
    /// previous one.
    case portamento

    /// The soft (una corda) pedal, which makes notes quieter and duller.
    case soft

    /// The sostenuto pedal, which keeps sounding only the notes held when it
    /// goes down.
    case sostenuto

    /// The sustain (damper) pedal, which keeps notes sounding after their
    /// keys are released.
    case sustain
}

// MARK: - CaseIterable

extension Pedal: CaseIterable {

    // MARK: Public Type Properties

    /// Every pedal, in the order a piano’s are usually listed: sustain,
    /// sostenuto and soft, then the legato and portamento footswitches.
    public static let allCases: [Self] = [.sustain,
                                          .sostenuto,
                                          .soft,
                                          .legato,
                                          .portamento]
}

// MARK: - Codable

extension Pedal: Codable {
}

// MARK: - CodingKeyRepresentable

extension Pedal: CodingKeyRepresentable {
}

// MARK: - Hashable

extension Pedal: Hashable {
}

// MARK: - Sendable

extension Pedal: Sendable {
}
