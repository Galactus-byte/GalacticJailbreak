import Foundation
import Darwin

/// Checks which entitlements are active at runtime.
/// Private entitlements are stripped by free signers (Sideloadly, AltStore, KSign)
/// but preserved by TrollStore, ldid, and zsign.
struct EntitlementChecker {

    enum SignerType: String {
        case trollStore = "TrollStore"
        case ldid       = "ldid / zsign"
        case freeSigner = "Sideloadly / AltStore / KSign"
        case unknown    = "Unknown"
    }

    /// Detects signer type based on available entitlements at runtime
    static var detectedSigner: SignerType {
        if hasPlatformApplication {
            if FileManager.default.fileExists(
                atPath: "/var/containers/Bundle/Application/.com.apple.mobile_installation.metadata.db"
            ) {
                return .trollStore
            }
            return .ldid
        }
        return .freeSigner
    }

    /// Whether the app has platform-application entitlement.
    /// Without this the kernel exploit will be rejected.
    static var hasPlatformApplication: Bool {
        return checkPlatformEntitlement()
    }

    private static func checkPlatformEntitlement() -> Bool {
        // Attempt task_for_pid on pid 1 (launchd)
        // Only succeeds with platform-application entitlement
        var task = mach_port_t(MACH_PORT_NULL)
        let self_task = mach_task_self_
        let kr = task_for_pid(self_task, 1, &task)
        if kr == KERN_SUCCESS && task != mach_port_t(MACH_PORT_NULL) {
            mach_port_deallocate(self_task, task)
            return true
        }
        return false
    }

    /// Whether the sandbox is disabled.
    /// Required for writing to /var/jb/
    static var isSandboxDisabled: Bool {
        let testPath = "/var/testGalactic_\(Int.random(in: 1000...9999))"
        let created = FileManager.default.createFile(atPath: testPath, contents: nil)
        if created {
            try? FileManager.default.removeItem(atPath: testPath)
            return true
        }
        return false
    }

    /// Full entitlement status report for the log console
    static var report: [(message: String, level: String)] {
        let signer = detectedSigner
        let platform = hasPlatformApplication
        let sandbox = isSandboxDisabled

        var lines: [(String, String)] = []
        lines.append(("Signer detected: \(signer.rawValue)", "info"))

        if platform {
            lines.append(("platform-application entitlement active ✓", "success"))
        } else {
            lines.append(("⚠ platform-application missing — install via TrollStore", "warning"))
            lines.append(("Exploit will fail at Stage 3 without this entitlement", "warning"))
        }

        if sandbox {
            lines.append(("Sandbox disabled ✓", "success"))
        } else {
            lines.append(("⚠ Sandbox active — /var/jb writes will fail", "warning"))
        }

        if platform && sandbox {
            lines.append(("All entitlements active — ready to jailbreak ✓", "success"))
        } else {
            lines.append(("Recommendation: reinstall via TrollStore", "warning"))
        }

        return lines
    }
}
