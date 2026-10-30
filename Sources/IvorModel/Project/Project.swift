// © 2025–2026 John Gary Pusey (see LICENSE.md)

public import Foundation

private import XestiArchive
private import XestiSexp
private import XestiTools

/// An Ivor project containing a collection of works and templates.
public struct Project {

    // MARK: Public Initializers

    /// Creates a new, empty project.
    public init() {
        self.name = ""
        self.skippedTemplates = []
        self.templateMap = [:]
        self.unreadableWorks = []
        self.workMap = [:]
    }

    // MARK: Public Instance Properties

    /// The display name of this project.
    public private(set) var name: String

    /// The templates left out when this project was loaded, because they couldn’t be read, in the
    /// order its file lists them. Empty for a new project.
    public let skippedTemplates: [SkippedTemplate]

    /// The works in this project’s file that couldn’t be read, in the order its file lists them.
    /// Saving keeps them as they were — see ``UnreadableWork``.
    public private(set) var unreadableWorks: [UnreadableWork]

    // MARK: Private Initializers

    private init(from file: FileWrapper) throws {
        let manifest = try Self._fetchManifest(from: file)
        let (templates, skippedTemplates) = Self._fetchTemplates(from: file,
                                                                 in: manifest)
        let (works, unreadableWorks) = Self._fetchWorks(from: file,
                                                        in: manifest)

        self.name = manifest.name
        self.skippedTemplates = skippedTemplates
        self.templateMap = Dictionary(uniqueKeysWithValues: templates.map { ($0.templateID, $0) })
        self.unreadableWorks = unreadableWorks
        self.workMap = Dictionary(uniqueKeysWithValues: works.map { ($0.workID, $0) })
    }

    // MARK: Private Instance Properties

    private var templateMap: [TemplateID: Template]
    private var workMap: [WorkID: Work]
}

// MARK: -

extension Project {

    // MARK: Public Type Methods

    /// Creates a project by loading from a file wrapper.
    ///
    /// A template or work that can’t be read — saved in an older format, say — doesn’t stop the
    /// rest of the project from loading. A template is left out (see ``skippedTemplates``), and
    /// saving the project drops it, since it can be analyzed again from its work. A work is kept
    /// unread (see ``unreadableWorks``), and saving the project writes it back as it was.
    ///
    /// - Parameter file:   The `FileWrapper` containing the serialized project data.
    ///
    /// - Returns:  A ``Project`` loaded from the file.
    ///
    /// - Throws:   ``Project/Error/loadFailure(_:)`` if the project cannot be loaded.
    public static func load(from file: FileWrapper) throws(Error) -> Project {
        do {
            return try Project(from: file.unzip())
        } catch let error as any EnhancedError {
            throw Error.loadFailure(error)
        } catch {
            throw Error.loadFailure(nil)
        }
    }

    // MARK: Public Instance Properties

    /// All templates in this project.
    public var templates: [Template] {
        Array(templateMap.values)
    }

    /// All works in this project.
    public var works: [Work] {
        Array(workMap.values)
    }

    // MARK: Public Instance Methods

    /// Returns the template with the given ID, or `nil` if not found.
    ///
    /// - Parameter templateID:     The ID of the template to fetch.
    ///
    /// - Returns:  The matching ``Template``, or `nil` if no template with that ID exists.
    public func fetchTemplate(_ templateID: TemplateID) -> Template? {
        templateMap[templateID]
    }

    /// Returns the work with the given ID, or `nil` if not found.
    ///
    /// - Parameter workID:     The ID of the work to fetch.
    ///
    /// - Returns:  The matching ``Work``, or `nil` if no work with that ID exists.
    public func fetchWork(_ workID: WorkID) -> Work? {
        workMap[workID]
    }

    /// Removes the template with the given ID from this project.
    ///
    /// - Parameter templateID:     The ID of the template to remove.
    ///
    /// - Returns:  The removed ``Template``, or `nil` if no template with that ID exists.
    ///
    /// - Throws:   ``Project/Error/templateIsLocked(_:)`` if the template is locked; the
    ///             project is left unchanged.
    @discardableResult
    public mutating func removeTemplate(_ templateID: TemplateID) throws(Error) -> Template? {
        guard let template = templateMap[templateID]
        else { return nil }

        guard !template.isLocked
        else { throw Error.templateIsLocked(templateID) }

        return templateMap.removeValue(forKey: templateID)
    }

    /// Removes the unreadable work with the given ID from this project, so that saving no longer
    /// keeps it.
    ///
    /// - Parameter workID:     The ID of the unreadable work to remove.
    ///
    /// - Returns:  The removed ``UnreadableWork``, or `nil` if no unreadable work has that ID.
    @discardableResult
    public mutating func removeUnreadableWork(_ workID: WorkID) -> UnreadableWork? {
        guard let index = unreadableWorks.firstIndex(where: { $0.workID == workID })
        else { return nil }

        return unreadableWorks.remove(at: index)
    }

    /// Removes the work with the given ID from this project.
    ///
    /// - Parameter workID:     The ID of the work to remove.
    ///
    /// - Returns:  The removed ``Work``, or `nil` if no work with that ID exists.
    ///
    /// - Throws:   ``Project/Error/workIsLocked(_:)`` if the work is locked; the project is
    ///             left unchanged.
    @discardableResult
    public mutating func removeWork(_ workID: WorkID) throws(Error) -> Work? {
        guard let work = workMap[workID]
        else { return nil }

        guard !work.isLocked
        else { throw Error.workIsLocked(workID) }

        return workMap.removeValue(forKey: workID)
    }

    /// Serializes this project to a file wrapper.
    ///
    /// - Returns:  A `FileWrapper` containing the serialized project data.
    ///
    /// - Throws:   ``Project/Error/saveFailure(_:)`` if this project cannot be saved.
    public func save() throws(Error) -> FileWrapper {
        do {
            return try _prepare().zip()
        } catch let error as any EnhancedError {
            throw Error.saveFailure(error)
        } catch {
            throw Error.saveFailure(nil)
        }
    }

    /// Inserts or replaces a template in this project.
    ///
    /// - Parameter template:   The ``Template`` to insert or replace.
    ///
    /// - Returns:  `true` if a template with the same ID already existed and was replaced;
    ///             otherwise, `false`.
    @discardableResult
    public mutating func updateTemplate(_ template: Template) -> Bool {
        templateMap.updateValue(template,
                                forKey: template.templateID) != nil
    }

    /// Inserts or replaces a work in this project.
    ///
    /// - Parameter work:   The ``Work`` to insert or replace.
    ///
    /// - Returns:  `true` if a work with the same ID already existed and was replaced;
    ///             otherwise, `false`.
    @discardableResult
    public mutating func updateWork(_ work: Work) -> Bool {
        workMap.updateValue(work,
                            forKey: work.workID) != nil
    }

    // MARK: Private Type Properties

    private static let manifestFileName       = manifestFileStem + "." + sexpFileExtension
    private static let manifestFileStem       = "manifest"
    private static let sexpFileExtension      = "sexp"
    private static let templatesDirectoryName = "templates"
    private static let worksDirectoryName     = "works"

    // MARK: Private Type Methods

    private static func _fetchManifest(from file: FileWrapper) throws -> Manifest {
        let data = try file.findFile(Self.manifestFileName).contentsOfRegularFile()

        return try SexpDecoder().decode(Manifest.self,
                                        from: data)
    }

    private static func _fetchContents(from file: FileWrapper,
                                       at path: [String]) -> Data? {
        try? file.findFile(path).contentsOfRegularFile()
    }

    //
    // A template that can't be read is left out, rather than failing the whole project: it can be
    // analyzed again from its work, and the format changes freely before 1.0.  It's dropped from the
    // project the next time the project is saved.
    //
    private static func _fetchTemplates(from file: FileWrapper,
                                        in manifest: Manifest) -> ([Template], [SkippedTemplate]) {
        var skippedTemplates: [SkippedTemplate] = []
        var templates: [Template] = []

        for templateID in manifest.templateIDs {
            let contents = _fetchContents(from: file,
                                          at: [templatesDirectoryName, _makeTemplateFileName(for: templateID)])

            do {
                try templates.append(SexpDecoder().decode(Template.self,
                                                          from: _require(contents)))
            } catch {
                skippedTemplates.append(SkippedTemplate(templateID: templateID,
                                                        name: _name(in: contents),
                                                        reason: _reason(for: error)))
            }
        }

        return (templates, skippedTemplates)
    }

    //
    // A work that can't be read is kept unread, with its file as it was, rather than failing the
    // whole project: unlike a template, it can't be made again.
    //
    private static func _fetchWorks(from file: FileWrapper,
                                    in manifest: Manifest) -> ([Work], [UnreadableWork]) {
        var unreadableWorks: [UnreadableWork] = []
        var works: [Work] = []

        for workID in manifest.workIDs {
            let contents = _fetchContents(from: file,
                                          at: [worksDirectoryName, _makeWorkFileName(for: workID)])

            do {
                try works.append(SexpDecoder().decode(Work.self,
                                                      from: _require(contents)))
            } catch {
                unreadableWorks.append(UnreadableWork(workID: workID,
                                                      name: _name(in: contents),
                                                      reason: _reason(for: error),
                                                      contents: contents))
            }
        }

        return (works, unreadableWorks)
    }

    private static func _makeTemplateFileName(for templateID: TemplateID) -> String {
        templateID.stringValue + "." + sexpFileExtension
    }

    private static func _makeWorkFileName(for workID: WorkID) -> String {
        workID.stringValue + "." + sexpFileExtension
    }

    //
    // The name in a work's or template's file, if that much of it can be read.
    //
    private static func _name(in contents: Data?) -> String? {
        guard let contents
        else { return nil }

        return try? SexpDecoder().decode(_NameOnly.self,
                                         from: contents).name.normalizingWhitespace()
    }

    //
    // The model's own errors — an unsupported version, say — explain themselves; anything else
    // (a decoding error, a missing file) is described by Foundation.
    //
    private static func _reason(for error: any Swift.Error) -> String {
        switch error {
        case let error as Template.Error:
            error.message

        case let error as Work.Error:
            error.message

        default:
            error.localizedDescription
        }
    }

    private static func _require(_ contents: Data?) throws -> Data {
        guard let contents
        else { throw CocoaError(.fileNoSuchFile) }

        return contents
    }

    // MARK: Private Instance Properties

    //
    // The unreadable works with a file to keep.
    //
    private var _keptUnreadableWorks: [UnreadableWork] {
        unreadableWorks.filter { $0.contents != nil }
    }

    // MARK: Private Instance Methods

    private func _prepare() throws -> FileWrapper {
        try FileWrapper(directoryWithFileWrappers: [Self.manifestFileName: _prepareManifest(),
                                                    Self.templatesDirectoryName: _prepareTemplates(),
                                                    Self.worksDirectoryName: _prepareWorks()])
    }

    //
    // Unreadable works are listed too, so that they're read again next time.
    //
    private func _prepareManifest() throws -> FileWrapper {
        let manifest = Manifest(name: name,
                                workIDs: Array(workMap.keys) + _keptUnreadableWorks.map(\.workID),
                                templateIDs: Array(templateMap.keys))
        let data = try SexpEncoder().encode(manifest)
        let file = FileWrapper(regularFileWithContents: data)

        file.preferredFilename = Self.manifestFileName

        return file
    }

    private func _prepareTemplates() throws -> FileWrapper {
        var children: [String: FileWrapper] = [:]

        for template in templateMap.values {
            let name = Self._makeTemplateFileName(for: template.templateID)
            let data = try SexpEncoder().encode(template)
            let file = FileWrapper(regularFileWithContents: data)

            file.preferredFilename = name

            children[name] = file
        }

        let file = FileWrapper(directoryWithFileWrappers: children)

        file.preferredFilename = Self.templatesDirectoryName

        return file
    }

    private func _prepareWorks() throws -> FileWrapper {
        var children: [String: FileWrapper] = [:]

        for work in workMap.values {
            let name = Self._makeWorkFileName(for: work.workID)
            let data = try SexpEncoder().encode(work)
            let file = FileWrapper(regularFileWithContents: data)

            file.preferredFilename = name

            children[name] = file
        }

        for unreadableWork in _keptUnreadableWorks {
            guard let contents = unreadableWork.contents
            else { continue }

            let name = Self._makeWorkFileName(for: unreadableWork.workID)
            let file = FileWrapper(regularFileWithContents: contents)

            file.preferredFilename = name

            children[name] = file
        }

        let file = FileWrapper(directoryWithFileWrappers: children)

        file.preferredFilename = Self.worksDirectoryName

        return file
    }
}

// MARK: - Sendable

extension Project: Sendable {
}

// MARK: - Private Types

//
// Just the name of a work or template, which may be all of it that can be read.
//
private struct _NameOnly: Decodable {
    let name: String
}
