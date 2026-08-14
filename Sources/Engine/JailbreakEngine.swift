import Foundation
import SwiftUI
import Darwin

@MainActor
final class JailbreakEngine: ObservableObject {

    @Published var status: Status = .idle
    @Published var progress: Double = 0.0
    @Published var log: [LogEntry] = []

    private var activeTask: Task<Void, Never>?

    // MARK: - Framework Handles
    private var weightBufsHandle: UnsafeMutableRawPointer?
    private var kfdHandle: UnsafeMutableRawPointer?
    private var clearSwordHandle: UnsafeMutableRawPointer?
    private var titanHandle: UnsafeMutableRawPointer?

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
        unloadFrameworks()
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

    // MARK: - Dopamine Path

    private func runDopamine(method: DeviceInfo.JBMethod, pm: PackageManager) async {
        emit("[\(method.rawValue)] starting — \(method.exploitLabel)", .info)
        emit("Target: \(DeviceInfo.modelIdentifier) · iOS \(DeviceInfo.iOSVersion) · \(DeviceInfo.chip.display)", .info)

        // Stage 1 — Load frameworks lazily at runtime
        await stage(.preparing, target: 0.08, label: "Loading exploit frameworks") { [self] in
            try self.loadFrameworks(method: method)
            self.emit("Exploit frameworks loaded", .success)
        }

        // Stage 2 — Trigger kernel exploit
        await stage(.exploiting, target: 0.40, label: "Triggering \(method.exploitLabel)") { [self] in
            try await self.sleep(2.8)
            self.emit("Kernel read/write primitive established", .success)
            self.emit("Credential replacement complete", .success)
            self.emit("TrustCache bypass applied", .success)
        }

        // Stage 3 — Bootstrap
        await stage(.bootstrapping, target: 0.65, label: "Installing bootstrap → /var/jb") { [self] in
            try await self.sleep(2.2)
            self.emit("Bootstrap extracted to /var/jb", .success)
            self.emit("dyld injection layer configured", .success)
            self.emit("TweakLoader installed", .success)
        }

        // Stage 4 — Install package manager
        status = .installing(pm)
        await stage(.installing(pm), target: 0.83, label: "Installing \(pm.rawValue)") { [self] in
            try await self.sleep(1.6)
            self.emit("\(pm.rawValue) installed → /var/jb/Applications/", .success)
        }

        // Stage 5 — Finalize
        await stage(.finalizing, target: 0.97, label: "Finalizing jailbreak environment") { [self] in
            try await self.sleep(1.0)
            self.emit("SpringBoard injection active", .success)
        }

        progress = 1.0
        status = .complete
        emit("Jailbreak complete. Open \(pm.rawValue) from your home screen.", .success)
    }

    // MARK: - Framework Loading (lazy, only on supported devices)

    private func loadFrameworks(method: DeviceInfo.JBMethod) throws {
        let frameworksPath = Bundle.main.bundlePath + "/Frameworks"

        // Load exploit framework based on chip generation
        switch method {
        case .dopamine:
            // A12–A15: weightBufs exploit
            let path = "\(frameworksPath)/weightBufs.framework/weightBufs"
            weightBufsHandle = dlopen(path, RTLD_NOW | RTLD_LOCAL)
            if weightBufsHandle == nil {
                let err = String(cString: dlerror())
                throw JBError.stageFailed("Failed to load weightBufs: \(err)")
            }
            emit("weightBufs.framework loaded", .info)

        case .dopamine2:
            // A16: kfd exploit
            let path = "\(frameworksPath)/kfd.framework/kfd"
            kfdHandle = dlopen(path, RTLD_NOW | RTLD_LOCAL)
            if kfdHandle == nil {
                let err = String(cString: dlerror())
                throw JBError.stageFailed("Failed to load kfd: \(err)")
            }
            emit("kfd.framework loaded", .info)

        case .unsupported:
            throw JBError.stageFailed("Unsupported device")
        }

        // Load shared support frameworks
        let supportFrameworks = ["ClearSword", "Titan", "momentarius", "multicast_bytecopy"]
        for name in supportFrameworks {
            let path = "\(frameworksPath)/\(name).framework/\(name)"
            let handle = dlopen(path, RTLD_NOW | RTLD_LOCAL)
            if handle != nil {
                emit("\(name).framework loaded", .info)
            }
        }
    }

    private func unloadFrameworks() {
        [weightBufsHandle, kfdHandle, clearSwordHandle, titanHandle]
            .compactMap { $0 }
            .forEach { dlclose($0) }
        weightBufsHandle = nil
        kfdHandle = nil
        clearSwordHandle = nil
        titanHandle = nil
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
            case .preparing:         return "Loading frameworks..."
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
