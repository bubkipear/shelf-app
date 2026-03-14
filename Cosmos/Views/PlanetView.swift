import SwiftUI

// MARK: - Animated planet orb (placeholder until real GIF assets land)

struct PlanetView: View {
    let experiment: Experiment
    let size: CGFloat
    var showLabel: Bool = false

    @State private var rotationAngle: Double = 0
    @State private var pulseScale: CGFloat = 1.0
    @State private var glowOpacity: Double = 0.6

    private var palette: PlanetPalette { PlanetPalette.palette(for: experiment.planetAsset) }
    private var brightness: Double { experiment.brightness }
    private var isTended: Bool { experiment.planetState == .tended }

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                // Outer glow halo
                if isTended {
                    Circle()
                        .fill(palette.glow.opacity(0.18 * glowOpacity))
                        .frame(width: size * 1.9, height: size * 1.9)
                        .blur(radius: size * 0.3)
                        .scaleEffect(pulseScale)
                }

                // Ring (if this planet has one)
                if let ringColor = palette.ring {
                    Ellipse()
                        .stroke(ringColor.opacity(0.55 * brightness), lineWidth: size * 0.05)
                        .frame(width: size * 1.55, height: size * 0.38)
                        .rotation3DEffect(.degrees(rotationAngle * 0.1), axis: (x: 0, y: 1, z: 0))
                        .opacity(brightness)
                }

                // Planet body
                ZStack {
                    // Base sphere
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    palette.primary.opacity(brightness),
                                    palette.primary.opacity(brightness * 0.6),
                                    Color.black.opacity(0.8)
                                ],
                                center: UnitPoint(x: 0.35, y: 0.3),
                                startRadius: 0,
                                endRadius: size * 0.6
                            )
                        )
                        .frame(width: size, height: size)

                    // Surface band detail
                    Ellipse()
                        .fill(
                            LinearGradient(
                                colors: [palette.glow.opacity(0.08 * brightness), .clear],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: size * 0.85, height: size * 0.22)
                        .offset(y: size * 0.08)
                        .blur(radius: 3)
                        .rotation3DEffect(.degrees(rotationAngle * 0.3), axis: (x: 0, y: 1, z: 0))

                    // Atmosphere rim
                    Circle()
                        .stroke(
                            RadialGradient(
                                colors: [.clear, palette.glow.opacity(0.5 * brightness)],
                                center: .center,
                                startRadius: size * 0.3,
                                endRadius: size * 0.55
                            ),
                            lineWidth: size * 0.08
                        )
                        .frame(width: size, height: size)
                }
            }

            if showLabel {
                Text(experiment.name)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.65))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: size * 1.8)
            }
        }
        .onAppear { startAnimations() }
    }

    private func startAnimations() {
        // Slow spin
        withAnimation(.linear(duration: 12).repeatForever(autoreverses: false)) {
            rotationAngle = 360
        }
        // Gentle pulse (only for tended planets)
        if isTended {
            withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) {
                pulseScale = 1.12
                glowOpacity = 1.0
            }
        }
    }
}
