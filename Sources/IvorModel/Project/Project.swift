// © 2025–2026 John Gary Pusey (see LICENSE.md)

public import Foundation

private import XestiSexp
private import XestiTools

/// An Ivor project containing a collection of works and templates.
public struct Project {

    // MARK: Public Initializers

    /// Creates a new, empty project.
    public init() {
        self.name = ""
        self.templateMap = [:]
        self.workMap = [:]
    }

    // MARK: Public Instance Properties

    /// The display name of this project.
    public private(set) var name: String

    // MARK: Private Instance Properties

    private var templateMap: [TemplateID: Template]
    private var workMap: [WorkID: Work]
}

// MARK: -

extension Project {

    // MARK: Public Type Methods

    /// Creates a project by loading from a file wrapper.
    ///
    /// - Parameter file:   The `FileWrapper` containing the serialized project data.
    ///
    /// - Returns:  A ``Project`` loaded from the file.
    ///
    /// - Throws:   ``Project/Error/loadFailure(_:)`` if the project cannot be loaded.
    public static func load(from file: FileWrapper) throws -> Project {
        do {
            return try Project(from: file.unzip())
        } catch let error as any EnhancedError {
            throw Error.loadFailure(error)
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
    @discardableResult
    public mutating func removeTemplate(_ templateID: TemplateID) -> Template? {
        guard let template = templateMap.removeValue(forKey: templateID)
        else { return nil }

        return template
    }

    /// Removes the work with the given ID from this project.
    ///
    /// - Parameter workID:     The ID of the work to remove.
    ///
    /// - Returns:  The removed ``Work``, or `nil` if no work with that ID exists.
    @discardableResult
    public mutating func removeWork(_ workID: WorkID) -> Work? {
        guard let work = workMap.removeValue(forKey: workID)
        else { return nil }

        return work
    }

    /// Serializes this project to a file wrapper.
    ///
    /// - Returns:  A `FileWrapper` containing the serialized project data.
    ///
    /// - Throws:   ``Project/Error/saveFailure(_:)`` if this project cannot be saved.
    public func save() throws -> FileWrapper {
        do {
            return try _prepare().zip()
        } catch let error as any EnhancedError {
            throw Error.saveFailure(error)
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

    private static func _fetchTemplate(from file: FileWrapper,
                                       for templateID: TemplateID) throws -> Template {
        let data = try file.findFile([templatesDirectoryName,
                                      _makeTemplateFileName(for: templateID)]).contentsOfRegularFile()

        return try SexpDecoder().decode(Template.self,
                                        from: data)
    }

    private static func _fetchTemplates(from file: FileWrapper,
                                        in manifest: Manifest) throws -> [Template] {
        try manifest.templateIDs.map {
            try _fetchTemplate(from: file,
                               for: $0)
        }
    }

    private static func _fetchWork(from file: FileWrapper,
                                   for workID: WorkID) throws -> Work {
        let data = try file.findFile([worksDirectoryName,
                                      _makeWorkFileName(for: workID)]).contentsOfRegularFile()

        return try SexpDecoder().decode(Work.self,
                                        from: data)
    }

    private static func _fetchWorks(from file: FileWrapper,
                                    in manifest: Manifest) throws -> [Work] {
        try manifest.workIDs.map {
            try _fetchWork(from: file,
                           for: $0)
        }
    }

    private static func _makeTemplateFileName(for templateID: TemplateID) -> String {
        templateID.stringValue + "." + sexpFileExtension
    }

    private static func _makeWorkFileName(for workID: WorkID) -> String {
        workID.stringValue + "." + sexpFileExtension
    }

    // MARK: Private Initializers

    private init(from file: FileWrapper) throws {
        let manifest = try Self._fetchManifest(from: file)
        let templates = try Self._fetchTemplates(from: file,
                                                 in: manifest)
        let works = try Self._fetchWorks(from: file,
                                         in: manifest)

        self.name = manifest.name
        self.templateMap = Dictionary(uniqueKeysWithValues: templates.map { ($0.templateID, $0) })
        self.workMap = Dictionary(uniqueKeysWithValues: works.map { ($0.workID, $0) })
    }

    // MARK: Private Instance Methods

    private func _prepare() throws -> FileWrapper {
        try FileWrapper(directoryWithFileWrappers: [Self.manifestFileName: _prepareManifest(),
                                                    Self.templatesDirectoryName: _prepareTemplates(),
                                                    Self.worksDirectoryName: _prepareWorks()])
    }

    private func _prepareManifest() throws -> FileWrapper {
        let manifest = Manifest(name: name,
                                workIDs: Array(workMap.keys),
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

        let file = FileWrapper(directoryWithFileWrappers: children)

        file.preferredFilename = Self.worksDirectoryName

        return file
    }
}

// MARK: - Sendable

extension Project: Sendable {
}
