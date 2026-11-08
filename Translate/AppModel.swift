import Foundation
import Observation
import TranslateCore

/// What the whole app shares: whether the model is on disk, a download in flight, and the
/// translator, loaded once off the main actor on the first request that needs it.
@Observable
final class AppModel {
    enum Download {
        case downloading(bytesWritten: Int64)
        case verifying
        case failed(any Error)
    }

    let store = ModelStore()
    let variant = ModelVariant.plamo3Translate0_8b
    /// Held here rather than only in defaults because the registration must follow changes.
    var hotKey = UserDefaults.standard.hotKey {
        didSet { UserDefaults.standard.hotKey = hotKey }
    }
    /// While a new shortcut is being recorded, the current one must not fire.
    var isRecordingShortcut = false
    private(set) var isModelAvailable: Bool
    private(set) var download: Download?
    private var current: ModelDownload?
    private var loading: Task<Translator, any Error>?

    init() {
        isModelAvailable = store.isAvailable(variant)
    }

    /// A retry is allowed only after the previous download has ended, cancelled or not,
    /// because both would use the same `.part` file.
    func downloadModel() {
        guard current == nil else { return }
        let current = ModelDownload.start(variant, into: store)
        self.current = current
        download = .downloading(bytesWritten: 0)
        Task {
            do {
                for try await event in current.events {
                    switch event {
                    case .downloading(let bytesWritten): download = .downloading(bytesWritten: bytesWritten)
                    case .verifying: download = .verifying
                    }
                }
                download = nil
                isModelAvailable = true
            } catch is CancellationError {
                download = nil
            } catch {
                download = .failed(error)
            }
            self.current = nil
        }
    }

    func cancelDownload() {
        current?.cancel()
    }

    func translator() async throws -> Translator {
        if let loading { return try await loading.value }
        guard isModelAvailable else { throw TranslationError.modelUnavailable }
        let url = store.url(for: variant)
        let loading = Task.detached(priority: .userInitiated) { try Translator(modelURL: url) }
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
