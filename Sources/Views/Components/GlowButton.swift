import SwiftUI

struct GlowButtonStyle: ButtonStyle {
    let isEnabled: Bool
    let color: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 11, weight: .black, design: .monospaced))
            .tracking(3.5)
            .foregroundColor(isEnabled ? .white : .white.opacity(0.25))
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(
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
            )
            .shadow(
                color: isEnabled ? color.opacity(configuration.isPressed ? 0.25 : 0.45) : .clear,
                radius: configuration.isPressed ? 6 : 18
            )
            .scaleEffect(configuration.isPressed && isEnabled ? 0.965 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

struct GlowButton: View {

    let title: String
    let isEnabled: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
        }
        .buttonStyle(GlowButtonStyle(isEnabled: isEnabled, color: color))
        .disabled(!isEnabled)
    }
}
