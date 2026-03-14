import SwiftUI

struct PlanetDetailView: View {
    @EnvironmentObject var store: ExperimentStore
    @Environment(\.dismiss) var dismiss

    let experiment: Experiment

    @State private var note: String = ""
    @State private var showNoteField = false
    @State private var showCloseOptions = false
    @State private var showReflectionPrompt = false
    @State private var reflection: String = ""
    @State private var pendingStatus: ExperimentStatus?
    @State private var checkedInThisSession = false
    @State private var checkInBurst = false

    private var palette: PlanetPalette { PlanetPalette.palette(for: experiment.planetAsset) }
    private var live: Experiment { store.myExperiments.first(where: { $0.id == experiment.id }) ?? experiment }

    var body: some View {
        ZStack {
            // Background — blurred planet colour
            Color.black.ignoresSafeArea()
            palette.primary.opacity(0.06).ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {

                    // Planet hero
                    ZStack {
                        // Glow backdrop
                        Circle()
                            .fill(palette.glow.opacity(0.12))
                            .frame(width: 260, height: 260)
                            .blur(radius: 60)

                        PlanetView(experiment: live, size: 130)
                            .scaleEffect(checkInBurst ? 1.12 : 1.0)
                            .animation(.spring(response: 0.4, dampingFraction: 0.5), value: checkInBurst)
                    }
                    .frame(height: 240)

                    // Name + meta
                    VStack(spacing: 8) {
                        Text(live.name)
                            .font(.system(size: 26, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)

                        if let intention = live.intention {
                            Text(intention)
                                .font(.system(size: 15, weight: .regular, design: .rounded))
                                .foregroundStyle(.white.opacity(0.45))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                        }

                        stateLabel
                    }
                    .padding(.horizontal, 24)

                    // Stats row
                    HStack(spacing: 0) {
                        StatCell(value: "\(live.totalCheckIns)", label: "check-ins")
                        Divider().frame(height: 28).opacity(0.2)
                        StatCell(value: "\(live.currentStreakDays)", label: "streak")
                        Divider().frame(height: 28).opacity(0.2)
                        StatCell(value: "\(live.daysSinceStart)d", label: "orbiting")
                    }
                    .padding(.vertical, 20)
                    .padding(.horizontal, 24)
                    .background(Color.white.opacity(0.04))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal, 20)
                    .padding(.top, 24)

                    // Check-in section (only for active)
                    if live.status == .active {
                        checkInSection
                            .padding(.top, 28)
                    } else {
                        closedBanner
                            .padding(.top, 28)
                    }

                    // Check-in history
                    historySection
                        .padding(.top, 32)

                    // Close options (active only)
                    if live.status == .active {
                        closeSection
                            .padding(.top, 24)
                    }

                    Spacer(minLength: 60)
                }
                .padding(.top, 20)
            }

            // Dismiss handle
            VStack {
                Capsule()
                    .fill(.white.opacity(0.2))
                    .frame(width: 36, height: 4)
                    .padding(.top, 12)
                Spacer()
            }
        }
        .sheet(isPresented: $showReflectionPrompt) {
            ReflectionView(status: pendingStatus ?? .abandoned, reflection: $reflection) {
                commitClose()
            }
        }
    }

    // MARK: - Subviews

    private var stateLabel: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(stateColor)
                .frame(width: 7, height: 7)
            Text(stateText)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.5))
                .tracking(1.2)
                .textCase(.uppercase)
        }
        .padding(.top, 4)
    }

    private var stateColor: Color {
        switch live.planetState {
        case .tended:    return palette.glow
        case .neglected: return .yellow
        case .adrift:    return .gray
        case .abandoned: return .gray.opacity(0.5)
        case .completed: return palette.primary
        }
    }

    private var stateText: String {
        switch live.planetState {
        case .tended:    return "tended"
        case .neglected: return "needs attention"
        case .adrift:    return "adrift"
        case .abandoned: return "abandoned"
        case .completed: return "complete"
        }
    }

    private var checkInSection: some View {
        VStack(spacing: 16) {
            if checkedInThisSession {
                // Confirmed state
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(palette.glow)
                    Text("Checked in")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.6))
                }
                .transition(.scale.combined(with: .opacity))
            } else {
                // Check-in button
                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                        checkedInThisSession = true
                        checkInBurst = true
                    }
                    store.checkIn(experimentId: live.id, note: note.isEmpty ? nil : note)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        checkInBurst = false
                    }
                    if !note.isEmpty {
                        showNoteField = false
                    }
                } label: {
                    Text("Mark today ✓")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 17)
                        .background(palette.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .padding(.horizontal, 20)
                .transition(.opacity)
            }

            // Note toggle
            VStack(spacing: 10) {
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        showNoteField.toggle()
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "pencil")
                            .font(.system(size: 13))
                        Text(showNoteField ? "Hide note" : "Add a note")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                    }
                    .foregroundStyle(.white.opacity(0.35))
                }

                if showNoteField {
                    ZStack(alignment: .topLeading) {
                        if note.isEmpty {
                            Text("Observation, not judgement…")
                                .font(.system(size: 15, design: .rounded))
                                .foregroundStyle(.white.opacity(0.2))
                                .padding(.top, 14)
                                .padding(.leading, 16)
                        }
                        TextEditor(text: $note)
                            .font(.system(size: 15, design: .rounded))
                            .foregroundStyle(.white)
                            .scrollContentBackground(.hidden)
                            .frame(minHeight: 80)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                    }
                    .background(Color.white.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .padding(.horizontal, 20)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .top)),
                        removal: .opacity
                    ))
                }
            }
        }
    }

    private var closedBanner: some View {
        VStack(spacing: 8) {
            Text(live.status == .completed ? "Experiment complete" : "This experiment ended")
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.5))
            if let r = live.closingReflection, !r.isEmpty {
                Text(""\(r)"")
                    .font(.system(size: 14, design: .rounded))
                    .italic()
                    .foregroundStyle(.white.opacity(0.3))
                    .padding(.horizontal, 28)
                    .multilineTextAlignment(.center)
            }
        }
    }

    private var historySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("HISTORY")
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .tracking(2)
                .foregroundStyle(.white.opacity(0.3))
                .padding(.horizontal, 24)

            if live.checkIns.isEmpty {
                Text("No check-ins yet")
                    .font(.system(size: 14, design: .rounded))
                    .foregroundStyle(.white.opacity(0.2))
                    .padding(.horizontal, 24)
            } else {
                LazyVStack(spacing: 10) {
                    ForEach(live.checkIns.sorted(by: { $0.date > $1.date }).prefix(10)) { checkIn in
                        HStack(alignment: .top, spacing: 12) {
                            Circle()
                                .fill(checkIn.didComplete ? palette.glow : Color.gray)
                                .frame(width: 7, height: 7)
                                .padding(.top, 5)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(checkIn.date.formatted(.relative(presentation: .named)))
                                    .font(.system(size: 13, design: .rounded))
                                    .foregroundStyle(.white.opacity(0.5))
                                if let n = checkIn.note, !n.isEmpty {
                                    Text(n)
                                        .font(.system(size: 14, design: .rounded))
                                        .foregroundStyle(.white.opacity(0.75))
                                }
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 24)
                    }
                }
            }
        }
    }

    private var closeSection: some View {
        VStack(spacing: 12) {
            Divider().opacity(0.1).padding(.horizontal, 24)

            HStack(spacing: 12) {
                CloseButton(label: "Abandon", color: .gray.opacity(0.6)) {
                    pendingStatus = .abandoned
                    showReflectionPrompt = true
                }
                CloseButton(label: "Complete", color: palette.primary.opacity(0.8)) {
                    pendingStatus = .completed
                    showReflectionPrompt = true
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

// MARK: - Supporting Views

struct StatCell: View {
    let value: String
    let label: String
    var body: some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
            Text(label)
                .font(.system(size: 11, design: .rounded))
                .foregroundStyle(.white.opacity(0.35))
                .tracking(0.5)
        }
        .frame(maxWidth: .infinity)
    }
}

struct CloseButton: View {
    let label: String
    let color: Color
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.7))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(color.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Reflection sheet

struct ReflectionView: View {
    let status: ExperimentStatus
    @Binding var reflection: String
    let onCommit: () -> Void
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 24) {
                Capsule()
                    .fill(.white.opacity(0.2))
                    .frame(width: 36, height: 4)
                    .padding(.top, 12)

                Text(status == .completed ? "What did you learn?" : "What did this teach you?")
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)

                ZStack(alignment: .topLeading) {
                    if reflection.isEmpty {
                        Text("Any observation, however small…")
                            .font(.system(size: 15, design: .rounded))
                            .foregroundStyle(.white.opacity(0.2))
                            .padding(.top, 16)
                            .padding(.leading, 18)
                    }
                    TextEditor(text: $reflection)
                        .font(.system(size: 16, design: .rounded))
                        .foregroundStyle(.white)
                        .scrollContentBackground(.hidden)
                        .frame(minHeight: 120)
                        .padding(12)
                }
                .background(Color.white.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal, 20)

                HStack(spacing: 12) {
                    Button("Skip") {
                        dismiss()
                        onCommit()
                    }
                    .font(.system(size: 15, design: .rounded))
                    .foregroundStyle(.white.opacity(0.35))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.white.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 14))

                    Button("Save") {
                        dismiss()
                        onCommit()
                    }
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal, 20)

                Spacer()
            }
        }
    }
}
