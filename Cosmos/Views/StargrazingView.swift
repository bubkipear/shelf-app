import SwiftUI

struct StargrazingView: View {
    @EnvironmentObject var store: ExperimentStore
    @State private var sortMode: SortMode = .active
    @State private var orbitingIds: Set<UUID> = []
    @State private var selectedExperiment: Experiment?

    enum SortMode: String, CaseIterable {
        case newest = "Newest"
        case active = "Most active"
        case popular = "Most orbited"
    }

    var sorted: [Experiment] {
        switch sortMode {
        case .newest:  return store.communityExperiments.sorted { $0.startDate > $1.startDate }
        case .active:  return store.communityExperiments.sorted { $0.totalCheckIns > $1.totalCheckIns }
        case .popular: return store.communityExperiments.sorted { $0.daysSinceStart > $1.daysSinceStart }
        }
    }

    var body: some View {
        ZStack {
            SkyBackground()

            VStack(spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("STARGAZING")
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                .tracking(2.5)
                                .foregroundStyle(.white.opacity(0.35))
                            Text("The collective sky")
                                .font(.system(size: 20, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 64)
                    .padding(.bottom, 16)

                    // Sort pills
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(SortMode.allCases, id: \.self) { mode in
                                let selected = sortMode == mode
                                Button {
                                    withAnimation(.spring(response: 0.35)) { sortMode = mode }
                                } label: {
                                    Text(mode.rawValue)
                                        .font(.system(size: 13, weight: selected ? .semibold : .regular, design: .rounded))
                                        .foregroundStyle(selected ? .black : .white.opacity(0.5))
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 8)
                                        .background(selected ? Color.white : Color.white.opacity(0.08))
                                        .clipShape(Capsule())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                    .padding(.bottom, 8)
                }

                // Feed
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 12) {
                        ForEach(sorted) { experiment in
                            CommunityCard(
                                experiment: experiment,
                                isOrbiting: orbitingIds.contains(experiment.id)
                            ) {
                                orbit(experiment)
                            }
                            .onTapGesture { selectedExperiment = experiment }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 110)
                }
            }
        }
        .ignoresSafeArea()
        .sheet(item: $selectedExperiment) { experiment in
            CommunityExperimentView(experiment: experiment, isOrbiting: orbitingIds.contains(experiment.id)) {
                orbit(experiment)
            }
        }
    }

    private func orbit(_ experiment: Experiment) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
            if orbitingIds.contains(experiment.id) {
                orbitingIds.remove(experiment.id)
            } else {
                orbitingIds.insert(experiment.id)
                store.orbitCommunityExperiment(experiment)
            }
        }
    }
}

// MARK: - Community Card

struct CommunityCard: View {
    let experiment: Experiment
    let isOrbiting: Bool
    let onOrbit: () -> Void

    private var palette: PlanetPalette { PlanetPalette.palette(for: experiment.planetAsset) }

    var body: some View {
        HStack(spacing: 14) {
            PlanetView(experiment: experiment, size: 52)
                .frame(width: 64, height: 64)

            VStack(alignment: .leading, spacing: 5) {
                Text(experiment.name)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)

                if let intention = experiment.intention {
                    Text(intention)
                        .font(.system(size: 13, design: .rounded))
                        .foregroundStyle(.white.opacity(0.4))
                        .lineLimit(2)
                }

                HStack(spacing: 10) {
                    Label("\(experiment.totalCheckIns + Int.random(in: 3...40)) orbiting", systemImage: "person.2")
                        .font(.system(size: 11, design: .rounded))
                        .foregroundStyle(.white.opacity(0.3))

                    Text("·")
                        .foregroundStyle(.white.opacity(0.2))

                    Text("\(experiment.daysSinceStart)d running")
                        .font(.system(size: 11, design: .rounded))
                        .foregroundStyle(.white.opacity(0.3))
                }
            }

            Spacer()

            // Orbit button
            Button(action: onOrbit) {
                Image(systemName: isOrbiting ? "checkmark" : "plus")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(isOrbiting ? palette.glow : .white.opacity(0.6))
                    .frame(width: 34, height: 34)
                    .background(isOrbiting ? palette.glow.opacity(0.15) : Color.white.opacity(0.08))
                    .clipShape(Circle())
                    .overlay(
                        Circle().stroke(isOrbiting ? palette.glow.opacity(0.4) : Color.clear, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.white.opacity(0.07), lineWidth: 1)
        )
    }
}

// MARK: - Community Experiment Detail

struct CommunityExperimentView: View {
    let experiment: Experiment
    let isOrbiting: Bool
    let onOrbit: () -> Void
    @Environment(\.dismiss) var dismiss

    private var palette: PlanetPalette { PlanetPalette.palette(for: experiment.planetAsset) }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            palette.primary.opacity(0.05).ignoresSafeArea()

            VStack(spacing: 0) {
                Capsule()
                    .fill(.white.opacity(0.2))
                    .frame(width: 36, height: 4)
                    .padding(.top, 12)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        ZStack {
                            Circle()
                                .fill(palette.glow.opacity(0.1))
                                .frame(width: 220, height: 220)
                                .blur(radius: 50)
                            PlanetView(experiment: experiment, size: 110)
                        }
                        .frame(height: 200)

                        VStack(spacing: 12) {
                            Text(experiment.name)
                                .font(.system(size: 26, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white)
                                .multilineTextAlignment(.center)

                            if let intention = experiment.intention {
                                Text(intention)
                                    .font(.system(size: 15, design: .rounded))
                                    .foregroundStyle(.white.opacity(0.45))
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 32)
                            }

                            HStack(spacing: 16) {
                                Label("\(experiment.totalCheckIns + Int.random(in: 3...40)) orbiting", systemImage: "person.2")
                                Text("·")
                                Text("\(experiment.daysSinceStart)d running")
                            }
                            .font(.system(size: 13, design: .rounded))
                            .foregroundStyle(.white.opacity(0.35))
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 36)

                        // Orbit CTA
                        Button(action: {
                            onOrbit()
                            dismiss()
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: isOrbiting ? "checkmark.circle" : "plus.circle")
                                Text(isOrbiting ? "Orbiting" : "Add to my sky")
                                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                            }
                            .foregroundStyle(isOrbiting ? .black : .black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 17)
                            .background(isOrbiting ? palette.primary.opacity(0.8) : Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        .padding(.horizontal, 24)
                        .disabled(isOrbiting)
                    }
                }
            }
        }
    }
}
