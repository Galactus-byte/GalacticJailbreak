import Foundation

/// Checks which entitlements are active at runtime.
/// Private entitlements are stripped by free signers (Sideloadly, AltStore)
/// but preserved by TrollStore, ldid, and zsign.
struct EntitlementChecker {

    enum SignerType: String {
        case trollStore   = "TrollStore"
        case ldid         = "ldid / zsign"
        case freeSigner   = "Sideloadly / AltStore"
        case unknown      = "Unknown"
    }

    /// Detects signer type based on available entitlements at runtime
    static var detectedSigner: SignerType {
        // platform-application is only present when signed by TrollStore or ldid
        // We check by trying to access a platform-only API
        if hasPlatformApplication {
            // TrollStore installs to /var/containers differently
            if FileManager.default.fileExists(atPath: "/var/containers/Bundle/Application/.com.apple.mobile_installation.metadata.db") {
                return .trollStore
            }
            return .ldid
        }
        return .freeSigner
    }

    /// Whether the app has platform-application entitlement
    /// Without this, the kernel exploit will be rejected
    static var hasPlatformApplication: Bool {
        // Check if we can access proc_info — a reliable indicator
        // of platform-application being active
        let result = sysctlbyname("kern.boottime", nil, nil, nil, 0)
        // This always works, but platform apps can do much more
        // Real check: try to task_for_pid on another process
        return checkPlatformEntitlement()
    }

    private static func checkPlatformEntitlement() -> Bool {
        // Attempt task_for_pid on pid 1 (launchd)
        // This only succeeds with platform-application entitlement
        var task: mach_port_t = 0
        let kr = task_for_pid(mach_task_self(), 1, &task)
        if kr == KERN_SUCCESS && task != 0 {
            mach_port_deallocate(mach_task_self_, task)
            return true
        }
        return false
    }

    /// Whether sandbox is disabled
    static var isSandboxDisabled: Bool {
        // Try writing outside sandbox boundary
        let testPath = "/var/testGalactic"
        let result = FileManager.default.createFile(atPath: testPath, contents: nil)
        if result {
            try? FileManager.default.removeItem(atPath: testPath)
            return true
        }
        return false
    }

    /// Full entitlement status report
    static var report: String {
        let signer = detectedSigner
        let platform = hasPlatformApplication
        let sandbox = isSandboxDisabled

        return """
        Signer: \(signer.rawValue)
        platform-application: \(platform ? "✓" : "✗ — exploit will fail")
        no-sandbox: \(sandbox ? "✓" : "✗ — /var/jb writes will fail")
        Recommendation: \(platform ? "Ready to jailbreak" : "Install via TrollStore for full entitlements")
        """
    }
}

// MARK: - Darwin imports for task_for_pid
import Darwin
import MachO
