import SwiftUI

struct ContentView: View {

    enum Phase { case selection, jailbreaking }

    @State private var selectedPM: PackageManager? = nil
    @State private var phase: Phase = .selection

    var body: some View {
        ZStack {
            GalacticBackgroundView()
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {
                    header
                        .padding(.top, 52)

                    if phase == .selection {
                        PackageManagerView(selected: $selectedPM) {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                phase = .jailbreaking
                            }
                        }
                        .transition(.asymmetric(
                            insertion: .move(edge: .leading).combined(with: .opacity),
                            removal:   .move(edge: .leading).combined(with: .opacity)
                        ))
                    } else {
                        JailbreakView(
                            packageManager: selectedPM ?? .sileo,
                            appPhase: $phase
                        )
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal:   .move(edge: .trailing).combined(with: .opacity)
                        ))
                    }

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 6) {
            Text("G A L A C T I C")
                .font(.system(size: 10, weight: .black, design: .monospaced))
                .kerning(6)
                .foregroundStyle(
                    LinearGradient(
                        colors: [.cyan, .purple],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )

            Text("Jailbreak")
                .font(.system(size: 44, weight: .heavy, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.purple, .blue, .cyan],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .shadow(color: .purple.opacity(0.7), radius: 22)

            deviceBadge

            // Phase step indicator
            HStack(spacing: 6) {
                stepDot(active: phase == .selection,  done: phase == .jailbreaking, label: "1")
                Rectangle()
                    .fill(phase == .jailbreaking ? Color.cyan.opacity(0.6) : Color.white.opacity(0.12))
                    .frame(width: 28, height: 1)
                stepDot(active: phase == .jailbreaking, done: false, label: "2")
            }
            .padding(.top, 6)
        }
    }

    private var deviceBadge: some View {
        HStack(spacing: 5) {
            Image(systemName: "iphone")
                .font(.system(size: 10))
            Text("\(DeviceInfo.modelIdentifier)  ·  iOS \(DeviceInfo.iOSVersion)  ·  \(DeviceInfo.chip.display)")
                .font(.system(size: 10, design: .monospaced))
        }
        .foregroundColor(.white.opacity(0.38))
    }

    private func stepDot(active: Bool, done: Bool, label: String) -> some View {
        ZStack {
            Circle()
                .fill(active ? Color.cyan.opacity(0.25) : (done ? Color.green.opacity(0.25) : Color.white.opacity(0.06)))
                .frame(width: 22, height: 22)
            Circle()
                .strokeBorder(active ? .cyan : (done ? .green : Color.white.opacity(0.15)), lineWidth: 1.2)
                .frame(width: 22, height: 22)
            Text(label)
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundColor(active ? .cyan : (done ? .green : .white.opacity(0.3)))
        }
    }
}
