// SortOCPList - ordered set of ordered pairs in which each ordered pair,
// (Ton, Pc), gives the onset time, Ton, and the chromatic pitch, Pc, of a
// single note or sequence of tied notes in the passage to be analysed. It is
// assumed that the elements of SortedOCPList have been sorted by increasing
// onset time and chromatic pitch, with priority given to onset time.

// x mod y = x - (y * floor(x / y))

// PN == "pitch name" == e.g., .cNatural4, .bFlat5
// PNC == "pitch name class" == e.g., .cNatural, .bFlat
// Pc == "chromatic pitch" == e.g., 0, 39 (.aNatural0 == 0, .cNatural4 == 39)
// "MIDI note number" == Pc + 21
// "chromatic pitch interval" between Pc,1 and Pc,2 == Pc,2 - Pc,1
// Pm == "morphetic pitch": .aNatural0 == 0, .aDoubleFlat0 == 0, .cNatural4 == 23, .cSharp4 == 23
// "morphetic pitch interval" between Pm,1 and Pm,2 == Pm,2 - Pm,1
// "chromamorphetic pitch" == (Pc, Pm)
// "chromamorphetic pitch interval" between (Pc,1, Pm,1) and (Pc,2, Pm,2) == (Pc,2 - Pc,1, Pm,2 - Pm,1)
// "chroma": c = Pc mod 12; Pc == (c - 3) mod 12
// "chroma interval" or "pitch class interval" from c1 to c2 == (c2 - c1) mod 12
// "morph": m = Pm mod 7; Pm == ?
// "morph interval" from m1 to m2 == (m2 - m1) mod 7

public typealias Chroma         = Int       // c; c == Pc mod 12; Pc == (c - 3) mod 12
public typealias ChromaticPitch = Int       // Pc; 0 == A0; 39 == C4; MIDI note number == Pc + 21
public typealias Morph          = Int       // m; m == Pm mod 7; Pm == ?
public typealias MorpheticPitch = Int       // Pm; 0 == A0, Ab0, A#0; 23 == C4, Cb4, C#4
public typealias OnsetTime      = Int
public typealias PitchName      = String    // PN;

public struct OrderedChromaticPitch: Comparable {
    let time: OnsetTime
    let pitch: ChromaticPitch

    public static func < (lhs: Self, rhs: Self) -> Bool {
        (lhs.time, lhs.pitch) < (rhs.time, rhs.pitch)
    }
}

public struct OrderedPitchName {
    let time: OnsetTime
    let name: PitchName
}

func modulo (_ n: Int,
             _ m: Int) -> Int {
    let rem = n % m

    return rem != 0 && (n ^ m) < 0 ? rem + m : rem
}

public func ps13s1(sortedOCPList: [OrderedChromaticPitch],
                   kpre: Int,
                   kpost: Int) -> [OrderedPitchName] {
    guard !sortedOCPList.isEmpty
    else { return [] }

    let chromaList = computeChromaList(sortedOCPList)
    let chromaVectorList = computeChromaVectorList(chromaList, kpre, kpost)
    let morphList = computeMorphList(chromaList, chromaVectorList)
    let morpheticPitchList = computeMorpheticPitchList(sortedOCPList, morphList)

    return computeOPNList(sortedOCPList, morpheticPitchList)
}

func computeChromaList(_ sortedOCPList: [OrderedChromaticPitch]) -> [Int] {
    sortedOCPList.map { modulo($0.pitch, 12) }
}

func computeChromaVectorList(_ chromaList: [Chroma],
                             _ kPre: Int,
                             _ kPost: Int) -> [[Chroma]] {
    let count = chromaList.count

    var thisVector: [Chroma] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]

    for idx in 0..<min(count, kPost) {
        thisVector[chromaList[idx]] += 1
    }

    var chromaVectorList: [[Chroma]] = [thisVector]

    for idx in 1..<count {
        if idx + kPost <= count {
            thisVector[chromaList[idx + kPost - 1]] += 1
        }

        if idx - kPre > 0 {
            thisVector[chromaList[idx - kPre - 1]] -= 1
        }

        chromaVectorList.append(thisVector)
    }

    return chromaVectorList
}

func computeMorphList(_ chromaList: [Chroma],
                      _ chromaVectorList: [[Chroma]]) -> [Morph] {
    let count = chromaList.count

    var morphList = [Morph?](repeating: nil,
                             count: chromaList.count)

    // First compute m0

    let initMorph = [0, 1, 1, 2, 2, 3, 4, 4, 5, 5, 6, 6]
    let c0 = chromaList[0]
    let m0 = initMorph[c0]
    let morphInt = [0, 1, 1, 2, 2, 3, 3, 4, 5, 5, 6, 6]

    // Compute Eq. 6.8 for 0 ≤ ct ≤ 11

    var tonicMorphForTonicChroma = [Morph?](repeating: nil,
                                            count: 12)

    for ct in 0...11 {
        tonicMorphForTonicChroma[ct] = modulo(m0 - morphInt[modulo(c0 - ct, 12)], 7)
    }

    var morphForTonicChroma = [Morph?](repeating: nil,
                                       count: 12)
    var tonicChromaSetForMorph = [[Chroma]](repeating: [],
                                            count: 7)
    var morphStrength = [Int?](repeating: nil,
                               count: 7)

    for j in 0..<count {
        // Compute Eq. 6.1 for 0 ≤ ct ≤ 11

        let c = chromaList[j]

        for ct in 0...11 {
            morphForTonicChroma[ct] = modulo(morphInt[modulo(c - ct, 12)] +
                                             (tonicMorphForTonicChroma[ct] ?? 0),
                                             7)
        }

        // Compute Eq. 6.3 for 0 ≤ m ≤ 6

        for m in 0...6 {
            tonicChromaSetForMorph[m] = []
        }

        for m in 0...6 {
            for ct in 0...11 where morphForTonicChroma[ct] == m {
                tonicChromaSetForMorph[m] = [ct] + tonicChromaSetForMorph[m]
            }
        }

        // Compute Eq. 6.4 for 0 ≤ m ≤ 6

        for m in 0...6 {
            var sum = 0

            for ct in tonicChromaSetForMorph[m] {
                sum += chromaVectorList[j][ct]
            }

            morphStrength[m] = sum
        }

        // Compute Eq. 6.5

        let maxMorphStrength = morphStrength.reduce(0) { max($0, $1 ?? 0) }

        morphList[j] = morphStrength.firstIndex(of: maxMorphStrength)
    }

    return morphList.map { $0 ?? 0 }
}

func computeMorpheticPitchList(_ sortedOCPList: [OrderedChromaticPitch],
                               _ morphList: [Morph]) -> [MorpheticPitch] {
    var morpheticPitchList: [MorpheticPitch] = []

    for idx in 0..<sortedOCPList.count {
        let chromaticPitch = sortedOCPList[idx].pitch
        let morph = morphList[idx]
        let morphOct1 = chromaticPitch / 12
        let morphOct2 = morphOct1 + 1
        let morphOct3 = morphOct1 - 1
        let mp1 = morphOct1 + (morph / 7)
        let mp2 = morphOct2 + (morph / 7)
        let mp3 = morphOct3 + (morph / 7)
        let chroma = modulo(chromaticPitch, 12)
        let cp = morphOct1 + (chroma / 12)
        let diffList = [abs(cp - mp1), abs(cp - mp2), abs(cp - mp3)]
        let morphOctList = [morphOct1, morphOct2, morphOct3]
        let minMorph = diffList.reduce(diffList[0]) { min($0, $1) }
        let bestMorphOct = morphOctList[diffList.firstIndex(of: minMorph) ?? 0]
        let bestMorpheticPitch = morph + (7 * bestMorphOct)

        morpheticPitchList.append(bestMorpheticPitch)
    }

    return morpheticPitchList
}

func computeOPNList(_ sortedOCPList: [OrderedChromaticPitch],
                    _ morpheticPitchList: [MorpheticPitch]) -> [OrderedPitchName] {
    var opnList: [OrderedPitchName] = []

    for idx in 0..<sortedOCPList.count {
        let pn = p2pn(sortedOCPList[idx].pitch,
                      morpheticPitchList[idx])

        opnList.append(OrderedPitchName(time: sortedOCPList[idx].time,
                                        name: pn))
    }

    return opnList
}

func p2pn(_ cPitch: ChromaticPitch,
          _ mPitch: MorpheticPitch) -> PitchName {
    let morph = modulo(mPitch, 7)
    let letterName = ["A", "B", "C", "D", "E", "F", "G"][morph]
    let undisplacedChroma = [0, 2, 3, 5, 7, 8, 10][morph]
    let displacement = cPitch - (12 * (mPitch / 7)) - undisplacedChroma

    var accidental = ""

    if displacement != 0 {
        let accidentalChar = displacement < 0 ? "f" : "s"

        for _ in 0..<abs(displacement) {
            accidental += accidentalChar
        }
    } else {
        accidental = "n"
    }

    var asaOctaveNumber = mPitch / 7

    if morph > 1 {
        asaOctaveNumber += 1
    }

    return "\(letterName)\(accidental)\(asaOctaveNumber)"
}
