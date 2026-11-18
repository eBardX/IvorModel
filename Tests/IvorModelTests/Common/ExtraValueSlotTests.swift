// © 2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import Testing
import XestiTools

struct ExtraValueSlotTests {
}

// MARK: -

extension ExtraValueSlotTests {
    @Test
    func accepts_delegatesToSpec() {
        let slot = Extra.ValueSlot(.channel, .int(1...16))

        #expect(slot.accepts(.int(1)))
        #expect(!slot.accepts(.int(17)))
        #expect(!slot.accepts(.string("1")))
    }

    @Test
    func equality() {
        let slot1 = Extra.ValueSlot(.text, .string(nil))
        let slot2 = Extra.ValueSlot(.text, .string(nil))

        #expect(slot1 == slot2)
    }

    @Test
    func hashable() {
        let slots: Set = [Extra.ValueSlot(.text, .string(nil)),
                          Extra.ValueSlot(.text, .string(nil)),
                          Extra.ValueSlot(.mark, .string(nil))]

        #expect(slots.count == 2)
    }

    @Test
    func inequality() {
        let slot = Extra.ValueSlot(.text, .string(nil))

        #expect(slot != Extra.ValueSlot(.mark, .string(nil)))
        #expect(slot != Extra.ValueSlot(.text, .string(["a"])))
    }

    @Test
    func init_storesRoleAndSpec() {
        let slot = Extra.ValueSlot(.velocity, .int(0...127))

        #expect(slot.role == .velocity)
        #expect(slot.spec == .int(0...127))
    }
}
