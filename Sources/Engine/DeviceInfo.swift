import UIKit
import Foundation
import SwiftUI

struct DeviceInfo {

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

    static var friendlyName: String {
        let id = modelIdentifier
        if id.matches(prefixes: ["iPhone7,1"])  { return "iPhone 6 Plus" }
        if id.matches(prefixes: ["iPhone7,2"])  { return "iPhone 6" }
        if id.matches(prefixes: ["iPhone8,1"])  { return "iPhone 6s" }
        if id.matches(prefixes: ["iPhone8,2"])  { return "iPhone 6s Plus" }
        if id.matches(prefixes: ["iPhone8,4"])  { return "iPhone SE (1st gen)" }
        if id.matches(prefixes: ["iPhone9,1", "iPhone9,3"]) { return "iPhone 7" }
        if id.matches(prefixes: ["iPhone9,2", "iPhone9,4"]) { return "iPhone 7 Plus" }
        if id.matches(prefixes: ["iPhone10,1", "iPhone10,4"]) { return "iPhone 8" }
        if id.matches(prefixes: ["iPhone10,2", "iPhone10,5"]) { return "iPhone 8 Plus" }
        if id.matches(prefixes: ["iPhone10,3", "iPhone10,6"]) { return "iPhone X" }
        if id.matches(prefixes: ["iPhone11,2"])  { return "iPhone XS" }
        if id.matches(prefixes: ["iPhone11,4", "iPhone11,6"]) { return "iPhone XS Max" }
        if id.matches(prefixes: ["iPhone11,8"])  { return "iPhone XR" }
        if id.matches(prefixes: ["iPhone12,1"])  { return "iPhone 11" }
        if id.matches(prefixes: ["iPhone12,3"])  { return "iPhone 11 Pro" }
        if id.matches(prefixes: ["iPhone12,5"])  { return "iPhone 11 Pro Max" }
        if id.matches(prefixes: ["iPhone12,8"])  { return "iPhone SE (2nd gen)" }
        if id.matches(prefixes: ["iPhone13,1"])  { return "iPhone 12 mini" }
        if id.matches(prefixes: ["iPhone13,2"])  { return "iPhone 12" }
        if id.matches(prefixes: ["iPhone13,3"])  { return "iPhone 12 Pro" }
        if id.matches(prefixes: ["iPhone13,4"])  { return "iPhone 12 Pro Max" }
        if id.matches(prefixes: ["iPhone14,4"])  { return "iPhone 13 mini" }
        if id.matches(prefixes: ["iPhone14,5"])  { return "iPhone 13" }
        if id.matches(prefixes: ["iPhone14,2"])  { return "iPhone 13 Pro" }
        if id.matches(prefixes: ["iPhone14,3"])  { return "iPhone 13 Pro Max" }
        if id.matches(prefixes: ["iPhone14,6"])  { return "iPhone SE (3rd gen)" }
        if id.matches(prefixes: ["iPhone14,7"])  { return "iPhone 14" }
        if id.matches(prefixes: ["iPhone14,8"])  { return "iPhone 14 Plus" }
        if id.matches(prefixes: ["iPhone15,2"])  { return "iPhone 14 Pro" }
        if id.matches(prefixes: ["iPhone15,3"])  { return "iPhone 14 Pro Max" }
        if id.matches(prefixes: ["iPhone15,4"])  { return "iPhone 15" }
        if id.matches(prefixes: ["iPhone15,5"])  { return "iPhone 15 Plus" }
        if id.matches(prefixes: ["iPhone16,1"])  { return "iPhone 15 Pro" }
        if id.matches(prefixes: ["iPhone16,2"])  { return "iPhone 15 Pro Max" }
        if id.matches(prefixes: ["iPhone17,1"])  { return "iPhone 16 Pro" }
        if id.matches(prefixes: ["iPhone17,2"])  { return "iPhone 16 Pro Max" }
        if id.matches(prefixes: ["iPhone17,3"])  { return "iPhone 16" }
        if id.matches(prefixes: ["iPhone17,4"])  { return "iPhone 16 Plus" }
        if id.matches(prefixes: ["iPad13,4", "iPad13,5", "iPad13,6", "iPad13,7"]) { return "iPad Pro 11-inch (3rd gen)" }
        if id.matches(prefixes: ["iPad13,8", "iPad13,9", "iPad13,10", "iPad13,11"]) { return "iPad Pro 12.9-inch (5th gen)" }
        if id.matches(prefixes: ["iPad13,16", "iPad13,17"]) { return "iPad Air (5th gen)" }
        if id.matches(prefixes: ["iPad14,3", "iPad14,4"]) { return "iPad Pro 11-inch (4th gen)" }
        if id.matches(prefixes: ["iPad14,5", "iPad14,6"]) { return "iPad Pro 12.9-inch (6th gen)" }
        if id.matches(prefixes: ["iPad14,8", "iPad14,9", "iPad14,10", "iPad14,11"]) { return "iPad Air (6th gen / M2)" }
        if id.matches(prefixes: ["iPad15,7", "iPad15,8"]) { return "iPad (A16)" }
        if id.matches(prefixes: ["iPad16,3", "iPad16,4"]) { return "iPad Pro 11-inch M4" }
        if id.matches(prefixes: ["iPad16,5", "iPad16,6"]) { return "iPad Pro 13-inch M4" }
        return id
    }

    static var chip: ChipGen {
        let id = modelIdentifier
        if id.matches(prefixes: ["iPhone7", "iPad5,1", "iPad5,2", "iPad5,3", "iPad5,4"]) { return .a8 }
        if id.matches(prefixes: ["iPhone8", "iPad6,3", "iPad6,4", "iPad6,7", "iPad6,8"]) { return .a9 }
        if id.matches(prefixes: ["iPhone9", "iPad6,11", "iPad6,12", "iPad7"]) { return .a10 }
        if id.matches(prefixes: ["iPhone10"]) { return .a11 }
        if id.matches(prefixes: ["iPhone11", "iPad8,1", "iPad8,2", "iPad8,3", "iPad8,4", "iPad8,5", "iPad8,6", "iPad8,7", "iPad8,8", "iPad11,1", "iPad11,2"]) { return .a12 }
        if id.matches(prefixes: ["iPhone12", "iPad11,6", "iPad11,7", "iPad12"]) { return .a13 }
        if id.matches(prefixes: ["iPhone13", "iPad13,1", "iPad13,2", "iPad13,18", "iPad13,19"]) { return .a14 }
        if id.matches(prefixes: ["iPhone14", "iPad14,1", "iPad14,2"]) { return .a15 }
        if id.matches(prefixes: ["iPhone15", "iPad15,7", "iPad15,8"]) { return .a16 }
        if id.matches(prefixes: ["iPhone16"]) { return .a17 }
        if id.matches(prefixes: ["iPhone17"]) { return .a18 }
        if id.matches(prefixes: ["iPad13,4", "iPad13,5", "iPad13,6", "iPad13,7", "iPad13,8", "iPad13,9", "iPad13,10", "iPad13,11", "iPad13,16", "iPad13,17"]) { return .m1 }
        if id.matches(prefixes: ["iPad14,3", "iPad14,4", "iPad14,5", "iPad14,6", "iPad14,8", "iPad14,9", "iPad14,10", "iPad14,11", "iPad15,3", "iPad15,4", "iPad15,5", "iPad15,6"]) { return .m2 }
        if id.matches(prefixes: ["iPad16"]) { return .m4 }
        return .unknown
    }

    static var jailbreakMethod: JBMethod {
        let v = versionTuple

        // Dopamine 2 supports iOS / iPadOS 15.0 through 16.6.1 on arm64e (A12-A16, M1, M2)
        let isSupportedVersion: Bool
        if v.major == 15 {
            isSupportedVersion = true
        } else if v.major == 16 {
            if v.minor < 6 {
                isSupportedVersion = true
            } else if v.minor == 6 && v.patch <= 1 {
                isSupportedVersion = true
            } else {
                isSupportedVersion = false
            }
        } else {
            isSupportedVersion = false
        }

        guard isSupportedVersion else { return .unsupported }

        switch chip {
        case .a12, .a13, .a14, .a15, .a16, .m1, .m2:
            return .dopamine2
        case .a8, .a9, .a10, .a11, .a17, .a18, .m4, .unknown:
            return .unsupported
        }
    }

    enum ChipGen: String {
        case a8, a9, a10, a11, a12, a13, a14, a15, a16, a17, a18
        case m1, m2, m4, unknown

        var display: String {
            switch self {
            case .a8:      return "A8"
            case .a9:      return "A9"
            case .a10:     return "A10"
            case .a11:     return "A11"
            case .a12:     return "A12"
            case .a13:     return "A13"
            case .a14:     return "A14"
            case .a15:     return "A15"
            case .a16:     return "A16"
            case .a17:     return "A17 Pro"
            case .a18:     return "A18"
            case .m1:      return "M1"
            case .m2:      return "M2"
            case .m4:      return "M4"
            case .unknown: return "Unknown"
            }
        }

        var isArm64e: Bool {
            switch self {
            case .a12, .a13, .a14, .a15, .a16, .a17, .a18, .m1, .m2, .m4:
                return true
            default:
                return false
            }
        }
    }

    enum JBMethod: String {
        case dopamine2   = "Dopamine 2"
        case unsupported = "Unsupported"

        var isSupported: Bool { self != .unsupported }

        var exploitLabel: String {
            switch self {
            case .dopamine2:   return "kfd / landa / weightBufs / XPF"
            case .unsupported: return "Not supported"
            }
        }

        var badge: Color {
            switch self {
            case .dopamine2:   return .purple
            case .unsupported: return .red
            }
        }
    }
}

private extension String {
    func matches(prefixes: [String]) -> Bool {
        prefixes.contains { hasPrefix($0) }
    }
}
