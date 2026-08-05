import SwiftUI

struct GalacticBackgroundView: View {

    private let stars: [Star] = Star.generate(count: 220)

    var body: some View {
        ZStack {
            // Base — deep void
            Color(red: 0.015, green: 0.015, blue: 0.06)
                .ignoresSafeArea()

            // Animated star canvas
            TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { tl in
                Canvas { ctx, size in
                    let t = tl.date.timeIntervalSinceReferenceDate
                    for star in stars {
                        let twinkle = 0.45 + 0.55 * sin(t * star.speed + star.phase)
                        let alpha   = star.alpha * twinkle
                        let x = star.nx * size.width
                        let y = star.ny * size.height
                        let r = star.radius

                        // Core
                        ctx.fill(
                            Path(ellipseIn: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)),
                            with: .color(star.color.opacity(alpha))
                        )

                        // Halo on brighter stars
                        if r > 1.4 {
                            ctx.fill(
                                Path(ellipseIn: CGRect(x: x - r * 4, y: y - r * 4,
                                                       width: r * 8, height: r * 8)),
                                with: .color(star.color.opacity(alpha * 0.12))
                            )
                        }
                    }
                }
                .ignoresSafeArea()
            }

            // Nebula overlays
            nebulae
        }
    }

    private var nebulae: some View {
        ZStack {
            // Purple cloud — top-left quadrant
            RadialGradient(
                colors: [Color.purple.opacity(0.28), Color.indigo.opacity(0.10), .clear],
                center: .init(x: 0.12, y: 0.18),
                startRadius: 0,
                endRadius: 280
            )

            // Blue-cyan — bottom-right quadrant
            RadialGradient(
                colors: [Color.blue.opacity(0.22), Color.cyan.opacity(0.10), .clear],
                center: .init(x: 0.88, y: 0.78),
                startRadius: 0,
                endRadius: 320
            )

            // Magenta accent — mid-screen
            RadialGradient(
                colors: [Color.pink.opacity(0.10), .clear],
                center: .init(x: 0.55, y: 0.42),
                startRadius: 0,
                endRadius: 180
            )
        }
        .ignoresSafeArea()
    }

    // MARK: - Star Model

    struct Star {
        let nx: CGFloat      // normalized x [0,1]
        let ny: CGFloat      // normalized y [0,1]
        let radius: CGFloat
        let alpha: Double
        let speed: Double    // twinkle frequency
        let phase: Double
        let color: Color

        static func generate(count: Int) -> [Star] {
            let palette: [Color] = [
                .white,
                .cyan,
                .blue,
                Color(red: 0.85, green: 0.85, blue: 1.0),
                Color(red: 0.9,  green: 0.7,  blue: 1.0),
            ]
            return (0..<count).map { _ in
                Star(
                    nx:     .random(in: 0...1),
                    ny:     .random(in: 0...1),
                    radius: .random(in: 0.4...2.6),
                    alpha:  .random(in: 0.35...1.0),
                    speed:  .random(in: 0.4...2.2),
                    phase:  .random(in: 0...(Double.pi * 2)),
                    color:  palette.randomElement()!
                )
            }
        }
    }
}
