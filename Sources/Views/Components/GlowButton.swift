import SwiftUI

struct GlowButton: View {

    let title: String
    let isEnabled: Bool
    let color: Color
    let action: () -> Void

    @State private var pressing = false

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 11, weight: .black, design: .monospaced))
                .kerning(3.5)
                .foregroundColor(isEnabled ? .white : .white.opacity(0.25))
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(buttonBG)
                .shadow(color: isEnabled ? color.opacity(pressing ? 0.25 : 0.45) : .clear,
                        radius: pressing ? 6 : 18)
                .scaleEffect(pressing ? 0.965 : 1.0)
        }
        .disabled(!isEnabled)
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in pressing = true  }
                .onEnded   { _ in pressing = false }
        )
        .animation(.spring(response: 0.2, dampingFraction: 0.7), value: pressing)
    }

    private var buttonBG: some View {
        ZStack {
            if isEnabled {
                RoundedRectangle(cornerRadius: 15)
                    .fill(LinearGradient(
                        colors: [color.opacity(0.35), color.opacity(0.18)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                RoundedRectangle(cornerRadius: 15)
                    .strokeBorder(
                        LinearGradient(
                            colors: [color.opacity(0.9), color.opacity(0.4)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            } else {
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.white.opacity(0.04))
                RoundedRectangle(cornerRadius: 15)
                    .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
            }
        }
    }
}
