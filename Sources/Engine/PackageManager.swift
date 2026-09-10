import Foundation
import SwiftUI

enum PackageManager: String, CaseIterable, Identifiable {
    case sileo = "Sileo"
    case zebra = "Zebra"

    var id: String { rawValue }

    var tagline: String {
        switch self {
        case .sileo: return "Modern · Swift-native · Official Dopamine & palera1n PM"
        case .zebra: return "Lightweight APT · Fast & stable · High customization"
        }
    }

    var icon: String {
        switch self {
        case .sileo: return "cube.fill"
        case .zebra: return "shield.lefthalf.filled"
        }
    }

    var accentColor: Color {
        switch self {
        case .sileo: return .blue
        case .zebra: return .orange
        }
    }

    var bundleID: String {
        switch self {
        case .sileo: return "org.coolstar.SileoStore"
        case .zebra: return "xyz.willy.Zebra"
        }
    }

    var debFileName: String {
        switch self {
        case .sileo: return "sileo.deb"
        case .zebra: return "zebra.deb"
        }
    }
}
