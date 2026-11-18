// © 2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import Testing
import XestiTools

struct ExtraValueSpecTests {
}

// MARK: -

extension ExtraValueSpecTests {
    @Test
    func accepts_bool() {
        #expect(Extra.ValueSpec.bool.accepts(.bool(false)))
        #expect(!Extra.ValueSpec.bool.accepts(.int(0)))
    }

    @Test
    func accepts_double_withinRange() {
        let spec = Extra.ValueSpec.double(0...100)

        #expect(spec.accepts(.double(0)))
        #expect(spec.accepts(.double(100)))
        #expect(!spec.accepts(.double(100.5)))
        #expect(!spec.accepts(.int(50)))
    }

    @Test
    func accepts_double_withoutRange() {
        #expect(Extra.ValueSpec.double(nil).accepts(.double(-1_000)))
    }

    @Test
    func accepts_int_withinRange() {
        let spec = Extra.ValueSpec.int(1...16)

        #expect(spec.accepts(.int(1)))
        #expect(spec.accepts(.int(16)))
        #expect(!spec.accepts(.int(0)))
        #expect(!spec.accepts(.double(1)))
    }

    @Test
    func accepts_int_withoutRange() {
        #expect(Extra.ValueSpec.int(nil).accepts(.int(-7)))
    }

    @Test
    func accepts_positiveDouble() {
        let spec = Extra.ValueSpec.positiveDouble

        #expect(spec.accepts(.double(0.001)))
        #expect(!spec.accepts(.double(0)))
        #expect(!spec.accepts(.double(-1)))
        #expect(!spec.accepts(.double(.infinity)))
        #expect(!spec.accepts(.double(.nan)))
        #expect(!spec.accepts(.int(1)))
    }

    @Test
    func accepts_string_withChoices() {
        let spec = Extra.ValueSpec.string(["common", "cut"])

        #expect(spec.accepts(.string("cut")))
        #expect(!spec.accepts(.string("Cut")))
        #expect(!spec.accepts(.bool(true)))
    }

    @Test
    func accepts_string_withoutChoices() {
        #expect(Extra.ValueSpec.string(nil).accepts(.string("")))
    }

    @Test
    func hashable() {
        let specs: Set<Extra.ValueSpec> = [.bool,
                                           .double(nil),
                                           .double(0...1),
                                           .int(nil),
                                           .int(nil),
                                           .positiveDouble,
                                           .string(nil),
                                           .string(["a"])]

        #expect(specs.count == 7)
    }
}
