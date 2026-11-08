import CryptoKit
import Foundation
import Testing
@testable import TranslateCore

struct ModelDownloadTests {
    private let directory = URL.temporaryDirectory.appending(path: "ModelDownloadTests-\(UUID().uuidString)")
    private let content = Data(repeating: 0x42, count: 300_000)

    private func fixture() throws -> (source: URL, variant: ModelVariant) {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let source = directory.appending(path: "source.bin")
        try content.write(to: source)
        let variant = ModelVariant(
            displayName: "Test",
            fileName: "model.gguf",
            repository: "owner/repo",
            revision: "abc",
            byteCount: Int64(content.count),
            sha256: SHA256.hash(data: content).map { String(format: "%02x", $0) }.joined()
        )
        return (source, variant)
    }

    @Test func aVerifiedDownloadBecomesTheModelFileAndLeavesNoPartBehind() async throws {
        let (source, variant) = try fixture()
        let store = ModelStore(directory: directory.appending(path: "store"))
        var events: [ModelDownload.Event] = []
        for try await event in ModelDownload.start(variant, from: source, into: store).events { events.append(event) }

        #expect(events.last == .verifying)
        #expect(events.contains(.downloading(bytesWritten: Int64(content.count))))
        #expect(try Data(contentsOf: store.url(for: variant)) == content)
        #expect(try FileManager.default.contentsOfDirectory(atPath: store.directory.path) == ["model.gguf"])
    }

    @Test func aChecksumMismatchLeavesNoFileBehind() async throws {
        let (source, correct) = try fixture()
        var tampered = correct
        tampered.sha256 = String(repeating: "0", count: 64)
        let store = ModelStore(directory: directory.appending(path: "store"))

        await #expect(throws: ModelDownloadError.checksumMismatch) {
            for try await _ in ModelDownload.start(tampered, from: source, into: store).events {}
        }
        #expect(try FileManager.default.contentsOfDirectory(atPath: store.directory.path).isEmpty)
    }

    @Test(.timeLimit(.minutes(1)))
    func cancellingBeforeTheTransferStartsStillEndsTheStreamAndARetrySucceeds() async throws {
        let (source, variant) = try fixture()
        let store = ModelStore(directory: directory.appending(path: "store"))
        let cancelled = ModelDownload.start(variant, from: source, into: store)
        cancelled.cancel()

        await #expect(throws: CancellationError.self) {
            for try await _ in cancelled.events {}
        }
        #expect(!FileManager.default.fileExists(atPath: store.directory.appending(path: "model.gguf.part").path))

        for try await _ in ModelDownload.start(variant, from: source, into: store).events {}
        #expect(try Data(contentsOf: store.url(for: variant)) == content)
    }
}
