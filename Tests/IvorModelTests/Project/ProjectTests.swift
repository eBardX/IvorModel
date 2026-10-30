// © 2025–2026 John Gary Pusey (see LICENSE.md)

import Foundation
@testable import IvorModel
import IvorTiming
import IvorTuning
import Testing
import XestiArchive
import XestiMarkov

struct ProjectTests {
}

// MARK: -

extension ProjectTests {
    @Test
    func fetchTemplate() throws {
        let mc = try #require(MarkovChain<Template.State<BeatTime, Pitch>>())
        let tmpl = Template(name: "My Template", content: .standardBeat(Template.Model(chains: .joint(mc))))
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
    func load_skipsTemplateInOldFormat() throws {
        let markovChain = try #require(MarkovChain<Template.State<BeatTime, Pitch>>())
        let current = Template(name: "Current", content: .standardBeat(Template.Model(chains: .joint(markovChain))))
        let old = Template(name: "Old", content: .standardBeat(Template.Model(chains: .joint(markovChain))))
        let work = Work(name: "My Work")
        var project = Project()

        project.updateTemplate(current)
        project.updateTemplate(old)
        project.updateWork(work)

        //
        // Rewrites `old` as a template in an earlier format version.
        //
        let root = try project.save().unzip()
        let templates = try #require(root.fileWrappers?["templates"])
        let oldFileName = "\(old.templateID.stringValue).sexp"
        let oldFile = try #require(templates.fileWrappers?[oldFileName])
        let oldData = try #require(oldFile.regularFileContents)
        let oldText = try #require(String(bytes: oldData, encoding: .utf8))
            .replacingOccurrences(of: "(version \(Template.currentVersion))", with: "(version 3)")

        #expect(oldText.contains("(version 3)"))

        templates.removeFileWrapper(oldFile)
        templates.addRegularFile(withContents: Data(oldText.utf8),
                                 preferredFilename: oldFileName)

        let loaded = try Project.load(from: root.zip())

        #expect(loaded.fetchTemplate(current.templateID) != nil)
        #expect(loaded.fetchTemplate(old.templateID) == nil)
        #expect(loaded.fetchWork(work.workID) != nil)
        #expect(loaded.skippedTemplates.map(\.templateID) == [old.templateID])
        #expect(loaded.skippedTemplates.first?.name == "Old")
    }

    @Test
    func load_skipsTemplateMissingAKey() throws {
        let markovChain = try #require(MarkovChain<Template.State<BeatTime, Pitch>>())
        let template = Template(name: "Partial", content: .standardBeat(Template.Model(chains: .joint(markovChain))))
        var project = Project()

        project.updateTemplate(template)

        let root = try project.save().unzip()

        try _rewrite(root,
                     ["templates", "\(template.templateID.stringValue).sexp"]) {
            $0.replacingOccurrences(of: "analysisSummary", with: "somethingElse")
        }

        let loaded = try Project.load(from: root.zip())
        let skipped = try #require(loaded.skippedTemplates.first)

        #expect(loaded.templates.isEmpty)
        #expect(skipped.templateID == template.templateID)
        #expect(skipped.name == "Partial")
        #expect(!skipped.reason.isEmpty)
        #expect(try Project.load(from: loaded.save()).skippedTemplates.isEmpty)
    }

    @Test
    func load_keepsUnreadableWork() throws {
        let readable = Work(name: "Readable")
        let unreadable = Work(name: "Unreadable")
        var project = Project()

        project.updateWork(readable)
        project.updateWork(unreadable)

        let root = try project.save().unzip()
        let path = ["works", "\(unreadable.workID.stringValue).sexp"]

        try _rewrite(root, path) {
            $0.replacingOccurrences(of: "(version \(Work.currentVersion))", with: "(version 3)")
        }

        let original = try _contents(of: root, path)
        let loaded = try Project.load(from: root.zip())
        let kept = try #require(loaded.unreadableWorks.first)

        #expect(loaded.works.map(\.workID) == [readable.workID])
        #expect(kept.workID == unreadable.workID)
        #expect(kept.name == "Unreadable")
        #expect(!kept.reason.isEmpty)

        //
        // Saved, it comes back unread, its file unchanged.
        //
        let resavedRoot = try loaded.save().unzip()
        let reloaded = try Project.load(from: resavedRoot.zip())

        #expect(reloaded.unreadableWorks.map(\.workID) == [unreadable.workID])
        #expect(try _contents(of: resavedRoot, path) == original)
    }

    @Test
    func load_missingWorkFile_isForgottenOnSave() throws {
        let work = Work(name: "Gone")
        var project = Project()

        project.updateWork(work)

        let root = try project.save().unzip()
        let works = try #require(root.fileWrappers?["works"])

        try works.removeFileWrapper(#require(works.fileWrappers?["\(work.workID.stringValue).sexp"]))

        let loaded = try Project.load(from: root.zip())

        #expect(loaded.unreadableWorks.map(\.workID) == [work.workID])
        #expect(loaded.unreadableWorks.first?.name == nil)
        #expect(try Project.load(from: loaded.save()).unreadableWorks.isEmpty)
    }

    @Test
    func removeUnreadableWork() throws {
        let work = Work(name: "Unreadable")
        var project = Project()

        project.updateWork(work)

        let root = try project.save().unzip()

        try _rewrite(root, ["works", "\(work.workID.stringValue).sexp"]) {
            $0.replacingOccurrences(of: "(version \(Work.currentVersion))", with: "(version 3)")
        }

        var loaded = try Project.load(from: root.zip())

        #expect(loaded.removeUnreadableWork(work.workID)?.workID == work.workID)
        #expect(loaded.removeUnreadableWork(work.workID) == nil)
        #expect(loaded.unreadableWorks.isEmpty)
        #expect(try Project.load(from: loaded.save()).unreadableWorks.isEmpty)
    }

    @Test
    func removeTemplate() throws {
        let mc = try #require(MarkovChain<Template.State<BeatTime, Pitch>>())
        let tmpl = Template(name: "My Template", content: .standardBeat(Template.Model(chains: .joint(mc))))
        var project = Project()

        _ = project.updateTemplate(tmpl)
        let removed = try project.removeTemplate(tmpl.templateID)

        #expect(removed == tmpl)
        #expect(project.templates.isEmpty)
    }

    @Test
    func removeTemplate_locked_throws() throws {
        let mc = try #require(MarkovChain<Template.State<BeatTime, Pitch>>())
        var tmpl = Template(name: "My Template", content: .standardBeat(Template.Model(chains: .joint(mc))))
        var project = Project()

        tmpl.isLocked = true
        _ = project.updateTemplate(tmpl)

        let error = #expect(throws: Project.Error.self) {
            try project.removeTemplate(tmpl.templateID)
        }

        guard case let .templateIsLocked(templateID) = error
        else { Issue.record("Expected templateIsLocked, got \(String(describing: error))"); return }

        #expect(templateID == tmpl.templateID)
        #expect(project.fetchTemplate(tmpl.templateID) == tmpl)
    }

    @Test
    func removeTemplate_missing() throws {
        var project = Project()
        let id = TemplateID()

        #expect(try project.removeTemplate(id) == nil)
    }

    @Test
    func removeWork() throws {
        let work = Work(name: "Concerto")
        var project = Project()

        _ = project.updateWork(work)
        let removed = try project.removeWork(work.workID)

        #expect(removed == work)
        #expect(project.works.isEmpty)
    }

    @Test
    func removeWork_locked_throws() {
        var work = Work(name: "Concerto")
        var project = Project()

        work.isLocked = true
        _ = project.updateWork(work)

        let error = #expect(throws: Project.Error.self) {
            try project.removeWork(work.workID)
        }

        guard case let .workIsLocked(workID) = error
        else { Issue.record("Expected workIsLocked, got \(String(describing: error))"); return }

        #expect(workID == work.workID)
        #expect(project.fetchWork(work.workID) == work)
    }

    @Test
    func removeWork_missing() throws {
        var project = Project()
        let id = WorkID()

        #expect(try project.removeWork(id) == nil)
    }

    @Test
    func updateTemplate_existing() throws {
        let mc = try #require(MarkovChain<Template.State<BeatTime, Pitch>>())
        let tmpl = Template(name: "My Template", content: .standardBeat(Template.Model(chains: .joint(mc))))
        var project = Project()

        _ = project.updateTemplate(tmpl)

        let replaced = project.updateTemplate(tmpl)

        #expect(replaced)
    }

    @Test
    func updateTemplate_new() throws {
        let mc = try #require(MarkovChain<Template.State<BeatTime, Pitch>>())
        let tmpl = Template(name: "My Template", content: .standardBeat(Template.Model(chains: .joint(mc))))
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

// MARK: - Private Functions

//
// The contents of the file at `path` in a saved project's unzipped `root`.
//
private func _contents(of root: FileWrapper,
                       _ path: [String]) throws -> Data {
    let directory = try #require(root.fileWrappers?[path[0]])
    let file = try #require(directory.fileWrappers?[path[1]])

    return try #require(file.regularFileContents)
}

//
// Replaces the text of the file at `path` in a saved project's unzipped `root`.
//
private func _rewrite(_ root: FileWrapper,
                      _ path: [String],
                      _ transform: (String) -> String) throws {
    let directory = try #require(root.fileWrappers?[path[0]])
    let file = try #require(directory.fileWrappers?[path[1]])
    let data = try #require(file.regularFileContents)
    let text = try #require(String(bytes: data, encoding: .utf8))
    let newText = transform(text)

    #expect(newText != text)

    directory.removeFileWrapper(file)
    directory.addRegularFile(withContents: Data(newText.utf8),
                             preferredFilename: path[1])
}
