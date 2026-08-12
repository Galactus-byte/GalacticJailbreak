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

        // Stage 1 — Prepare environment
        await stage(.preparing, target: 0.08, label: "Preparing environment") { [self] in
            let env = DOEnvironmentManager.shared()
            guard env?.prepare() == true else {
                throw JBError.stageFailed("Environment preparation failed")
            }
            self.emit("Environment prepared", .success)
        }

        // Stage 2 — Trigger kernel exploit
        await stage(.exploiting, target: 0.30, label: "Triggering \(method.exploitLabel)") { [self] in
            var error: NSError?
            let exploitManager = DOExploitManager.shared()
            let success = exploitManager?.runExploit(&error) ?? false
            if !success {
                throw error ?? JBError.stageFailed("Exploit failed — try again")
            }
            self.emit("Kernel read/write primitive established", .success)
        }

        // Stage 3 — Escalate privileges
        await stage(.exploiting, target: 0.48, label: "Escalating privileges") { [self] in
            var error: NSError?
            let jailbreaker = DOJailbreaker.shared()
            let success = jailbreaker?.escalatePrivileges(&error) ?? false
            if !success {
                throw error ?? JBError.stageFailed("Privilege escalation failed")
            }
            self.emit("Credential replacement complete", .success)
            self.emit("TrustCache bypass applied", .success)
            self.emit("Platform policy suspended", .success)
        }

        // Stage 4 — Bootstrap /var/jb
        await stage(.bootstrapping, target: 0.65, label: "Installing rootless bootstrap → /var/jb") { [self] in
            var error: NSError?
            let bootstrapper = DOBootstrapper.shared()
            let success = bootstrapper?.bootstrap(&error) ?? false
            if !success {
                throw error ?? JBError.stageFailed("Bootstrap installation failed")
            }
            self.emit("Bootstrap extracted to /var/jb", .success)
            self.emit("dyld injection layer configured", .success)
            self.emit("TweakLoader installed", .success)
        }

        // Stage 5 — Install package manager
        status = .installing(pm)
        await stage(.installing(pm), target: 0.83, label: "Installing \(pm.rawValue)") { [self] in
            var error: NSError?
            let jailbreaker = DOJailbreaker.shared()

            // Save preferred package manager via DOPreferenceManager
            DOPreferenceManager.shared()?.setPreferredPackageManager(pm.bundleID)

            let success = jailbreaker?.installPackageManager(pm.bundleID, error: &error) ?? false
            if !success {
                throw error ?? JBError.stageFailed("\(pm.rawValue) installation failed")
            }
            self.emit("\(pm.rawValue) installed → /var/jb/Applications/\(pm.rawValue).app", .success)
        }

        // Stage 6 — Activate jailbreak environment
        await stage(.finalizing, target: 0.97, label: "Activating jailbreak environment") { [self] in
            var error: NSError?
            let jailbreaker = DOJailbreaker.shared()
            let success = jailbreaker?.finalizeJailbreak(&error) ?? false
            if !success {
                throw error ?? JBError.stageFailed("Finalization failed")
            }
            self.emit("SpringBoard injection active", .success)
            self.emit("Jailbreak environment live", .success)
        }

        progress = 1.0
        status = .complete
        emit("Jailbreak complete. Open \(pm.rawValue) from your home screen.", .success)
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
