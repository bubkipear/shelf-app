import SwiftUI

struct ExperimentDetailView: View {
    @EnvironmentObject var store: SupabaseExperimentStore
    @Environment(\.dismiss) var dismiss

    let experiment: Experiment

    @State private var showAddObservation = false
    @State private var showReflectionPrompt = false
    @State private var reflection: String = ""
    @State private var pendingStatus: ExperimentStatus?
    @State private var checkedInThisSession = false
    @State private var bumpScale: CGFloat = 1.0

    private let cream    = Color(red: 0.98, green: 0.96, blue: 0.93)
    private let graphite = Color(red: 0.25, green: 0.23, blue: 0.22)
    private let shelfLine = Color(red: 0.72, green: 0.68, blue: 0.63)

    private var live: Experiment {
        store.myExperiments.first(where: { $0.id == experiment.id }) ?? experiment
    }
    private var customImage: UIImage? {
        live.hasCustomImage ? store.loadCustomImage(for: live.id) : nil
    }

    var body: some View {
        ZStack {
            cream.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {

                    // Hero shelf scene
                    ZStack(alignment: .bottom) {
                        cream
                        VStack(spacing: 0) {
                            Spacer()
                            ShelfItemHeroView(experiment: live, customImage: customImage)
                                .scaleEffect(bumpScale)
                                .animation(.spring(response: 0.4, dampingFraction: 0.5), value: bumpScale)
                                .padding(.bottom, 20)
                            ShelfLineView(color: shelfLine)
                        }
                    }
                    .frame(height: 260)

                    // Name + state
                    VStack(spacing: 8) {
                        Text(live.name)
                            .font(.system(size: 24, weight: .semibold, design: .rounded))
                            .foregroundStyle(graphite)
                            .multilineTextAlignment(.center)

                        if let intention = live.intention {
                            Text(intention)
                                .font(.system(size: 14, design: .rounded))
                                .foregroundStyle(graphite.opacity(0.45))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                        }

                        stateLabel
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 24)

                    // Stats
                    HStack(spacing: 0) {
                        StatCell(value: "\(live.totalCheckIns)", label: "check-ins",  graphite: graphite)
                        Divider().frame(height: 28).opacity(0.15)
                        StatCell(value: "\(live.currentStreakDays)", label: "streak", graphite: graphite)
                        Divider().frame(height: 28).opacity(0.15)
                        StatCell(value: "\(live.daysSinceStart)d", label: "running",  graphite: graphite)
                    }
                    .padding(.vertical, 18)
                    .background(graphite.opacity(0.04))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .padding(.horizontal, 20)
                    .padding(.top, 24)

                    // Check-in (active only)
                    if live.status == .active {
                        checkInSection.padding(.top, 28)
                    } else {
                        closedBanner.padding(.top, 28)
                    }

                    // Observation log
                    observationLog.padding(.top, 32)

                    // Close options
                    if live.status == .active {
                        closeSection.padding(.top, 24)
                    }

                    Spacer(minLength: 60)
                }
                .padding(.top, 20)
            }

            VStack {
                Capsule()
                    .fill(graphite.opacity(0.15))
                    .frame(width: 36, height: 4)
                    .padding(.top, 12)
                Spacer()
            }
        }
        .sheet(isPresented: $showAddObservation) {
            AddObservationView(experimentId: live.id).environmentObject(store)
        }
        .sheet(isPresented: $showReflectionPrompt) {
            ReflectionView(status: pendingStatus ?? .abandoned, reflection: $reflection, graphite: graphite, cream: cream) {
                commitClose()
            }
        }
    }

    // MARK: - Subviews

    private var stateLabel: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(stateColor)
                .frame(width: 6, height: 6)
            Text(stateText)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(graphite.opacity(0.4))
                .tracking(1.2)
                .textCase(.uppercase)
        }
        .padding(.top, 2)
    }

    private var stateColor: Color {
        switch live.experimentState {
        case .tended:    return .green.opacity(0.8)
        case .neglected: return .orange.opacity(0.8)
        case .adrift:    return graphite.opacity(0.3)
        case .abandoned: return graphite.opacity(0.2)
        case .completed: return .blue.opacity(0.6)
        }
    }

    private var stateText: String {
        switch live.experimentState {
        case .tended:    return "tended"
        case .neglected: return "needs attention"
        case .adrift:    return "adrift"
        case .abandoned: return "abandoned"
        case .completed: return "complete"
        }
    }

    private var checkInSection: some View {
        VStack(spacing: 0) {
            if checkedInThisSession {
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(.green.opacity(0.7))
                    Text("Checked in")
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(graphite.opacity(0.5))
                }
                .transition(.scale.combined(with: .opacity))
            } else {
                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                        checkedInThisSession = true
                        bumpScale = 1.08
                    }
                    store.checkIn(experimentId: live.id, note: nil)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { bumpScale = 1.0 }
                } label: {
                    Text("Mark today ✓")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(cream)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(graphite)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal, 20)
                .transition(.opacity)
            }
        }
    }

    private var closedBanner: some View {
        VStack(spacing: 6) {
            Text(live.status == .completed ? "Experiment complete" : "This experiment ended")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(graphite.opacity(0.4))
            if let r = live.closingReflection, !r.isEmpty {
                Text("\u{201C}\(r)\u{201D}")
                    .font(.system(size: 13, design: .rounded)).italic()
                    .foregroundStyle(graphite.opacity(0.3))
                    .padding(.horizontal, 28).multilineTextAlignment(.center)
            }
        }
    }

    private var observationLog: some View {
        let notes = live.checkIns
            .filter { $0.note != nil && !($0.note!.isEmpty) }
            .sorted { $0.date > $1.date }

        return VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("OBSERVATION LOG")
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .tracking(2).foregroundStyle(graphite.opacity(0.3))
                Spacer()
                Button { showAddObservation = true } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus").font(.system(size: 11, weight: .semibold))
                        Text("Add").font(.system(size: 12, weight: .medium, design: .rounded))
                    }
                    .foregroundStyle(graphite)
                    .padding(.horizontal, 12).padding(.vertical, 6)
                    .background(graphite.opacity(0.08))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 24)

            if notes.isEmpty {
                Text("No observations yet — tap Add to record what you're noticing")
                    .font(.system(size: 13, design: .rounded))
                    .foregroundStyle(graphite.opacity(0.25))
                    .padding(.horizontal, 24).padding(.top, 14)
            } else {
                LazyVStack(spacing: 0) {
                    ForEach(Array(notes.enumerated()), id: \.element.id) { index, entry in
                        HStack(alignment: .top, spacing: 14) {
                            VStack(spacing: 0) {
                                Circle().fill(graphite.opacity(0.5)).frame(width: 5, height: 5).padding(.top, 6)
                                if index < notes.count - 1 {
                                    Rectangle().fill(graphite.opacity(0.08)).frame(width: 1).frame(maxHeight: .infinity)
                                }
                            }
                            .frame(width: 5)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(entry.date.formatted(date: .abbreviated, time: .shortened))
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundStyle(graphite.opacity(0.3))
                                Text(entry.note!)
                                    .font(.system(size: 14, design: .rounded))
                                    .foregroundStyle(graphite.opacity(0.8))
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 24).padding(.vertical, 12)
                    }
                }
                .padding(.top, 8)
            }
        }
    }

    private var closeSection: some View {
        VStack(spacing: 12) {
            Rectangle().fill(graphite.opacity(0.08)).frame(height: 1).padding(.horizontal, 24)
            HStack(spacing: 10) {
                CloseButton(label: "Abandon", borderColor: graphite.opacity(0.2), textColor: graphite.opacity(0.45)) {
                    pendingStatus = .abandoned; showReflectionPrompt = true
                }
                CloseButton(label: "Complete", borderColor: graphite.opacity(0.5), textColor: graphite.opacity(0.7)) {
                    pendingStatus = .completed; showReflectionPrompt = true
                }
            }
            .padding(.horizontal, 20)
        }
    }

    private func commitClose() {
        store.close(experimentId: live.id, as: pendingStatus ?? .abandoned, reflection: reflection.isEmpty ? nil : reflection)
        dismiss()
    }
}

// MARK: - Supporting

struct StatCell: View {
    let value: String
    let label: String
    let graphite: Color
    var body: some View {
        VStack(spacing: 3) {
            Text(value).font(.system(size: 20, weight: .semibold, design: .rounded)).foregroundStyle(graphite)
            Text(label).font(.system(size: 10, design: .rounded)).foregroundStyle(graphite.opacity(0.35)).tracking(0.5)
        }
        .frame(maxWidth: .infinity)
    }
}

struct CloseButton: View {
    let label: String
    let borderColor: Color
    let textColor: Color
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(textColor)
                .frame(maxWidth: .infinity).padding(.vertical, 14)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(borderColor, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Add Observation

struct AddObservationView: View {
    @EnvironmentObject var store: SupabaseExperimentStore
    @Environment(\.dismiss) var dismiss
    let experimentId: UUID
    @State private var text: String = ""
    @FocusState private var focused: Bool
    private let cream    = Color(red: 0.98, green: 0.96, blue: 0.93)
    private let graphite = Color(red: 0.25, green: 0.23, blue: 0.22)

    var body: some View {
        ZStack {
            cream.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 0) {
                Capsule().fill(graphite.opacity(0.2)).frame(width: 36, height: 4)
                    .frame(maxWidth: .infinity).padding(.top, 12).padding(.bottom, 28)

                Text("New observation")
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .foregroundStyle(graphite).padding(.horizontal, 24)
                Text("What are you noticing? Not judging — just noticing.")
                    .font(.system(size: 13, design: .rounded))
                    .foregroundStyle(graphite.opacity(0.35))
                    .padding(.horizontal, 24).padding(.top, 6).padding(.bottom, 20)

                ZStack(alignment: .topLeading) {
                    if text.isEmpty {
                        Text("Write anything…")
                            .font(.system(size: 16, design: .rounded))
                            .foregroundStyle(graphite.opacity(0.18))
                            .padding(.top, 16).padding(.leading, 18)
                    }
                    TextEditor(text: $text)
                        .font(.system(size: 16, design: .rounded)).foregroundStyle(graphite)
                        .scrollContentBackground(.hidden).frame(minHeight: 140).padding(12)
                        .focused($focused)
                }
                .background(graphite.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .padding(.horizontal, 20)

                HStack(spacing: 10) {
                    Button("Cancel") { dismiss() }
                        .font(.system(size: 14, design: .rounded)).foregroundStyle(graphite.opacity(0.4))
                        .frame(maxWidth: .infinity).padding(.vertical, 15)
                        .background(graphite.opacity(0.05)).clipShape(RoundedRectangle(cornerRadius: 12))

                    Button("Save") {
                        store.addObservation(experimentId: experimentId, note: text)
                        dismiss()
                    }
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(text.isEmpty ? graphite.opacity(0.3) : cream)
                    .frame(maxWidth: .infinity).padding(.vertical, 15)
                    .background(text.isEmpty ? graphite.opacity(0.1) : graphite)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding(.horizontal, 20).padding(.top, 14)
                Spacer()
            }
        }
        .onAppear { focused = true }
    }
}

// MARK: - Reflection sheet

struct ReflectionView: View {
    let status: ExperimentStatus
    @Binding var reflection: String
    let graphite: Color
    let cream: Color
    let onCommit: () -> Void
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            cream.ignoresSafeArea()
            VStack(spacing: 24) {
                Capsule().fill(graphite.opacity(0.2)).frame(width: 36, height: 4).padding(.top, 12)

                Text(status == .completed ? "What did you learn?" : "What did this teach you?")
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .foregroundStyle(graphite).multilineTextAlignment(.center).padding(.horizontal, 28)

                ZStack(alignment: .topLeading) {
                    if reflection.isEmpty {
                        Text("Any observation, however small…")
                            .font(.system(size: 15, design: .rounded))
                            .foregroundStyle(graphite.opacity(0.2))
                            .padding(.top, 16).padding(.leading, 18)
                    }
                    TextEditor(text: $reflection)
                        .font(.system(size: 16, design: .rounded)).foregroundStyle(graphite)
                        .scrollContentBackground(.hidden).frame(minHeight: 120).padding(12)
                }
                .background(graphite.opacity(0.04)).clipShape(RoundedRectangle(cornerRadius: 14))
                .padding(.horizontal, 20)

                HStack(spacing: 10) {
                    Button("Skip") { dismiss(); onCommit() }
                        .font(.system(size: 14, design: .rounded)).foregroundStyle(graphite.opacity(0.4))
                        .frame(maxWidth: .infinity).padding(.vertical, 15)
                        .background(graphite.opacity(0.05)).clipShape(RoundedRectangle(cornerRadius: 12))
                    Button("Save") { dismiss(); onCommit() }
                        .font(.system(size: 14, weight: .semibold, design: .rounded)).foregroundStyle(cream)
                        .frame(maxWidth: .infinity).padding(.vertical, 15)
                        .background(graphite).clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal, 20)
                Spacer()
            }
        }
    }
}
