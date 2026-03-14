import SwiftUI

struct MySkyView: View {
    @EnvironmentObject var store: ExperimentStore
    @State private var selectedExperiment: Experiment?
    @State private var showNewExperiment = false
    @State private var positions: [UUID: CGPoint] = [:]
    @State private var appeared = false

    // Fixed orbital positions for up to 12 planets — feels natural, not grid-like
    private let orbitalSlots: [CGPoint] = {
        let w = UIScreen.main.bounds.width
        let h = UIScreen.main.bounds.height
        return [
            CGPoint(x: w * 0.28, y: h * 0.22),
            CGPoint(x: w * 0.68, y: h * 0.18),
            CGPoint(x: w * 0.50, y: h * 0.35),
            CGPoint(x: w * 0.18, y: h * 0.45),
            CGPoint(x: w * 0.78, y: h * 0.40),
            CGPoint(x: w * 0.35, y: h * 0.55),
            CGPoint(x: w * 0.65, y: h * 0.58),
            CGPoint(x: w * 0.15, y: h * 0.65),
            CGPoint(x: w * 0.82, y: h * 0.62),
            CGPoint(x: w * 0.45, y: h * 0.70),
            CGPoint(x: w * 0.25, y: h * 0.75),
            CGPoint(x: w * 0.70, y: h * 0.74),
        ]
    }()

    var body: some View {
        ZStack {
            SkyBackground()

            // Planets
            ForEach(Array(store.activeExperiments.enumerated()), id: \.element.id) { index, experiment in
                let slot = orbitalSlots[min(index, orbitalSlots.count - 1)]
                let planetSize: CGFloat = planetSizeFor(experiment)

                PlanetView(experiment: experiment, size: planetSize, showLabel: true)
                    .position(slot)
                    .opacity(appeared ? 1 : 0)
                    .scaleEffect(appeared ? 1 : 0.3)
                    .animation(
                        .spring(response: 0.7, dampingFraction: 0.6)
                        .delay(Double(index) * 0.08),
                        value: appeared
                    )
                    .onTapGesture {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) {
                            selectedExperiment = experiment
                        }
                    }
            }

            // Empty state
            if store.activeExperiments.isEmpty {
                VStack(spacing: 12) {
                    Text("Your sky is empty")
                        .font(.system(size: 22, weight: .light, design: .rounded))
                        .foregroundStyle(.white.opacity(0.6))
                    Text("Tap + to plant your first experiment")
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundStyle(.white.opacity(0.3))
                }
                .offset(y: -60)
            }

            // Header
            VStack {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("MY SKY")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .tracking(2.5)
                            .foregroundStyle(.white.opacity(0.35))
                        Text("\(store.activeExperiments.count) experiment\(store.activeExperiments.count == 1 ? "" : "s") orbiting")
                            .font(.system(size: 14, weight: .regular, design: .rounded))
                            .foregroundStyle(.white.opacity(0.55))
                    }
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 64)
                Spacer()
            }

            // Add button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button {
                        showNewExperiment = true
                    } label: {
                        ZStack {
                            Circle()
                                .fill(.white.opacity(0.1))
                                .frame(width: 56, height: 56)
                            Image(systemName: "plus")
                                .font(.system(size: 22, weight: .light))
                                .foregroundStyle(.white)
                        }
                    }
                    .padding(.trailing, 28)
                    .padding(.bottom, 110)
                }
            }
        }
        .ignoresSafeArea()
        .onAppear { appeared = true }
        .sheet(isPresented: $showNewExperiment) {
            NewExperimentView()
                .environmentObject(store)
        }
        .sheet(item: $selectedExperiment) { experiment in
            PlanetDetailView(experiment: experiment)
                .environmentObject(store)
        }
    }

    private func planetSizeFor(_ experiment: Experiment) -> CGFloat {
        // Older / more tended experiments feel slightly larger
        let base: CGFloat = 44
        let bonus = min(CGFloat(experiment.currentStreakDays) * 1.5, 20)
        return base + bonus
    }
}
