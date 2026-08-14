import SwiftUI

struct ContentView: View {

    enum Phase { case selection, jailbreaking }

    @State private var selectedPM: PackageManager? = nil
    @State private var phase: Phase = .selection

    private var isSupported: Bool {
        DeviceInfo.jailbreakMethod.isSupported
    }

    var body: some View {
        ZStack {
            GalacticBackgroundView()
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {
                    header
                        .padding(.top, 52)

                    if !isSupported {
                        unsupportedView
                    } else if phase == .selection {
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

    // MARK: - Unsupported View

    private var unsupportedView: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color.red.opacity(0.15))
                    .frame(width: 80, height: 80)
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 44))
                    .foregroundColor(.red)
            }

            VStack(spacing: 10) {
                Text("Device Not Supported")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)

                Text("Your device is not supported. Dopamine requires iOS 15.0–16.7.x on A12–A16 chips.")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // Device info card
            VStack(spacing: 8) {
                infoRow(label: "Device", value: DeviceInfo.modelIdentifier)
                infoRow(label: "iOS", value: DeviceInfo.iOSVersion)
                infoRow(label: "Chip", value: DeviceInfo.chip.display)
                infoRow(label: "Status", value: "Unsupported")
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(Color.red.opacity(0.3), lineWidth: 1)
                    )
            )

            // Supported devices info
            VStack(spacing: 6) {
                Text("SUPPORTED DEVICES")
                    .font(.system(size: 9, weight: .black, design: .monospaced))
                    .kerning(3)
                    .foregroundColor(.white.opacity(0.3))

                Text("iPhone XS / XR / 11 / 12 / 13 / 14 Pro\niOS 15.0 – 16.7.x only")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.4))
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 4)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(Color.red.opacity(0.2), lineWidth: 1)
                )
        )
    }

    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(.white.opacity(0.4))
            Spacer()
            Text(value)
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundColor(.white.opacity(0.7))
        }
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

            if isSupported {
                HStack(spacing: 6) {
                    stepDot(active: phase == .selection, done: phase == .jailbreaking, label: "1")
                    Rectangle()
                        .fill(phase == .jailbreaking ? Color.cyan.opacity(0.6) : Color.white.opacity(0.12))
                        .frame(width: 28, height: 1)
                    stepDot(active: phase == .jailbreaking, done: false, label: "2")
                }
                .padding(.top, 6)
            }
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
