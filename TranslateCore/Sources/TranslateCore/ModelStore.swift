import Foundation

/// Where model files live. Only finished, verified files carry the model's own name;
/// a download in flight is a `.part` file next to it.
public struct ModelStore: Sendable {
    public let directory: URL

    public init(directory: URL = URL.applicationSupportDirectory.appending(path: "Translate/Models")) {
        self.directory = directory
    }

    public func url(for variant: ModelVariant) -> URL {
        directory.appending(path: variant.fileName)
    }

    public func isAvailable(_ variant: ModelVariant) -> Bool {
        FileManager.default.fileExists(atPath: url(for: variant).path)
    }

    /// Deletes downloads that never finished verifying, such as after a crash or a quit.
    public func removeIncompleteDownloads() throws {
        guard FileManager.default.fileExists(atPath: directory.path) else { return }
        for name in try FileManager.default.contentsOfDirectory(atPath: directory.path) where name.hasSuffix(Self.partSuffix) {
            try FileManager.default.removeItem(at: directory.appending(path: name))
        }
    }

    func partURL(for variant: ModelVariant) -> URL {
        directory.appending(path: variant.fileName + Self.partSuffix)
    }

    private static let partSuffix = ".part"
}
