import Foundation

/// One downloadable model file, pinned to a Hugging Face commit so the URL always serves
/// the bytes that `sha256` describes.
public struct ModelVariant: Sendable, Hashable {
    public var displayName: String
    public var fileName: String
    public var repository: String
    public var revision: String
    public var byteCount: Int64
    public var sha256: String

    public init(displayName: String, fileName: String, repository: String, revision: String, byteCount: Int64, sha256: String) {
        self.displayName = displayName
        self.fileName = fileName
        self.repository = repository
        self.revision = revision
        self.byteCount = byteCount
        self.sha256 = sha256
    }

    public var downloadURL: URL {
        URL(string: "https://huggingface.co/\(repository)/resolve/\(revision)/\(fileName)")!
    }
}

extension ModelVariant {
    /// The one model v1 ships with: fast enough on Apple Silicon, and within 0.02 PFTB of
    /// the 2B variant on PFN's own table.
    public static let plamo3Translate0_8b = ModelVariant(
        displayName: "PLaMo 3 Translate 0.8B",
        fileName: "plamo-3-translate-0.8b-Q4_K_M.gguf",
        repository: "pfnet/plamo-3-translate-0.8b-gguf",
        revision: "0c4af2b003fdd94b6868aa955414c1c86ee96997",
        byteCount: 573_125_952,
        sha256: "73a1d942d8ab1e654d83898d997b8b4808c32ba669b378df612230989d18f079"
    )
}
