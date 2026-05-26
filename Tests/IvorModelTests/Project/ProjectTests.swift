// © 2025–2026 John Gary Pusey (see LICENSE.md)

@testable import IvorModel
import IvorTiming
import IvorTuning
import Testing
import XestiMarkov

struct ProjectTests {
}

// MARK: -

extension ProjectTests {
    @Test
    func fetchTemplate() throws {
        let mc = try #require(MarkovChain<NoteEvent<BeatTime, Pitch>>())
        let tmpl = Template(name: "My Template", content: .standardBeat(mc))
        var project = Project()

        _ = project.updateTemplate(tmpl)

        #expect(project.fetchTemplate(tmpl.templateID) == tmpl)
    }

    @Test
    func fetchTemplate_missing() {
        let project = Project()
        let id = TemplateID()

        #expect(project.fetchTemplate(id) == nil)
    }

    @Test
    func fetchWork() {
        let work = Work(name: "Symphony")
        var project = Project()

        _ = project.updateWork(work)

        #expect(project.fetchWork(work.workID) == work)
    }

    @Test
    func fetchWork_missing() {
        let project = Project()
        let id = WorkID()

        #expect(project.fetchWork(id) == nil)
    }

    @Test
    func init_empty() {
        let project = Project()

        #expect(project.templates.isEmpty)
        #expect(project.works.isEmpty)
    }

    @Test
    func removeTemplate() throws {
        let mc = try #require(MarkovChain<NoteEvent<BeatTime, Pitch>>())
        let tmpl = Template(name: "My Template", content: .standardBeat(mc))
        var project = Project()

        _ = project.updateTemplate(tmpl)
        let removed = project.removeTemplate(tmpl.templateID)

        #expect(removed == tmpl)
        #expect(project.templates.isEmpty)
    }

    @Test
    func removeTemplate_missing() {
        var project = Project()
        let id = TemplateID()

        #expect(project.removeTemplate(id) == nil)
    }

    @Test
    func removeWork() {
        let work = Work(name: "Concerto")
        var project = Project()

        _ = project.updateWork(work)
        let removed = project.removeWork(work.workID)

        #expect(removed == work)
        #expect(project.works.isEmpty)
    }

    @Test
    func removeWork_missing() {
        var project = Project()
        let id = WorkID()

        #expect(project.removeWork(id) == nil)
    }

    @Test
    func updateTemplate_existing() throws {
        let mc = try #require(MarkovChain<NoteEvent<BeatTime, Pitch>>())
        let tmpl = Template(name: "My Template", content: .standardBeat(mc))
        var project = Project()

        _ = project.updateTemplate(tmpl)

        let replaced = project.updateTemplate(tmpl)

        #expect(replaced)
    }

    @Test
    func updateTemplate_new() throws {
        let mc = try #require(MarkovChain<NoteEvent<BeatTime, Pitch>>())
        let tmpl = Template(name: "My Template", content: .standardBeat(mc))
        var project = Project()

        let inserted = project.updateTemplate(tmpl)

        #expect(!inserted)
    }

    @Test
    func updateWork_existing() {
        let work = Work(name: "My Work")
        var project = Project()

        _ = project.updateWork(work)

        let replaced = project.updateWork(work)

        #expect(replaced)
    }

    @Test
    func updateWork_new() {
        let work = Work(name: "My Work")
        var project = Project()

        let inserted = project.updateWork(work)

        #expect(!inserted)
    }
}
