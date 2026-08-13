import Foundation
import SwiftUI

@MainActor
final class JailbreakEngine: ObservableObject {

    @Published var status: Status = .idle
    @Published var progress: Double = 0.0
    @Published var log: [LogEntry] = []

    private var activeTask: Task<Void, Never>?

    // MARK: - Public Interface

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

    // MARK: - Execution Router

    private func execute(pm: PackageManager) async {
        let method = DeviceInfo.jailbreakMethod
        guard method.isSupported else {
            status = .failed("Device or iOS version not supported.")
            emit("Unsupported: \(DeviceInfo.modelIdentifier) / iOS \(DeviceInfo.iOSVersion)", .error)
            emit("Dopamine supports A12–A15 on iOS 15.0–16.7.x", .warning)
            emit("Dopamine 2 supports A16 on iOS 16.0–16.7.x", .warning)
            return
        }
        await runDopamine(method: method, pm: pm)
    }

    // MARK: - Dopamine Path (A12–A16, fully on-device)

    private func runDopamine(method: DeviceInfo.JBMethod, pm: PackageManager) async {
        emit("[\(method.rawValue)] starting — \(method.exploitLabel)", .info)
        emit("Target: \(DeviceInfo.modelIdentifier) · iOS \(DeviceInfo.iOSVersion) · \(DeviceInfo.chip.display)", .info)

        // Stage 1 — Environment check
        await stage(.preparing, target: 0.08, label: "Checking environment") { [self] in
            guard DOHelper.isEnvironmentSupported() else {
                throw JBError.stageFailed("Device not supported by Dopamine")
            }
            if DOHelper.isDeviceJailbroken() {
                self.emit("Previously jailbroken — re-jailbreaking", .warning)
            }
            self.emit("Environment check passed", .success)
        }

        // Stage 2 — Run exploit + escalate via DOJailbreaker
        await stage(.exploiting, target: 0.40, label: "Running \(method.exploitLabel) exploit") { [self] in
            if let error = DOHelper.runJailbreak() {
                throw error
            }
            self.emit("Kernel read/write primitive established", .success)
            self.emit("Credential replacement complete", .success)
            self.emit("TrustCache bypass applied", .success)
        }

        // Stage 3 — Download and prepare bootstrap via DOBootstrapper
        await stage(.bootstrapping, target: 0.65, label: "Preparing bootstrap → /var/jb") { [self] in
            try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
                DOHelper.prepareBootstrap { error in
                    if let error = error {
                        cont.resume(throwing: error)
                    } else {
                        cont.resume()
                    }
                }
            }
            self.emit("Bootstrap extracted to /var/jb", .success)

            if let symlinkError = DOHelper.updateVarJbSymlink() {
                throw symlinkError
            }
            self.emit("Symlink /var/jb configured", .success)
        }

        // Stage 4 — Install selected package manager
        status = .installing(pm)
        await stage(.installing(pm), target: 0.83, label: "Installing \(pm.rawValue)") { [self] in
            DOHelper.setPreferredPackageManager(pm.bundleID)

            if let pmError = DOHelper.installPackageManagers() {
                throw pmError
            }
            self.emit("\(pm.rawValue) installed → /var/jb/Applications/", .success)
        }

        // Stage 5 — Finalize environment
        await stage(.finalizing, target: 0.97, label: "Finalizing jailbreak environment") { [self] in
            if let finalizeError = DOHelper.finalizeBootstrap() {
                throw finalizeError
            }
            self.emit("Bootstrap finalized", .success)

            DOHelper.markDeviceJailbroken(true)
            self.emit("Environment marked as jailbroken", .success)

            DOHelper.finalizeJailbreaker()
            self.emit("SpringBoard injection active", .success)
        }

        progress = 1.0
        status = .complete
        emit("Jailbreak complete. Open \(pm.rawValue) from your home screen.", .success)
    }

    // MARK: - Respring (called from JailbreakView after complete)

    func respring() {
        DOHelper.respring()
    }

    // MARK: - Stage Runner

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

    func emit(_ message: String, _ level: LogEntry.Level = .info) {
        log.append(LogEntry(timestamp: Date(), message: message, level: level))
    }

    // MARK: - Error Type

    enum JBError: LocalizedError {
        case stageFailed(String)
        var errorDescription: String? {
            switch self { case .stageFailed(let r): return r }
        }
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
            case .preparing:         return "Checking environment..."
            case .exploiting:        return "Exploiting kernel..."
            case .bootstrapping:     return "Bootstrapping /var/jb..."
            case .installing(let p): return "Installing \(p.rawValue)..."
            case .finalizing:        return "Finalizing environment..."
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
