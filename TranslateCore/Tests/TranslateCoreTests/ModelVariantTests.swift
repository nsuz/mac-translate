import Foundation
import Testing
@testable import TranslateCore

struct ModelVariantTests {
    @Test func downloadURLResolvesTheFileAtThePinnedRevision() {
        let variant = ModelVariant(
            displayName: "Test",
            fileName: "model.gguf",
            repository: "owner/repo",
            revision: "abc123",
            byteCount: 1,
            sha256: "00"
        )
        #expect(variant.downloadURL == URL(string: "https://huggingface.co/owner/repo/resolve/abc123/model.gguf"))
    }

    @Test func theCatalogedModelIsPinnedToACommitNotABranch() {
        let variant = ModelVariant.plamo3Translate0_8b
        #expect(variant.revision.count == 40)
        #expect(variant.sha256.count == 64)
        #expect(variant.byteCount > 500_000_000)
    }
}
