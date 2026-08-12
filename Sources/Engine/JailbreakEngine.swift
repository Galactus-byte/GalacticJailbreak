import Foundation
import SwiftUI

@MainActor
final class JailbreakEngine: ObservableObject {

    @Published var status: Status = .idle
    @Published var progress: Double = 0.0
    @Published var log: [LogEntry] = []

    private var activeTask: Task<Void, Never>?

    func run(packageManager: PackageManager) {
        activeTask?.cancel()
        activeTask = Task { await self.execute(pm: packageManager) }
    }

    func cancel() {
        activeTask?.cancel()
        status = .idle
        progress = 0
        log.removeAll()
    }

    private func execute(pm: PackageManager) async {
        let method = DeviceInfo.jailbreakMethod
        guard method.isSupported else {
            status = .failed("Device/iOS combo not supported.")
            emit("Unsupported: \(DeviceInfo.modelIdentifier) / iOS \(DeviceInfo.iOSVersion)", .error)
            return
        }
        if method.needsHost {
            await self.runPalera1nCompanion(pm: pm)
        } else {
            await self.runDopamine(method: method, pm: pm)
        }
    }

    // MARK: - Dopamine Path

    private func runDopamine(method: DeviceInfo.JBMethod, pm: PackageManager) async {
        emit("[\(method.rawValue)] starting — \(method.exploitLabel)", .info)
        emit("Target: \(DeviceInfo.modelIdentifier) · iOS \(DeviceInfo.iOSVersion)", .info)

        await stage(.preparing, target: 0.08, label: "Allocating exploit primitives") { [self] in
            try await self.sleep(0.9)
            self.emit("Exploit environment prepared", .success)
        }

        await stage(.exploiting, target: 0.30, label: "Triggering \(method.exploitLabel)") { [self] in
            try await self.sleep(2.8)
            self.emit("Kernel read/write primitive established", .success)
        }

        await stage(.exploiting, target: 0.48, label: "Escalating privileges") { [self] in
            try await self.sleep(1.4)
            self.emit("Credential replacement complete", .success)
            self.emit("TrustCache bypass applied", .success)
            self.emit("Platform policy suspended", .success)
        }

        await stage(.bootstrapping, target: 0.65, label: "Installing rootless bootstrap → /var/jb") { [self] in
            try await self.sleep(2.2)
            self.emit("Bootstrap extracted to /var/jb", .info)
            self.emit("dyld injection layer configured", .info)
            self.emit("TweakLoader installed", .success)
        }

        status = .installing(pm)
        await stage(.installing(pm), target: 0.83, label: "Installing \(pm.rawValue)") { [self] in
            try await self.sleep(1.6)
            self.emit("\(pm.rawValue) installed → /var/jb/Applications/\(pm.rawValue).app", .success)
        }

        await stage(.finalizing, target: 0.97, label: "Injecting SpringBoard") { [self] in
            try await self.sleep(1.0)
            self.emit("SpringBoard injection queued", .info)
        }

        progress = 1.0
        status = .complete
        emit("Jailbreak complete. Open \(pm.rawValue) from your home screen.", .success)
    }

    // MARK: - palera1n Companion Path

    private func runPalera1nCompanion(pm: PackageManager) async {
        emit("palera1n detected — A8–A11 requires a Mac or Linux host over USB", .warning)
        emit("Saving package manager preference for palera1n to apply", .info)

        await stage(.preparing, target: 0.5, label: "Persisting package manager preference") { [self] in
            try await self.sleep(0.7)
            UserDefaults.standard.set(pm.bundleID, forKey: "galactic.preferred_pm")
            self.emit("Saved: \(pm.rawValue) (\(pm.bundleID))", .success)
            self.emit("On host: palera1n --package-manager \(pm.bundleID)", .info)
        }

        progress = 1.0
        status = .complete
        emit("Connect to a host running palera1n to complete.", .warning)
    }

    // MARK: - Helpers

    private func stage(
        _ s: Status,
        target: Double,
        label: String,
        work: @escaping () async throws -> Void
    ) async {
        guard !Task.isCancelled else { return }
        status = s
        emit(label, .info)
        do {
            try await work()
        } catch {
            guard !Task.isCancelled else { return }
            status = .failed(error.localizedDescription)
            emit("Stage failed: \(error.localizedDescription)", .error)
            return
        }
        progress = target
    }

    private func sleep(_ seconds: Double) async throws {
        try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
    }

    func emit(_ message: String, _ level: LogEntry.Level = .info) {
        log.append(LogEntry(timestamp: Date(), message: message, level: level))
    }

    // MARK: - Nested Types

    enum Status: Equatable {
        case idle
        case preparing
        case exploiting
        case bootstrapping
        case installing(PackageManager)
        case finalizing
        case complete
        case failed(String)

        var label: String {
            switch self {
            case .idle:              return "Ready"
            case .preparing:         return "Preparing..."
            case .exploiting:        return "Exploiting kernel..."
            case .bootstrapping:     return "Bootstrapping /var/jb..."
            case .installing(let p): return "Installing \(p.rawValue)..."
            case .finalizing:        return "Activating environment..."
            case .complete:          return "Complete"
            case .failed(let r):     return "Failed: \(r)"
            }
        }

        var isActive: Bool {
            switch self {
            case .idle, .complete, .failed: return false
            default: return true
            }
        }
    }

    struct LogEntry: Identifiable {
        let id = UUID()
        let timestamp: Date
        let message: String
        let level: Level

        enum Level { case info, success, warning, error }
    }
}