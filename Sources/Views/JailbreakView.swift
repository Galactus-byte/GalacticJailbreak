import SwiftUI
import Darwin

struct JailbreakView: View {

    let packageManager: PackageManager
    @Binding var appPhase: ContentView.Phase

    @StateObject private var engine = JailbreakEngine()
    @State private var started = false

    var body: some View {
        VStack(spacing: 20) {
            MethodBadgeView()

            ProgressRing(
                progress: engine.progress,
                status: engine.status,
                pm: packageManager
            )

            Text(engine.status.label)
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundColor(.cyan)
                .animation(.easeInOut(duration: 0.3), value: engine.status.label)

            LogConsole(entries: engine.log)
                .frame(height: 150)

            controls
        }
    }

    @ViewBuilder
    private var controls: some View {
        switch engine.status {
        case .complete:
            GlowButton(title: "RESPRING SPRINGBOARD", isEnabled: true, color: .green) {
                respring()
            }

        case .failed:
            GlowButton(title: "RETRY", isEnabled: true, color: .red) {
                engine.cancel()
                started = false
                begin()
            }

        default:
            if !started {
                GlowButton(title: "BEGIN", isEnabled: true, color: .cyan) { begin() }
            } else {
                HStack(spacing: 8) {
                    ProgressView().tint(.cyan).scaleEffect(0.75)
                    Text("RUNNING — KEEP SCREEN ON")
                        .font(.system(size: 9, weight: .black, design: .monospaced))
                        .kerning(2)
                        .foregroundColor(.cyan.opacity(0.6))
                }
            }
        }
    }

    private func begin() {
        started = true
        engine.run(packageManager: packageManager)
    }

    // Process() is macOS-only. On iOS jailbroken devices use posix_spawn
    // to call sbreload from the rootless bootstrap at /var/jb.
    private func respring() {
        let path = "/var/jb/usr/bin/sbreload"
        var pid: pid_t = 0
        let args: [UnsafeMutablePointer<CChar>?] = [
            strdup(path),
            nil
        ]
        posix_spawn(&pid, path, nil, nil, args, nil)
        args.forEach { free($0) }
    }
}

// MARK: - Progress Ring

struct ProgressRing: View {

    let progress: Double
    let status: JailbreakEngine.Status
    let pm: PackageManager

    @State private var spin: Double = 0

    var body: some View {
        ZStack {
            Circle()
                .strokeBorder(Color.white.opacity(0.04), lineWidth: 1)
                .frame(width: 168, height: 168)

            Circle()
                .strokeBorder(Color.white.opacity(0.07), lineWidth: 10)
                .frame(width: 134, height: 134)

            Circle()
                .trim(from: 0, to: CGFloat(progress))
                .stroke(
                    AngularGradient(
                        colors: [.purple, .blue, .cyan, .purple],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 10, lineCap: .round)
                )
                .frame(width: 134, height: 134)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.5), value: progress)
                .shadow(color: .cyan.opacity(0.55), radius: 8)

            if status.isActive {
                Circle()
                    .trim(from: 0.82, to: 1.0)
                    .stroke(Color.cyan.opacity(0.55),
                            style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: 152, height: 152)
                    .rotationEffect(.degrees(spin))
                    .onAppear {
                        withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
                            spin = 360
                        }
                    }
            }

            centerContent
        }
    }

    @ViewBuilder
    private var centerContent: some View {
        switch status {
        case .complete:
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 38))
                .foregroundColor(.green)
                .transition(.scale.combined(with: .opacity))

        case .failed:
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 38))
                .foregroundColor(.red)

        default:
            VStack(spacing: 3) {
                Text("\(Int(progress * 100))%")
                    .font(.system(size: 26, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                Text(pm.rawValue)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(pm.accentColor)
            }
        }
    }
}

// MARK: - Log Console

struct LogConsole: View {

    let entries: [JailbreakEngine.LogEntry]

    private static let timeFmt: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "HH:mm:ss"; return f
    }()

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: 3) {
                    ForEach(entries) { e in
                        HStack(alignment: .top, spacing: 6) {
                            Text(Self.timeFmt.string(from: e.timestamp))
                                .frame(width: 56, alignment: .leading)
                                .foregroundColor(.white.opacity(0.25))
                            Text(">")
                                .foregroundColor(levelColor(e.level).opacity(0.6))
                            Text(e.message)
                                .foregroundColor(levelColor(e.level))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .font(.system(size: 9.5, design: .monospaced))
                        .id(e.id)
                    }
                }
                .padding(12)
            }
            .background(
                RoundedRectangle(cornerRadius: 13)
                    .fill(Color.black.opacity(0.52))
                    .overlay(
                        RoundedRectangle(cornerRadius: 13)
                            .strokeBorder(Color.cyan.opacity(0.18), lineWidth: 1)
                    )
            )
            .onChange(of: entries.count) { _ in
                guard let last = entries.last else { return }
                withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
            }
        }
    }

    private func levelColor(_ l: JailbreakEngine.LogEntry.Level) -> Color {
        switch l {
        case .info:    return .white.opacity(0.65)
        case .success: return .green
        case .warning: return .yellow
        case .error:   return .red
        }
    }
}

// MARK: - Method Badge

struct MethodBadgeView: View {

    private var method: DeviceInfo.JBMethod { DeviceInfo.jailbreakMethod }

    var body: some View {
        HStack(spacing: 8) {
            Circle().fill(method.badge).frame(width: 6, height: 6)
            Text(method.rawValue.uppercased())
                .font(.system(size: 9, weight: .black, design: .monospaced))
                .foregroundColor(method.badge)
                .kerning(2)
            dot
            Text(method.exploitLabel)
                .font(.system(size: 9, design: .monospaced))
                .foregroundColor(.white.opacity(0.45))
            dot
            Text("iOS \(DeviceInfo.iOSVersion)")
                .font(.system(size: 9, design: .monospaced))
                .foregroundColor(.white.opacity(0.45))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 7)
        .background(
            Capsule()
                .fill(method.badge.opacity(0.10))
                .overlay(Capsule().strokeBorder(method.badge.opacity(0.28), lineWidth: 1))
        )
    }

    private var dot: some View {
        Text("·").foregroundColor(.white.opacity(0.2)).font(.system(size: 9))
    }
}
