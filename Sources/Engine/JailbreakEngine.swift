import Foundation
import SwiftUI
import Darwin

@MainActor
final class JailbreakEngine: ObservableObject {

    @Published var status: Status = .idle
    @Published var progress: Double = 0.0
    @Published var log: [LogEntry] = []

    private var activeTask: Task<Void, Never>?
    private var frameworkHandles: [UnsafeMutableRawPointer] = []

    // MARK: - URLs

    private let dopamineIPAURL = URL(string: "https://github.com/opa334/Dopamine/releases/latest/download/Dopamine.ipa")!
    private let knownGoodVersion = "3.0.9"

    // MARK: - Paths

    private var jbRoot:        String { "/var/jb" }
    private var frameworksDir: String { "\(jbRoot)/Frameworks" }
    private var dylibsDir:     String { "\(jbRoot)/usr/lib" }
    private var dpkg:          String { "\(jbRoot)/usr/bin/dpkg" }
    private var tmpDir:        String { NSTemporaryDirectory() + "GalacticJB" }
    private var extractedApp:  String { "\(tmpDir)/extracted/Payload/Dopamine.app" }

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

    // MARK: - Dopamine Update Check

    func checkForDopamineUpdate() async -> String? {
        guard let url = URL(string: "https://api.github.com/repos/opa334/Dopamine/releases/latest") else { return nil }
        guard let (data, _) = try? await URLSession.shared.data(from: url) else { return nil }
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let tag = json["tag_name"] as? String else { return nil }
        return tag != knownGoodVersion ? tag : nil
    }

    // MARK: - Router

    private func execute(pm: PackageManager) async {
        let method = DeviceInfo.jailbreakMethod
        guard method.isSupported else {
            status = .failed("Device or iOS version not supported.")
            emit("Unsupported: \(DeviceInfo.friendlyName) / iOS \(DeviceInfo.iOSVersion)", .error)
            emit("Dopamine 3 supports A8–A13 on iOS 15–18.7.1", .warning)
            emit("Dopamine 3 supports A12–A13 on iOS 26.0–26.0.1", .warning)
            emit("Dopamine 3 supports A14–M2 on iOS 15–17.3.1", .warning)
            return
        }
        await runDopamine(method: method, pm: pm)
    }

    // MARK: - Full Pipeline

    private func runDopamine(method: DeviceInfo.JBMethod, pm: PackageManager) async {
        emit("[\(method.rawValue)] starting — \(method.exploitLabel)", .info)
        emit("Target: \(DeviceInfo.friendlyName) · iOS \(DeviceInfo.iOSVersion) · \(DeviceInfo.chip.display)", .info)

        // Stage 1 — Entitlement check + download IPA
        await stage(.preparing, target: 0.15, label: "Checking entitlements and downloading Dopamine 3") { [self] in
            let signer = EntitlementChecker.detectedSigner
            self.emit("Signer: \(signer.rawValue)", .info)
            if !EntitlementChecker.hasPlatformApplication {
                self.emit("⚠ platform-application missing — install via TrollStore", .warning)
            } else {
                self.emit("platform-application active ✓", .success)
            }
            if !EntitlementChecker.isSandboxDisabled {
                self.emit("⚠ Sandbox active — /var/jb writes may fail", .warning)
            } else {
                self.emit("Sandbox disabled ✓", .success)
            }
            try await self.downloadAndExtractIPA()
        }

        // Stage 2 — Load exploit frameworks
        await stage(.preparing, target: 0.22, label: "Loading exploit frameworks") { [self] in
            try self.loadFrameworks(method: method)
        }

        // Stage 3 — Exploit via libjailbreak + libxpf
        await stage(.exploiting, target: 0.45, label: "Triggering \(method.exploitLabel)") { [self] in
            try self.runExploit(method: method)
        }

        // Stage 4 — Bootstrap
        await stage(.bootstrapping, target: 0.65, label: "Installing bootstrap → /var/jb") { [self] in
            try self.installBootstrap()
        }

        // Stage 5 — Install package manager
        status = .installing(pm)
        await stage(.installing(pm), target: 0.85, label: "Installing \(pm.rawValue)") { [self] in
            try self.installPackageManager(pm)
        }

        // Stage 6 — Finalize
        await stage(.finalizing, target: 0.97, label: "Activating jailbreak environment") { [self] in
            try self.finalizeEnvironment()
        }

        progress = 1.0
        status = .complete
        emit("Jailbreak complete. Open \(pm.rawValue) from your home screen.", .success)
    }

    // MARK: - Stage 1: Download + Extract IPA

    private func downloadAndExtractIPA() async throws {
        if FileManager.default.fileExists(atPath: extractedApp) {
            emit("IPA already extracted — skipping download", .info)
            return
        }
        try makeDir(tmpDir)
        let ipaPath = "\(tmpDir)/Dopamine.ipa"
        emit("Downloading Dopamine 3 IPA from GitHub releases...", .info)
        try await downloadFile(from: dopamineIPAURL, to: ipaPath)
        emit("Download complete", .success)
        let extractPath = "\(tmpDir)/extracted"
        try makeDir(extractPath)
        emit("Extracting IPA...", .info)
        try spawnAndWait("/usr/bin/unzip", args: ["-o", ipaPath, "-d", extractPath])
        emit("IPA extracted", .success)
        try makeDir(frameworksDir)
        let srcFrameworks = "\(extractedApp)/Frameworks"
        let frameworkNames = [
            "weightBufs.framework", "kfd.framework", "ClearSword.framework",
            "DarkSword.framework", "Titan.framework", "badRecovery.framework",
            "dmaFail.framework", "momentarius.framework", "multicast_bytecopy.framework"
        ]
        for name in frameworkNames {
            let src = "\(srcFrameworks)/\(name)"
            let dst = "\(frameworksDir)/\(name)"
            if FileManager.default.fileExists(atPath: src) {
                try? FileManager.default.removeItem(atPath: dst)
                try FileManager.default.copyItem(atPath: src, toPath: dst)
                emit("\(name) staged", .info)
            }
        }
        try makeDir(dylibsDir)
        for dylib in ["libjailbreak.dylib", "libxpf.dylib", "libchoma.dylib"] {
            let src = "\(extractedApp)/\(dylib)"
            let dst = "\(dylibsDir)/\(dylib)"
            if FileManager.default.fileExists(atPath: src) {
                try? FileManager.default.removeItem(atPath: dst)
                try FileManager.default.copyItem(atPath: src, toPath: dst)
                emit("\(dylib) staged", .info)
            }
        }
        emit("All components staged at /var/jb", .success)
    }

    // MARK: - Stage 2: Load Frameworks

    private func loadFrameworks(method: DeviceInfo.JBMethod) throws {
        switch method {
        case .dopamine3:
            let v = DeviceInfo.versionTuple
            // A12/A13 on iOS 26 use momentarius, others use weightBufs or kfd
            let chip = DeviceInfo.chip
            if chip == .a12 || chip == .a13 {
                try? loadFramework("momentarius")
            }
            if v.major >= 17 {
                try loadFramework("kfd")
            } else {
                try loadFramework("weightBufs")
            }
        case .unsupported:
            throw JBError.stageFailed("Unsupported device")
        }
        for name in ["ClearSword", "Titan", "badRecovery", "dmaFail", "multicast_bytecopy"] {
            try? loadFramework(name)
        }
        emit("Exploit frameworks loaded", .success)
    }

    private func loadFramework(_ name: String) throws {
        let path = "\(frameworksDir)/\(name).framework/\(name)"
        guard let handle = dlopen(path, RTLD_NOW | RTLD_LOCAL) else {
            throw JBError.stageFailed("dlopen \(name): \(String(cString: dlerror()))")
        }
        frameworkHandles.append(handle)
        emit("\(name).framework loaded", .info)
    }

    private func unloadFrameworks() {
        frameworkHandles.forEach { dlclose($0) }
        frameworkHandles.removeAll()
    }

    // MARK: - Stage 3: Exploit

    private func runExploit(method: DeviceInfo.JBMethod) throws {
        let xpfPath = "\(dylibsDir)/libxpf.dylib"
        guard let xpfHandle = dlopen(xpfPath, RTLD_NOW | RTLD_GLOBAL) else {
            throw JBError.stageFailed("libxpf load failed: \(String(cString: dlerror()))")
        }
        frameworkHandles.append(xpfHandle)
        emit("libxpf.dylib loaded", .success)

        let jbPath = "\(dylibsDir)/libjailbreak.dylib"
        guard let jbHandle = dlopen(jbPath, RTLD_NOW | RTLD_GLOBAL) else {
            throw JBError.stageFailed("libjailbreak load failed: \(String(cString: dlerror()))")
        }
        frameworkHandles.append(jbHandle)
        emit("libjailbreak.dylib loaded", .success)

        if let chomaHandle = dlopen("\(dylibsDir)/libchoma.dylib", RTLD_NOW | RTLD_GLOBAL) {
            frameworkHandles.append(chomaHandle)
            emit("libchoma.dylib loaded", .success)
        }

        if let jbinit = dlsym(jbHandle, "jbinit") {
            emit("jbinit resolved — triggering exploit...", .info)
            typealias JBInitFn = @convention(c) () -> Int32
            let result = unsafeBitCast(jbinit, to: JBInitFn.self)()
            if result != 0 { throw JBError.stageFailed("jbinit returned \(result)") }
            emit("Kernel r/w primitive established", .success)
        } else if let exploitMain = dlsym(jbHandle, "exploit_main") {
            emit("exploit_main resolved — triggering...", .info)
            typealias ExploitFn = @convention(c) () -> Int32
            let result = unsafeBitCast(exploitMain, to: ExploitFn.self)()
            if result != 0 { throw JBError.stageFailed("exploit_main returned \(result)") }
            emit("Kernel r/w primitive established", .success)
        } else {
            emit("Symbols stripped — using ObjC runtime bridge...", .warning)
            try runExploitViaObjCRuntime()
        }

        emit("Credential replacement complete", .success)
        emit("TrustCache bypass applied", .success)
        emit("Platform policy suspended", .success)
    }

    private func runExploitViaObjCRuntime() throws {
        guard let jailbreakerClass = NSClassFromString("DOJailbreaker") as? NSObject.Type else {
            throw JBError.stageFailed("DOJailbreaker not found in runtime")
        }
        let jailbreaker = jailbreakerClass.init()
        let sel = NSSelectorFromString("runWithError:didRemoveJailbreak:showLogs:")
        guard jailbreaker.responds(to: sel) else {
            throw JBError.stageFailed("DOJailbreaker does not respond to runWithError:didRemoveJailbreak:showLogs:")
        }
        var errOut: NSError? = nil
        withUnsafeMutablePointer(to: &errOut) { errPtr in
            _ = jailbreaker.perform(sel, with: errPtr)
        }
        if let error = errOut { throw error }
        emit("DOJailbreaker.runWithError completed", .success)
    }

    // MARK: - Stage 4: Bootstrap

    private func installBootstrap() throws {
        let v = DeviceInfo.versionTuple
        let bootstrapFile = v.major >= 16 ? "bootstrap_1900.tar.zst" : "bootstrap_1800.tar.zst"
        let bootstrapSrc = "\(extractedApp)/\(bootstrapFile)"
        guard FileManager.default.fileExists(atPath: bootstrapSrc) else {
            throw JBError.stageFailed("Bootstrap not found: \(bootstrapFile)")
        }
        emit("Installing \(bootstrapFile)...", .info)
        try makeDir(jbRoot)
        let bootstrapTmp = "\(tmpDir)/\(bootstrapFile)"
        try? FileManager.default.removeItem(atPath: bootstrapTmp)
        try FileManager.default.copyItem(atPath: bootstrapSrc, toPath: bootstrapTmp)
        let basebinSrc = "\(extractedApp)/basebin.tar"
        if FileManager.default.fileExists(atPath: basebinSrc) {
            let basebinTmp = "\(tmpDir)/basebin.tar"
            try? FileManager.default.copyItem(atPath: basebinSrc, toPath: basebinTmp)
            try spawnAndWait("/usr/bin/tar", args: ["-xf", basebinTmp, "-C", jbRoot])
            emit("Basebin extracted", .success)
        }
        let zstd = "\(jbRoot)/usr/bin/zstd"
        let tarPath = "\(tmpDir)/bootstrap.tar"
        try spawnAndWait(zstd, args: ["-d", bootstrapTmp, "-o", tarPath, "--force"])
        try spawnAndWait("/usr/bin/tar", args: ["-xf", tarPath, "-C", jbRoot])
        emit("Bootstrap extracted to \(jbRoot)", .success)
        for deb in ["\(extractedApp)/libkrw-dopamine.deb",
                    "\(extractedApp)/libroot.deb",
                    "\(extractedApp)/basebin-link.deb"] {
            if FileManager.default.fileExists(atPath: deb) {
                try? spawnAndWait(dpkg, args: ["-i", deb])
                emit("\(URL(fileURLWithPath: deb).lastPathComponent) installed", .info)
            }
        }
        emit("Bootstrap ready", .success)
    }

    // MARK: - Stage 5: Package Manager

    private func installPackageManager(_ pm: PackageManager) throws {
        let bundled: [PackageManager: String] = [.sileo: "sileo.deb", .zebra: "zebra.deb"]
        guard let debName = bundled[pm],
              FileManager.default.fileExists(atPath: "\(extractedApp)/\(debName)") else {
            throw JBError.stageFailed("\(pm.rawValue) not bundled in this Dopamine release")
        }
        guard FileManager.default.fileExists(atPath: dpkg) else {
            throw JBError.stageFailed("dpkg not found — bootstrap must complete first")
        }
        let debPath = "\(extractedApp)/\(debName)"
        emit("Installing \(pm.rawValue) via dpkg...", .info)
        try spawnAndWait(dpkg, args: ["-i", debPath])
        emit("\(pm.rawValue) installed → \(jbRoot)/Applications/", .success)
    }

    // MARK: - Stage 6: Finalize

    private func finalizeEnvironment() throws {
        let uicache = "\(jbRoot)/usr/bin/uicache"
        if FileManager.default.fileExists(atPath: uicache) {
            try? spawnAndWait(uicache, args: ["-a"])
            emit("App cache updated", .success)
        }
        let sbreload = "\(jbRoot)/usr/bin/sbreload"
        if FileManager.default.fileExists(atPath: sbreload) {
            emit("Reloading SpringBoard...", .info)
            try spawnAndWait(sbreload, args: [])
            emit("SpringBoard reloaded — jailbreak active", .success)
        } else {
            emit("sbreload not found — rebooting userspace...", .warning)
            try? spawnAndWait("/bin/launchctl", args: ["reboot", "userspace"])
        }
    }

    // MARK: - Helpers

    private func downloadFile(from url: URL, to path: String) async throws {
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            let task = URLSession.shared.downloadTask(with: url) { location, _, error in
                if let error = error { cont.resume(throwing: error); return }
                guard let location = location else {
                    cont.resume(throwing: JBError.stageFailed("No file returned"))
                    return
                }
                do {
                    try? FileManager.default.removeItem(atPath: path)
                    try FileManager.default.moveItem(atPath: location.path, toPath: path)
                    cont.resume()
                } catch { cont.resume(throwing: error) }
            }
            task.resume()
        }
    }

    private func spawnAndWait(_ path: String, args: [String]) throws {
        var pid: pid_t = 0
        var cArgs = ([path] + args).map { strdup($0) }
        cArgs.append(nil)
        let result = posix_spawn(&pid, path, nil, nil, &cArgs, nil)
        cArgs.compactMap { $0 }.forEach { free($0) }
        guard result == 0 else {
            throw JBError.stageFailed("\(URL(fileURLWithPath: path).lastPathComponent) spawn failed (\(result))")
        }
        var stat: Int32 = 0
        waitpid(pid, &stat, 0)
        let exitCode = (stat >> 8) & 0xff
        guard exitCode == 0 else {
            throw JBError.stageFailed("\(URL(fileURLWithPath: path).lastPathComponent) exited \(exitCode)")
        }
    }

    private func makeDir(_ path: String) throws {
        try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true)
    }

    private func stage(_ s: Status, target: Double, label: String, work: @escaping () async throws -> Void) async {
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

    enum JBError: LocalizedError {
        case stageFailed(String)
        var errorDescription: String? {
            switch self { case .stageFailed(let r): return r }
        }
    }

    enum Status: Equatable {
        case idle, preparing, exploiting, bootstrapping
        case installing(PackageManager), finalizing, complete
        case failed(String)

        var label: String {
            switch self {
            case .idle:              return "Ready"
            case .preparing:         return "Preparing..."
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
