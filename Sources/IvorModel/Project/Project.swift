public import Foundation

private import XestiSexp
private import XestiTools

public struct Project {

    // MARK: Public Initializers

    public init() {
        self.name = ""
        self.templateMap = [:]
        self.workMap = [:]
    }

    // MARK: Public Instance Properties

    public private(set) var name: String

    // MARK: Internal Instance Properties

    internal var templateMap: [TemplateID: Template]
    internal var workMap: [WorkID: Work]
}

// MARK: -

extension Project {

    // MARK: Public Type Methods

    public static func load(from file: FileWrapper) throws -> Project {
        do {
            return try Project(from: file.unzip())
        } catch let error as any EnhancedError {
            throw Error.loadFailure(error)
        }
    }

    // MARK: Public Instance Properties

    public var templates: [Template] {
        Array(templateMap.values)
    }

    public var works: [Work] {
        Array(workMap.values)
    }

    // MARK: Public Instance Methods

    public func fetchTemplate(_ templateID: TemplateID) -> Template? {
        templateMap[templateID]
    }

    public func fetchWork(_ workID: WorkID) -> Work? {
        workMap[workID]
    }

    @discardableResult
    public mutating func removeTemplate(_ templateID: TemplateID) -> Template? {
        guard let template = templateMap.removeValue(forKey: templateID)
        else { return nil }

        return template
    }

    @discardableResult
    public mutating func removeWork(_ workID: WorkID) -> Work? {
        guard let work = workMap.removeValue(forKey: workID)
        else { return nil }

        return work
    }

    public func save() throws -> FileWrapper {
        do {
            return try _prepare().zip()
        } catch let error as any EnhancedError {
            throw Error.saveFailure(error)
        }
    }

    @discardableResult
    public mutating func updateTemplate(_ template: Template) -> Bool {
        templateMap.updateValue(template,
                                forKey: template.templateID) != nil
    }

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
