import SwiftUI

struct BrowseView: View {
    @EnvironmentObject var store: SupabaseExperimentStore
    @State private var sortMode: SortMode = .active
    @State private var orbitingIds: Set<UUID> = []
    @State private var selectedExperiment: Experiment?

    private let cream    = Color(red: 0.98, green: 0.96, blue: 0.93)
    private let graphite = Color(red: 0.25, green: 0.23, blue: 0.22)

    enum SortMode: String, CaseIterable {
        case newest = "Newest"
        case active = "Most active"
        case popular = "Most tried"
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
            cream.ignoresSafeArea()
            VStack(spacing: 0) {

                // Header
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("BROWSE")
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                .tracking(2.5).foregroundStyle(graphite.opacity(0.35))
                            Text("Other people's shelves")
                                .font(.system(size: 20, weight: .semibold, design: .rounded))
                                .foregroundStyle(graphite)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 24).padding(.top, 64).padding(.bottom, 16)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(SortMode.allCases, id: \.self) { mode in
                                let sel = sortMode == mode
                                Button { withAnimation(.spring(response: 0.35)) { sortMode = mode } } label: {
                                    Text(mode.rawValue)
                                        .font(.system(size: 12, weight: sel ? .semibold : .regular, design: .rounded))
                                        .foregroundStyle(sel ? cream : graphite.opacity(0.5))
                                        .padding(.horizontal, 14).padding(.vertical, 8)
                                        .background(sel ? graphite : graphite.opacity(0.07))
                                        .clipShape(Capsule())
                                }.buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                    .padding(.bottom, 8)
                }

                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 10) {
                        ForEach(sorted) { experiment in
                            BrowseCard(
                                experiment: experiment,
                                isTrying: orbitingIds.contains(experiment.id),
                                graphite: graphite, cream: cream
                            ) { orbit(experiment) }
                            .onTapGesture { selectedExperiment = experiment }
                        }
                    }
                    .padding(.horizontal, 16).padding(.top, 16).padding(.bottom, 110)
                }
            }
        }
        .ignoresSafeArea()
        .sheet(item: $selectedExperiment) { experiment in
            BrowseDetailView(
                experiment: experiment,
                isTrying: orbitingIds.contains(experiment.id),
                graphite: graphite, cream: cream
            ) { orbit(experiment) }
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

// MARK: - Browse Card

struct BrowseCard: View {
    let experiment: Experiment
    let isTrying: Bool
    let graphite: Color
    let cream: Color
    let onTry: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            // Icon swatch
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(graphite.opacity(0.06))
                    .frame(width: 52, height: 52)
                Image(systemName: experiment.iconPreset.rawValue)
                    .font(.system(size: 22, weight: .thin))
                    .foregroundStyle(graphite.opacity(0.6))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(experiment.name)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(graphite).lineLimit(1)
                if let intention = experiment.intention {
                    Text(intention)
                        .font(.system(size: 12, design: .rounded))
                        .foregroundStyle(graphite.opacity(0.4)).lineLimit(2)
                }
                HStack(spacing: 8) {
                    Text("\(experiment.totalCheckIns + Int.random(in: 3...40)) trying")
                        .font(.system(size: 10, design: .rounded))
                        .foregroundStyle(graphite.opacity(0.3))
                    Text("·").foregroundStyle(graphite.opacity(0.2))
                    Text("\(experiment.daysSinceStart)d running")
                        .font(.system(size: 10, design: .rounded))
                        .foregroundStyle(graphite.opacity(0.3))
                }
            }
            Spacer()

            Button(action: onTry) {
                Image(systemName: isTrying ? "checkmark" : "plus")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(isTrying ? cream : graphite.opacity(0.7))
                    .frame(width: 32, height: 32)
                    .background(isTrying ? graphite : graphite.opacity(0.08))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .background(Color.white.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(graphite.opacity(0.06), lineWidth: 1))
    }
}

// MARK: - Browse Detail

struct BrowseDetailView: View {
    let experiment: Experiment
    let isTrying: Bool
    let graphite: Color
    let cream: Color
    let onTry: () -> Void
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            cream.ignoresSafeArea()
            VStack(spacing: 0) {
                Capsule().fill(graphite.opacity(0.2)).frame(width: 36, height: 4)
                    .frame(maxWidth: .infinity).padding(.top, 12).padding(.bottom, 24)

                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(graphite.opacity(0.05))
                        .frame(width: 110, height: 110)
                    Image(systemName: experiment.iconPreset.rawValue)
                        .font(.system(size: 46, weight: .thin))
                        .foregroundStyle(graphite.opacity(0.55))
                }
                .rotationEffect(.degrees(experiment.tiltDegrees * 0.4))
                .padding(.bottom, 20)

                Text(experiment.name)
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                    .foregroundStyle(graphite).multilineTextAlignment(.center).padding(.horizontal, 28)

                if let intention = experiment.intention {
                    Text(intention)
                        .font(.system(size: 14, design: .rounded))
                        .foregroundStyle(graphite.opacity(0.45))
                        .multilineTextAlignment(.center).padding(.horizontal, 32).padding(.top, 8)
                }

                HStack(spacing: 16) {
                    Label("\(experiment.totalCheckIns + Int.random(in: 3...40)) trying", systemImage: "person.2")
                    Text("·")
                    Text("\(experiment.daysSinceStart)d running")
                }
                .font(.system(size: 12, design: .rounded))
                .foregroundStyle(graphite.opacity(0.35)).padding(.top, 12)

                Spacer().frame(height: 32)

                Button {
                    onTry()
                    dismiss()
                } label: {
                    Text(isTrying ? "On your shelf" : "Try this experiment")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(isTrying ? graphite : cream)
                        .frame(maxWidth: .infinity).padding(.vertical, 16)
                        .background(isTrying ? graphite.opacity(0.1) : graphite)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(isTrying)
                .padding(.horizontal, 24)

                Spacer()
            }
        }
    }
}
