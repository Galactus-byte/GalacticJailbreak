import SwiftUI

struct PackageManagerView: View {

    @Binding var selected: PackageManager?
    let onConfirm: () -> Void

    var body: some View {
        VStack(spacing: 22) {
            sectionHeader

            VStack(spacing: 10) {
                ForEach(PackageManager.allCases) { pm in
                    PMCard(pm: pm, isSelected: selected == pm) {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.72)) {
                            selected = pm
                        }
                    }
                }
            }

            GlowButton(
                title: "INITIALIZE JAILBREAK",
                isEnabled: selected != nil,
                color: .cyan,
                action: onConfirm
            )
            .padding(.top, 4)
        }
    }

    private var sectionHeader: some View {
        VStack(spacing: 6) {
            Text("PACKAGE MANAGER")
                .font(.system(size: 10, weight: .black, design: .monospaced))
                .kerning(5)
                .foregroundColor(.cyan.opacity(0.7))

            Text("Installed before the jailbreak activates")
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.35))
        }
    }
}

// MARK: - Card

struct PMCard: View {

    let pm: PackageManager
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                iconView
                textBlock
                Spacer()
                radioIndicator
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(cardBG)
            .shadow(color: isSelected ? pm.accentColor.opacity(0.28) : .clear, radius: 14)
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.28), value: isSelected)
    }

    private var iconView: some View {
        ZStack {
            Circle()
                .fill(pm.accentColor.opacity(isSelected ? 0.28 : 0.10))
                .frame(width: 46, height: 46)

            Image(systemName: pm.icon)
                .font(.system(size: 19, weight: .semibold))
                .foregroundColor(pm.accentColor)
        }
    }

    private var textBlock: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(pm.rawValue)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.white)
            Text(pm.tagline)
                .font(.system(size: 10))
                .foregroundColor(.white.opacity(0.50))
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var radioIndicator: some View {
        ZStack {
            Circle()
                .strokeBorder(
                    isSelected ? pm.accentColor : Color.white.opacity(0.25),
                    lineWidth: 1.8
                )
                .frame(width: 22, height: 22)

            if isSelected {
                Circle()
                    .fill(pm.accentColor)
                    .frame(width: 12, height: 12)
                    .transition(.scale)
            }
        }
        .animation(.spring(response: 0.2), value: isSelected)
    }

    private var cardBG: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color.white.opacity(isSelected ? 0.09 : 0.04))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(
                        isSelected
                            ? LinearGradient(
                                colors: [pm.accentColor.opacity(0.8), pm.accentColor.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                              )
                            : LinearGradient(
                                colors: [Color.white.opacity(0.10), Color.white.opacity(0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                              ),
                        lineWidth: isSelected ? 1.5 : 1
                    )
            )
    }
}
