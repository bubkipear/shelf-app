import SwiftUI

// MARK: - Star field rendered once as a background layer

struct SkyBackground: View {
    @State private var twinklePhase: Double = 0

    private let stars: [(CGPoint, Double, Double)] = {
        var s: [(CGPoint, Double, Double)] = []
        var rng = SeededRNG(seed: 42)
        for _ in 0..<180 {
            let x = rng.next() * UIScreen.main.bounds.width
            let y = rng.next() * UIScreen.main.bounds.height
            let size = rng.next() * 1.8 + 0.3
            let phase = rng.next() * .pi * 2
            s.append((CGPoint(x: x, y: y), size, phase))
        }
        return s
    }()

    var body: some View {
        TimelineView(.animation(minimumInterval: 0.05)) { context in
            Canvas { ctx, size in
                let t = context.date.timeIntervalSinceReferenceDate

                // Deep space gradient
                let bg = ctx.resolve(
                    Image(systemName: "square.fill")
                        .resizable()
                        .foregroundStyle(Color.black)
                )
                ctx.fill(Path(CGRect(origin: .zero, size: size)), with: .color(.black))

                // Subtle nebula smear
                let nebulaCentre = CGPoint(x: size.width * 0.6, y: size.height * 0.3)
                ctx.drawLayer { sub in
                    sub.opacity = 0.07
                    sub.fill(
                        Path(ellipseIn: CGRect(x: nebulaCentre.x - 180, y: nebulaCentre.y - 120, width: 360, height: 240)),
                        with: .color(Color(red: 0.3, green: 0.2, blue: 0.7))
                    )
                }
                let nebula2 = CGPoint(x: size.width * 0.2, y: size.height * 0.65)
                ctx.drawLayer { sub in
                    sub.opacity = 0.05
                    sub.fill(
                        Path(ellipseIn: CGRect(x: nebula2.x - 140, y: nebula2.y - 90, width: 280, height: 180)),
                        with: .color(Color(red: 0.1, green: 0.3, blue: 0.5))
                    )
                }

                // Stars
                for (pt, size_, phase) in stars {
                    let alpha = 0.4 + 0.4 * sin(t * 0.8 + phase)
                    ctx.fill(
                        Path(ellipseIn: CGRect(x: pt.x - size_ / 2, y: pt.y - size_ / 2, width: size_, height: size_)),
                        with: .color(Color.white.opacity(alpha))
                    )
                }
            }
        }
        .ignoresSafeArea()
    }
}

// Deterministic RNG for stable star layout
struct SeededRNG {
    var state: UInt64

    init(seed: UInt64) { state = seed }

    mutating func next() -> Double {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        let value = Double(state >> 33) / Double(1 << 31)
        return value
    }
}
