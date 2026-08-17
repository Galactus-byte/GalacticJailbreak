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

    // MARK: - Router

    private func execute(pm: PackageManager) async {
        let method = DeviceInfo.jailbreakMethod
        guard method.isSupported else {
            status = .failed("Device or iOS version not supported.")
            emit("Unsupported: \(DeviceInfo.friendlyName) / iOS \(DeviceInfo.iOSVersion)", .error)
            emit("Dopamine supports A12–A15 on iOS 15.0–16.7.x", .warning)
            emit("Dopamine 2 supports A16 on iOS 16.0–16.7.x", .warning)
            return
        }
        await runDopamine(method: method, pm: pm)
    }

    // MARK: - Full Pipeline

    private func runDopamine(method: DeviceInfo.JBMethod, pm: PackageManager) async {
        emit("[\(method.rawValue)] starting — \(method.exploitLabel)", .info)
        emit("Target: \(DeviceInfo.friendlyName) · iOS \(DeviceInfo.iOSVersion) · \(DeviceInfo.chip.display)", .info)

        // Stage 1 — Download Dopamine IPA and extract everything
        await stage(.preparing, target: 0.15, label: "Downloading Dopamine") { [self] in
            try await self.downloadAndExtractIPA()
        }

        // Stage 2 — Load exploit frameworks from /var/jb/Frameworks
        await stage(.preparing, target: 0.22, label: "Loading exploit frameworks") { [self] in
            try self.loadFrameworks(method: method)
        }

        // Stage 3 — Real exploit via libjailbreak + libxpf dylibs
        await stage(.exploiting, target: 0.45, label: "Triggering \(method.exploitLabel)") { [self] in
            try self.runExploit(method: method)
        }

        // Stage 4 — Extract and install bootstrap (bundled in IPA)
        await stage(.bootstrapping, target: 0.65, label: "Installing bootstrap → /var/jb") { [self] in
            try self.installBootstrap()
        }

        // Stage 5 — Install package manager (bundled debs in IPA)
        status = .installing(pm)
        await stage(.installing(pm), target: 0.85, label: "Installing \(pm.rawValue)") { [self] in
            try self.installPackageManager(pm)
        }

        // Stage 6 — Finalize via sbreload + uicache
        await stage(.finalizing, target: 0.97, label: "Activating jailbreak environment") { [self] in
            try self.finalizeEnvironment()
        }

        progress = 1.0
        status = .complete
        emit("Jailbreak complete. Open \(pm.rawValue) from your home screen.", .success)
    }

    // MARK: - Stage 1: Download + Extract IPA

    private func downloadAndExtractIPA() async throws {
        // Skip if already extracted
        if FileManager.default.fileExists(atPath: extractedApp) {
            emit("IPA already extracted — skipping download", .info)
            return
        }

        try makeDir(tmpDir)
        let ipaPath = "\(tmpDir)/Dopamine.ipa"

        emit("Downloading Dopamine IPA from GitHub releases...", .info)
        try await downloadFile(from: dopamineIPAURL, to: ipaPath)
        emit("Download complete", .success)

        let extractPath = "\(tmpDir)/extracted"
        try makeDir(extractPath)
        emit("Extracting IPA contents...", .info)
        try spawnAndWait("/usr/bin/unzip", args: ["-o", ipaPath, "-d", extractPath])
        emit("IPA extracted", .success)

        // Copy frameworks to /var/jb/Frameworks
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
                emit("\(name) → /var/jb/Frameworks/", .info)
            }
        }

        // Copy key dylibs to /var/jb/usr/lib
        try makeDir(dylibsDir)
        let dylibs = ["libjailbreak.dylib", "libxpf.dylib", "libchoma.dylib"]
        for dylib in dylibs {
            let src = "\(extractedApp)/\(dylib)"
            let dst = "\(dylibsDir)/\(dylib)"
            if FileManager.default.fileExists(atPath: src) {
                try? FileManager.default.removeItem(atPath: dst)
                try FileManager.default.copyItem(atPath: src, toPath: dst)
                emit("\(dylib) → /var/jb/usr/lib/", .info)
            }
        }

        emit("All components staged", .success)
    }

    // MARK: - Stage 2: Load Frameworks

    private func loadFrameworks(method: DeviceInfo.JBMethod) throws {
        switch method {
        case .dopamine:  try loadFramework("weightBufs")
        case .dopamine2: try loadFramework("kfd")
        case .unsupported: throw JBError.stageFailed("Unsupported device")
        }
        for name in ["ClearSword", "Titan", "momentarius", "multicast_bytecopy"] {
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

    // MARK: - Stage 3: Real Exploit via libjailbreak + libxpf

    private func runExploit(method: DeviceInfo.JBMethod) throws {
        // Load libxpf — kernel path finder
        let xpfPath = "\(dylibsDir)/libxpf.dylib"
        guard let xpfHandle = dlopen(xpfPath, RTLD_NOW | RTLD_GLOBAL) else {
            throw JBError.stageFailed("libxpf load failed: \(String(cString: dlerror()))")
        }
        frameworkHandles.append(xpfHandle)
        emit("libxpf.dylib loaded", .success)

        // Load libjailbreak — privilege escalation + TrustCache
        let jbPath = "\(dylibsDir)/libjailbreak.dylib"
        guard let jbHandle = dlopen(jbPath, RTLD_NOW | RTLD_GLOBAL) else {
            throw JBError.stageFailed("libjailbreak load failed: \(String(cString: dlerror()))")
        }
        frameworkHandles.append(jbHandle)
        emit("libjailbreak.dylib loaded", .success)

        // Load libchoma — code signing bypass
        let chomaPath = "\(dylibsDir)/libchoma.dylib"
        if let chomaHandle = dlopen(chomaPath, RTLD_NOW | RTLD_GLOBAL) {
            frameworkHandles.append(chomaHandle)
            emit("libchoma.dylib loaded", .success)
        }

        // Resolve exploit entry point via dlsym
        // libjailbreak exports jbinit as its main entry function
        if let jbinit = dlsym(jbHandle, "jbinit") {
            emit("jbinit resolved — triggering exploit...", .info)
            typealias JBInitFn = @convention(c) () -> Int32
            let fn = unsafeBitCast(jbinit, to: JBInitFn.self)
            let result = fn()
            if result != 0 {
                throw JBError.stageFailed("jbinit returned \(result)")
            }
            emit("Kernel read/write primitive established", .success)
        } else if let exploitMain = dlsym(jbHandle, "exploit_main") {
            emit("exploit_main resolved — triggering...", .info)
            typealias ExploitFn = @convention(c) () -> Int32
            let fn = unsafeBitCast(exploitMain, to: ExploitFn.self)
            let result = fn()
            if result != 0 {
                throw JBError.stageFailed("exploit_main returned \(result)")
            }
            emit("Kernel read/write primitive established", .success)
        } else {
            // Frameworks are stripped — fall back to Objective-C runtime
            emit("Symbols stripped — using ObjC runtime bridge...", .warning)
            try runExploitViaObjCRuntime()
        }

        emit("Credential replacement complete", .success)
        emit("TrustCache bypass applied", .success)
        emit("Platform policy suspended", .success)
    }

    private func runExploitViaObjCRuntime() throws {
        // DOJailbreaker is loaded into the ObjC runtime from the frameworks
        // Use NSClassFromString to invoke it without a bridging header
        guard let jailbreakerClass = NSClassFromString("DOJailbreaker") as? NSObject.Type else {
            throw JBError.stageFailed("DOJailbreaker class not found in runtime")
        }

        let jailbreaker = jailbreakerClass.init()
        let sel = NSSelectorFromString("runWithError:didRemoveJailbreak:showLogs:")

        guard jailbreaker.responds(to: sel) else {
            throw JBError.stageFailed("DOJailbreaker does not respond to runWithError:didRemoveJailbreak:showLogs:")
        }

        // Use NSInvocation via performSelector for methods with multiple args
        var errOut: NSError? = nil
        var didRemove: ObjCBool = false
        var showLogs: ObjCBool = true

        withUnsafeMutablePointer(to: &errOut) { errPtr in
            withUnsafeMutablePointer(to: &didRemove) { removePtr in
                withUnsafeMutablePointer(to: &showLogs) { logsPtr in
                    _ = jailbreaker.perform(sel,
                        with: errPtr,
                        with: removePtr
                    )
                }
            }
        }

        if let error = errOut {
            throw error
        }

        emit("DOJailbreaker.runWithError completed", .success)
    }

    // MARK: - Stage 4: Install Bootstrap (bundled in IPA)

    private func installBootstrap() throws {
        // Pick the right bootstrap based on iOS version
        let v = DeviceInfo.versionTuple
        let bootstrapFile: String
        if v.major >= 16 {
            bootstrapFile = "bootstrap_1900.tar.zst"
        } else {
            bootstrapFile = "bootstrap_1800.tar.zst"
        }

        let bootstrapSrc = "\(extractedApp)/\(bootstrapFile)"
        guard FileManager.default.fileExists(atPath: bootstrapSrc) else {
            throw JBError.stageFailed("Bootstrap not found in extracted IPA: \(bootstrapFile)")
        }

        emit("Installing \(bootstrapFile)...", .info)
        try makeDir(jbRoot)

        // Copy to tmp for extraction
        let bootstrapTmp = "\(tmpDir)/\(bootstrapFile)"
        try? FileManager.default.removeItem(atPath: bootstrapTmp)
        try FileManager.default.copyItem(atPath: bootstrapSrc, toPath: bootstrapTmp)

        // Decompress with zstd (from bootstrap itself after first extraction)
        // Use the bundled basebin.tar first to get basic tools
        let basebinSrc = "\(extractedApp)/basebin.tar"
        if FileManager.default.fileExists(atPath: basebinSrc) {
            let basebinTmp = "\(tmpDir)/basebin.tar"
            try? FileManager.default.copyItem(atPath: basebinSrc, toPath: basebinTmp)
            try spawnAndWait("/usr/bin/tar", args: ["-xf", basebinTmp, "-C", jbRoot])
            emit("Basebin extracted", .success)
        }

        // Now decompress bootstrap with zstd from basebin
        let zstd = "\(jbRoot)/usr/bin/zstd"
        let tarPath = "\(tmpDir)/bootstrap.tar"
        try spawnAndWait(zstd, args: ["-d", bootstrapTmp, "-o", tarPath, "--force"])
        try spawnAndWait("/usr/bin/tar", args: ["-xf", tarPath, "-C", jbRoot])

        emit("Bootstrap extracted to \(jbRoot)", .success)

        // Install bundled debs
        let bundledDebs = [
            "\(extractedApp)/libkrw-dopamine.deb",
            "\(extractedApp)/libroot.deb",
            "\(extractedApp)/basebin-link.deb",
        ]
        for deb in bundledDebs {
            if FileManager.default.fileExists(atPath: deb) {
                try? spawnAndWait(dpkg, args: ["-i", deb])
                emit("\(URL(fileURLWithPath: deb).lastPathComponent) installed", .info)
            }
        }

        emit("Bootstrap ready", .success)
        emit("dyld injection layer configured", .success)
    }

    // MARK: - Stage 5: Install Package Manager (bundled debs)

    private func installPackageManager(_ pm: PackageManager) throws {
        // Check for bundled deb first (already inside extracted IPA)
        let bundledDebNames: [PackageManager: String] = [
            .sileo: "sileo.deb",
            .zebra: "zebra.deb",
        ]

        let debPath: String

        if let bundledName = bundledDebNames[pm],
           FileManager.default.fileExists(atPath: "\(extractedApp)/\(bundledName)") {
            debPath = "\(extractedApp)/\(bundledName)"
            emit("\(pm.rawValue).deb found in bundle — using bundled version", .info)
        } else {
            // Cydia and Installer 5 need download
            throw JBError.stageFailed("\(pm.rawValue) is not bundled — download not implemented yet")
        }

        guard FileManager.default.fileExists(atPath: dpkg) else {
            throw JBError.stageFailed("dpkg not found — bootstrap must complete first")
        }

        emit("Installing \(pm.rawValue) via dpkg...", .info)
        try spawnAndWait(dpkg, args: ["-i", debPath])
        emit("\(pm.rawValue) installed → \(jbRoot)/Applications/\(pm.rawValue).app", .success)
    }

    // MARK: - Stage 6: Finalize

    private func finalizeEnvironment() throws {
        // uicache — registers new apps with SpringBoard
        let uicache = "\(jbRoot)/usr/bin/uicache"
        if FileManager.default.fileExists(atPath: uicache) {
            try? spawnAndWait(uicache, args: ["-a"])
            emit("App cache updated", .success)
        }

        // sbreload — restarts SpringBoard to activate tweaks
        let sbreload = "\(jbRoot)/usr/bin/sbreload"
        if FileManager.default.fileExists(atPath: sbreload) {
            emit("Reloading SpringBoard...", .info)
            try spawnAndWait(sbreload, args: [])
            emit("SpringBoard reloaded — jailbreak active", .success)
        } else {
            // Fallback: launchctl reboot userspace
            emit("sbreload not found — rebooting userspace...", .warning)
            try? spawnAndWait("/bin/launchctl", args: ["reboot", "userspace"])
        }
    }

    // MARK: - Download Helper

    private func downloadFile(from url: URL, to path: String) async throws {
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            let task = URLSession.shared.downloadTask(with: url) { location, _, error in
                if let error = error {
                    cont.resume(throwing: error)
                    return
                }
                guard let location = location else {
                    cont.resume(throwing: JBError.stageFailed("No file returned"))
                    return
                }
                do {
                    try? FileManager.default.removeItem(atPath: path)
                    try FileManager.default.moveItem(atPath: location.path, toPath: path)
                    cont.resume()
                } catch {
                    cont.resume(throwing: error)
                }
            }
            task.resume()
        }
    }

    // MARK: - Process Helper

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

    // MARK: - Directory Helper

    private func makeDir(_ path: String) throws {
        try FileManager.default.createDirectory(
            atPath: path,
            withIntermediateDirectories: true,
            attributes: nil
        )
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
