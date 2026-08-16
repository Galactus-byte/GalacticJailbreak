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

    // MARK: - Friendly Device Name

    static var friendlyName: String {
        let id = modelIdentifier
        // iPhone
        if id.matches(prefixes: ["iPhone7"])  { return "iPhone 6s" }
        if id.matches(prefixes: ["iPhone8,1"]) { return "iPhone 6s" }
        if id.matches(prefixes: ["iPhone8,2"]) { return "iPhone 6s Plus" }
        if id.matches(prefixes: ["iPhone8,4"]) { return "iPhone SE (1st gen)" }
        if id.matches(prefixes: ["iPhone9,1", "iPhone9,3"]) { return "iPhone 7" }
        if id.matches(prefixes: ["iPhone9,2", "iPhone9,4"]) { return "iPhone 7 Plus" }
        if id.matches(prefixes: ["iPhone10,1", "iPhone10,4"]) { return "iPhone 8" }
        if id.matches(prefixes: ["iPhone10,2", "iPhone10,5"]) { return "iPhone 8 Plus" }
        if id.matches(prefixes: ["iPhone10,3", "iPhone10,6"]) { return "iPhone X" }
        if id.matches(prefixes: ["iPhone11,2"]) { return "iPhone XS" }
        if id.matches(prefixes: ["iPhone11,4", "iPhone11,6"]) { return "iPhone XS Max" }
        if id.matches(prefixes: ["iPhone11,8"]) { return "iPhone XR" }
        if id.matches(prefixes: ["iPhone12,1"]) { return "iPhone 11" }
        if id.matches(prefixes: ["iPhone12,3"]) { return "iPhone 11 Pro" }
        if id.matches(prefixes: ["iPhone12,5"]) { return "iPhone 11 Pro Max" }
        if id.matches(prefixes: ["iPhone12,8"]) { return "iPhone SE (2nd gen)" }
        if id.matches(prefixes: ["iPhone13,1"]) { return "iPhone 12 mini" }
        if id.matches(prefixes: ["iPhone13,2"]) { return "iPhone 12" }
        if id.matches(prefixes: ["iPhone13,3"]) { return "iPhone 12 Pro" }
        if id.matches(prefixes: ["iPhone13,4"]) { return "iPhone 12 Pro Max" }
        if id.matches(prefixes: ["iPhone14,4"]) { return "iPhone 13 mini" }
        if id.matches(prefixes: ["iPhone14,5"]) { return "iPhone 13" }
        if id.matches(prefixes: ["iPhone14,2"]) { return "iPhone 13 Pro" }
        if id.matches(prefixes: ["iPhone14,3"]) { return "iPhone 13 Pro Max" }
        if id.matches(prefixes: ["iPhone14,6"]) { return "iPhone SE (3rd gen)" }
        if id.matches(prefixes: ["iPhone14,7"]) { return "iPhone 14" }
        if id.matches(prefixes: ["iPhone14,8"]) { return "iPhone 14 Plus" }
        if id.matches(prefixes: ["iPhone15,2"]) { return "iPhone 14 Pro" }
        if id.matches(prefixes: ["iPhone15,3"]) { return "iPhone 14 Pro Max" }
        if id.matches(prefixes: ["iPhone15,4"]) { return "iPhone 15" }
        if id.matches(prefixes: ["iPhone15,5"]) { return "iPhone 15 Plus" }
        if id.matches(prefixes: ["iPhone16,1"]) { return "iPhone 15 Pro" }
        if id.matches(prefixes: ["iPhone16,2"]) { return "iPhone 15 Pro Max" }
        // iPad
        if id.matches(prefixes: ["iPad15,7"]) { return "iPad (A16) Wi-Fi" }
        if id.matches(prefixes: ["iPad15,8"]) { return "iPad (A16) Wi-Fi + Cellular" }
        if id.matches(prefixes: ["iPad15,3", "iPad15,4"]) { return "iPad Air 11\" M2" }
        if id.matches(prefixes: ["iPad15,5", "iPad15,6"]) { return "iPad Air 13\" M2" }
        if id.matches(prefixes: ["iPad14,8", "iPad14,9"]) { return "iPad Air 11\" M1" }
        if id.matches(prefixes: ["iPad14,10", "iPad14,11"]) { return "iPad Air 13\" M1" }
        if id.matches(prefixes: ["iPad16,3", "iPad16,4"]) { return "iPad Pro 11\" M4" }
        if id.matches(prefixes: ["iPad16,5", "iPad16,6"]) { return "iPad Pro 13\" M4" }
        if id.matches(prefixes: ["iPad13,18", "iPad13,19"]) { return "iPad (10th gen)" }
        if id.matches(prefixes: ["iPad11,6", "iPad11,7"]) { return "iPad (8th gen)" }
        if id.matches(prefixes: ["iPad12,1", "iPad12,2"]) { return "iPad (9th gen)" }
        return id
    }

    // MARK: - Chip Detection

    static var chip: ChipGen {
        let id = modelIdentifier
        // A8
        if id.matches(prefixes: ["iPhone7", "iPad5,1", "iPad5,2", "iPad5,3", "iPad5,4"]) { return .a8 }
        // A9
        if id.matches(prefixes: ["iPhone8", "iPad6,3", "iPad6,4", "iPad6,7", "iPad6,8"]) { return .a9 }
        // A10
        if id.matches(prefixes: ["iPhone9", "iPad6,11", "iPad6,12", "iPad7"]) { return .a10 }
        // A11
        if id.matches(prefixes: ["iPhone10"]) { return .a11 }
        // A12
        if id.matches(prefixes: ["iPhone11", "iPad8", "iPad11"]) { return .a12 }
        // A13
        if id.matches(prefixes: ["iPhone12", "iPad11,6", "iPad11,7"]) { return .a13 }
        // A14
        if id.matches(prefixes: ["iPhone13", "iPad13,1", "iPad13,2",
                                  "iPad13,18", "iPad13,19"]) { return .a14 }
        // A15
        if id.matches(prefixes: ["iPhone14", "iPad14,1", "iPad14,2"]) { return .a15 }
        // A16 — iPhone 14 Pro, iPhone 15, iPad (A16)
        if id.matches(prefixes: ["iPhone15", "iPad15,7", "iPad15,8"]) { return .a16 }
        // A17 Pro — iPhone 15 Pro
        if id.matches(prefixes: ["iPhone16"]) { return .a17 }
        // M-series iPads
        if id.matches(prefixes: ["iPad15,3", "iPad15,4", "iPad15,5", "iPad15,6"]) { return .m2 }
        if id.matches(prefixes: ["iPad16"]) { return .m4 }
        return .unknown
    }

    static var jailbreakMethod: JBMethod {
        let v = versionTuple
        switch chip {
        // A8–A11 — requires computer (palera1n), not supported in app
        case .a8, .a9, .a10, .a11:
            return .unsupported

        // A12–A15 — Dopamine (weightBufs, fully on-device)
        case .a12, .a13, .a14, .a15:
            guard v.major == 15 || (v.major == 16 && v.minor <= 7) else { return .unsupported }
            return .dopamine

        // A16 — Dopamine 2 (kfd / XPF)
        case .a16:
            guard v.major == 16 && v.minor <= 7 else { return .unsupported }
            return .dopamine2

        // A17, M-series — no jailbreak available
        case .a17, .m2, .m4, .unknown:
            return .unsupported
        }
    }

    // MARK: - Nested Types

    enum ChipGen: String {
        case a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, m2, m4, unknown

        var display: String {
            switch self {
            case .a8:    return "A8"
            case .a9:    return "A9"
            case .a10:   return "A10"
            case .a11:   return "A11"
            case .a12:   return "A12"
            case .a13:   return "A13"
            case .a14:   return "A14"
            case .a15:   return "A15"
            case .a16:   return "A16"
            case .a17:   return "A17 Pro"
            case .m2:    return "M2"
            case .m4:    return "M4"
            case .unknown: return "Unknown"
            }
        }
    }

    enum JBMethod: String {
        case dopamine   = "Dopamine"
        case dopamine2  = "Dopamine 2"
        case unsupported = "Unsupported"

        var isSupported: Bool { self != .unsupported }

        var exploitLabel: String {
            switch self {
            case .dopamine:    return "weightBufs kernel r/w"
            case .dopamine2:   return "kfd / XPF primitive"
            case .unsupported: return "—"
            }
        }

        var badge: Color {
            switch self {
            case .dopamine:    return .purple
            case .dopamine2:   return .cyan
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
