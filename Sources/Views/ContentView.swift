import UIKit
import Foundation
import SwiftUI

struct DeviceInfo {

    // MARK: - Hardware Identification

    static var modelIdentifier: String {
        var info = utsname()
        uname(&info)
        return withUnsafePointer(to: &info.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) { String(cString: $0) }
        }
    }

    static var iOSVersion: String { UIDevice.current.systemVersion }

    static var versionTuple: (major: Int, minor: Int, patch: Int) {
        let parts = iOSVersion.split(separator: ".").compactMap { Int($0) }
        return (
            parts.indices.contains(0) ? parts[0] : 0,
            parts.indices.contains(1) ? parts[1] : 0,
            parts.indices.contains(2) ? parts[2] : 0
        )
    }

    static var chip: ChipGen {
        let id = modelIdentifier
        // A8 / A8X
        if id.matches(prefixes: ["iPhone7", "iPad5,1", "iPad5,2", "iPad5,3", "iPad5,4"]) { return .a8 }
        // A9 / A9X
        if id.matches(prefixes: ["iPhone8", "iPad6,3", "iPad6,4", "iPad6,7", "iPad6,8"]) { return .a9 }
        // A10 / A10X
        if id.matches(prefixes: ["iPhone9", "iPad6,11", "iPad6,12", "iPad7"]) { return .a10 }
        // A11 — last checkm8 generation
        if id.matches(prefixes: ["iPhone10"]) { return .a11 }
        // A12 / A12X / A12Z
        if id.matches(prefixes: ["iPhone11", "iPad8", "iPad11"]) { return .a12 }
        // A13
        if id.matches(prefixes: ["iPhone12", "iPad11,6", "iPad11,7"]) { return .a13 }
        // A14
        if id.matches(prefixes: ["iPhone13", "iPad13,1", "iPad13,2", "iPad13,4",
                                  "iPad13,5", "iPad13,6", "iPad13,7"]) { return .a14 }
        // A15
        if id.matches(prefixes: ["iPhone14", "iPad14,1", "iPad14,2"]) { return .a15 }
        // A16
        if id.matches(prefixes: ["iPhone15"]) { return .a16 }
        return .unknown
    }

    static var jailbreakMethod: JBMethod {
        let v = versionTuple
        switch chip {
        // A8–A11 — requires a computer, not supported in app
        case .a8, .a9, .a10, .a11:
            return .unsupported

        // A12–A15 — Dopamine (weightBufs exploit, fully on-device)
        case .a12, .a13, .a14, .a15:
            guard v.major == 15 || (v.major == 16 && v.minor <= 7) else { return .unsupported }
            return .dopamine

        // A16 — Dopamine 2 (kfd / XPF exploit)
        case .a16:
            guard v.major == 16 && v.minor <= 7 else { return .unsupported }
            return .dopamine2

        case .unknown:
            return .unsupported
        }
    }

    // MARK: - Nested Types

    enum ChipGen: String {
        case a8, a9, a10, a11, a12, a13, a14, a15, a16, unknown
        var display: String { rawValue.uppercased() }
    }

    enum JBMethod: String {
        case dopamine  = "Dopamine"
        case dopamine2 = "Dopamine 2"
        case unsupported = "Unsupported"

        var isSupported: Bool { self != .unsupported }

        var exploitLabel: String {
            switch self {
            case .dopamine:   return "weightBufs kernel r/w"
            case .dopamine2:  return "kfd / XPF primitive"
            case .unsupported: return "—"
            }
        }

        var badge: Color {
            switch self {
            case .dopamine:   return .purple
            case .dopamine2:  return .cyan
            case .unsupported: return .red
            }
        }
    }
}

// MARK: - String prefix helper
private extension String {
    func matches(prefixes: [String]) -> Bool {
        prefixes.contains { hasPrefix($0) }
    }
}
