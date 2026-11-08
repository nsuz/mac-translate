import Foundation
import TranslateCore

/// Owns the translator. Loading takes about a second and happens off the main actor, once,
/// on the first request that needs it.
final class AppModel {
    nonisolated static let modelURL = URL.applicationSupportDirectory
        .appending(path: "Translate/Models/plamo-3-translate-0.8b-Q4_K_M.gguf")

    private var loading: Task<Translator, any Error>?

    func translator() async throws -> Translator {
        if let loading { return try await loading.value }
        let loading = Task.detached(priority: .userInitiated) { try Translator(modelURL: Self.modelURL) }
        self.loading = loading
        do {
            return try await loading.value
        } catch {
            self.loading = nil
            throw error
        }
    }

    func shutdown() async {
        guard let translator = try? await loading?.value else { return }
        await translator.shutdown()
        loading = nil
    }
}
