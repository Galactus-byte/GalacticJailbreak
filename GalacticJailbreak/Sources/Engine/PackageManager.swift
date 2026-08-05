import Foundation
import SwiftUI

enum PackageManager: String, CaseIterable, Identifiable {
    case sileo    = "Sileo"
    case zebra    = "Zebra"
    case cydia    = "Cydia"
    case installer = "Installer 5"

    var id: String { rawValue }

    var tagline: String {
        switch self {
        case .sileo:     return "Modern · Native Swift · Default for Dopamine & palera1n"
        case .zebra:     return "Lightweight APT · Fast · Great for older hardware"
        case .cydia:     return "Classic · Legacy repo support · Battle-tested"
        case .installer: return "Minimalist · IPA-native · Clean UI"
        }
    }

    var icon: String {
        switch self {
        case .sileo:     return "cube.fill"
        case .zebra:     return "shield.lefthalf.filled"
        case .cydia:     return "archivebox.fill"
        case .installer: return "arrow.down.app.fill"
        }
    }

    var accentColor: Color {
        switch self {
        case .sileo:     return .blue
        case .zebra:     return .orange
        case .cydia:     return .purple
        case .installer: return .cyan
        }
    }

    var bundleID: String {
        switch self {
        case .sileo:     return "org.coolstar.SileoStore"
        case .zebra:     return "xyz.willy.Zebra"
        case .cydia:     return "com.saurik.Cydia"
        case .installer: return "com.sparkling-juice.Installer5"
        }
    }

    var debURL: URL {
        switch self {
        case .sileo:
            return URL(string: "https://github.com/Sileo/Sileo/releases/latest/download/sileo.deb")!
        case .zebra:
            return URL(string: "https://getzbra.com/repo/debians/xyz.willy.Zebra_latest.deb")!
        case .cydia:
            return URL(string: "https://cydia.saurik.com/api/deb/cydia/i386/1.1.32_iphoneos-arm")!
        case .installer:
            return URL(string: "https://installer.io/pkg/latest/installer5.deb")!
        }
    }
}
