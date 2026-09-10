import Foundation
import Darwin

/// Checks which entitlements are active at runtime.
/// Private entitlements are stripped by standard signers (Sideloadly, AltStore)
/// but preserved when installed via TrollStore or signed with ldid / CoreTrust.
struct EntitlementChecker {

    enum SignerType: String {
        case trollStore = "TrollStore"
        case ldid       = "ldid / CoreTrust"
        case freeSigner = "Sideloadly / AltStore"
        case unknown    = "Unknown"
    }

    /// Detects signer type based on runtime path and available entitlements
    static var detectedSigner: SignerType {
        let bundlePath = Bundle.main.bundlePath
        if bundlePath.contains("/var/containers/Bundle/Application/") {
            if hasPlatformApplication {
                return .trollStore
            }
            return .ldid
        }
        if hasPlatformApplication {
            return .ldid
        }
        return .freeSigner
    }

    /// Whether the app has platform-application entitlement.
    /// TrollStore preserves this entitlement.
    static var hasPlatformApplication: Bool {
        return checkPlatformEntitlement()
    }

    private static func checkPlatformEntitlement() -> Bool {
        // Attempt task_for_pid on current process or test entitlement
        var task = mach_port_t(MACH_PORT_NULL)
        let selfTask = mach_task_self_
        let kr = task_for_pid(selfTask, getpid(), &task)
        if kr == KERN_SUCCESS && task != mach_port_t(MACH_PORT_NULL) {
            mach_port_deallocate(selfTask, task)
            return true
        }
        return false
    }

    /// Whether the sandbox is disabled (com.apple.private.security.no-sandbox).
    /// Required for writing outside the application sandbox container.
    static var isSandboxDisabled: Bool {
        let testDir = "/var/mobile/Library/Caches"
        let testPath = "\(testDir)/.galactic_test_\(UUID().uuidString)"
        let testData = "sandbox_check".data(using: .utf8)
        
        if FileManager.default.createFile(atPath: testPath, contents: testData) {
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
            lines.append(("Exploit requires TrollStore private entitlements", "warning"))
        }

        if sandbox {
            lines.append(("Sandbox disabled ✓", "success"))
        } else {
            lines.append(("⚠ Sandbox active — unsandboxed writes will fail", "warning"))
        }

        if platform && sandbox {
            lines.append(("All entitlements active — ready to jailbreak ✓", "success"))
        } else {
            lines.append(("Recommendation: reinstall via TrollStore", "warning"))
        }

        return lines
    }
}
