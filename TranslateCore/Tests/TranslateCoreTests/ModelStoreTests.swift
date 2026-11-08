import Foundation
import Testing
@testable import TranslateCore

struct ModelStoreTests {
    private let directory = URL.temporaryDirectory.appending(path: "ModelStoreTests-\(UUID().uuidString)")
    private let variant = ModelVariant(
        displayName: "Test", fileName: "model.gguf", repository: "owner/repo", revision: "abc", byteCount: 1, sha256: "00"
    )

    @Test func placesTheModelFileUnderTheDirectory() {
        let store = ModelStore(directory: directory)
        #expect(store.url(for: variant) == directory.appending(path: "model.gguf"))
    }

    @Test func aModelIsAvailableOnlyWhenItsFileExists() throws {
        let store = ModelStore(directory: directory)
        #expect(!store.isAvailable(variant))
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try Data().write(to: store.url(for: variant))
        #expect(store.isAvailable(variant))
    }

    @Test func removingIncompleteDownloadsKeepsFinishedModels() throws {
        let store = ModelStore(directory: directory)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try Data().write(to: store.url(for: variant))
        try Data().write(to: directory.appending(path: "other.gguf.part"))
        try store.removeIncompleteDownloads()
        let remaining = try FileManager.default.contentsOfDirectory(atPath: directory.path)
        #expect(remaining == ["model.gguf"])
    }

    @Test func removingIncompleteDownloadsToleratesAMissingDirectory() throws {
        try ModelStore(directory: directory).removeIncompleteDownloads()
    }
}
