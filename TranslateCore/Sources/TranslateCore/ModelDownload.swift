import CryptoKit
import Foundation
import Synchronization

public enum ModelDownloadError: Error, Equatable {
    case unexpectedResponse(statusCode: Int)
    case checksumMismatch
}

/// A download of a model into a store. The file is verified against the catalog's SHA-256
/// before it takes the model's name, so nothing half-done ever looks like a model.
public struct ModelDownload: Sendable {
    public enum Event: Sendable, Equatable {
        case downloading(bytesWritten: Int64)
        case verifying
    }

    /// Ends when the model file is in place, or throws. After `cancel()` it throws
    /// `CancellationError`, and only once the transfer has stopped and the `.part` is gone.
    public let events: AsyncThrowingStream<Event, any Error>
    private let task: Task<Void, Never>

    /// There is no resumption: the file is small enough to start over.
    public static func start(_ variant: ModelVariant, from source: URL? = nil, into store: ModelStore) -> ModelDownload {
        let (events, continuation) = AsyncThrowingStream<Event, any Error>.makeStream()
        let task = Task {
            do {
                try await download(variant, from: source ?? variant.downloadURL, into: store, reporting: continuation)
                continuation.finish()
            } catch {
                continuation.finish(throwing: Task.isCancelled ? CancellationError() : error)
            }
        }
        continuation.onTermination = { _ in task.cancel() }
        return ModelDownload(events: events, task: task)
    }

    public func cancel() {
        task.cancel()
    }

    private static func download(
        _ variant: ModelVariant,
        from source: URL,
        into store: ModelStore,
        reporting continuation: AsyncThrowingStream<Event, any Error>.Continuation
    ) async throws {
        let part = store.partURL(for: variant)
        try FileManager.default.createDirectory(at: store.directory, withIntermediateDirectories: true)
        try? FileManager.default.removeItem(at: part)
        do {
            let response = try await Transfer(to: part, reporting: continuation).run(URLRequest(url: source))
            try Task.checkCancellation()
            if let http = response as? HTTPURLResponse, http.statusCode != 200 {
                throw ModelDownloadError.unexpectedResponse(statusCode: http.statusCode)
            }
            continuation.yield(.verifying)
            guard try sha256(of: part) == variant.sha256 else { throw ModelDownloadError.checksumMismatch }
            _ = try FileManager.default.replaceItemAt(store.url(for: variant), withItemAt: part)
        } catch {
            try? FileManager.default.removeItem(at: part)
            throw error
        }
    }

    private static func sha256(of file: URL) throws -> String {
        let handle = try FileHandle(forReadingFrom: file)
        defer { try? handle.close() }
        var hasher = SHA256()
        while let chunk = try handle.read(upToCount: 1 << 20), !chunk.isEmpty {
            try Task.checkCancellation()
            hasher.update(data: chunk)
        }
        return hasher.finalize().map { String(format: "%02x", $0) }.joined()
    }
}

/// One download task driven through a session delegate: the async `download(for:delegate:)`
/// never calls the task delegate's progress or completion methods (checked on macOS 26).
private final class Transfer: NSObject, URLSessionDownloadDelegate, Sendable {
    private struct State {
        var completion: CheckedContinuation<URLResponse, any Error>?
        var result: Result<URLResponse, any Error>?
        var moveError: (any Error)?
    }

    private let destination: URL
    private let events: AsyncThrowingStream<ModelDownload.Event, any Error>.Continuation
    private let state = Mutex(State())

    init(to destination: URL, reporting events: AsyncThrowingStream<ModelDownload.Event, any Error>.Continuation) {
        self.destination = destination
        self.events = events
    }

    /// Returns once the file is at `destination`, or throws. Cancellation may land before the
    /// task is resumed or after it has completed; either way the result is delivered once.
    func run(_ request: URLRequest) async throws -> URLResponse {
        let session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
        defer { session.finishTasksAndInvalidate() }
        let task = session.downloadTask(with: request)
        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                let finished = state.withLock { state -> Result<URLResponse, any Error>? in
                    if let result = state.result { return result }
                    state.completion = continuation
                    return nil
                }
                if let finished {
                    continuation.resume(with: finished)
                } else {
                    task.resume()
                }
            }
        } onCancel: {
            task.cancel()
        }
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        events.yield(.downloading(bytesWritten: totalBytesWritten))
    }

    // The temporary file lives only until this method returns.
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        do {
            try FileManager.default.moveItem(at: location, to: destination)
        } catch {
            state.withLock { $0.moveError = error }
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: (any Error)?) {
        let completion = state.withLock { state in
            if let error = error ?? state.moveError {
                state.result = .failure(error)
            } else {
                state.result = .success(task.response ?? URLResponse())
            }
            defer { state.completion = nil }
            return state.completion.map { ($0, state.result!) }
        }
        if let (continuation, result) = completion { continuation.resume(with: result) }
    }
}
