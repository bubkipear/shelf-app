import SwiftUI

struct NewExperimentView: View {
    @EnvironmentObject var store: ExperimentStore
    @Environment(\.dismiss) var dismiss

    @State private var name: String = ""
    @State private var intention: String = ""
    @State private var frequency: CheckInFrequency? = .daily
    @State private var durationDays: Int? = 30
    @State private var isPublic: Bool = true
    @State private var selectedPlanet: String = "planet_01"
    @State private var customDuration: String = "30"
    @State private var openEnded: Bool = false
    @State private var step: Int = 0   // 0 = name+planet, 1 = details

    private let allPlanets = (1...12).map { "planet_\(String(format: "%02d", $0))" }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                // Handle
                Capsule()
                    .fill(.white.opacity(0.2))
                    .frame(width: 36, height: 4)
                    .padding(.top, 12)
                    .padding(.bottom, 28)

                // Progress dots
                HStack(spacing: 6) {
                    ForEach(0..<2) { i in
                        Capsule()
                            .fill(i <= step ? Color.white : Color.white.opacity(0.2))
                            .frame(width: i == step ? 20 : 6, height: 6)
                            .animation(.spring(response: 0.4), value: step)
                    }
                }
                .padding(.bottom, 32)

                if step == 0 {
                    stepOne
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .trailing)),
                            removal: .opacity.combined(with: .move(edge: .leading))
                        ))
                } else {
                    stepTwo
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .trailing)),
                            removal: .opacity.combined(with: .move(edge: .leading))
                        ))
                }
            }
        }
    }

    // MARK: - Step 1: Name + Planet Pick

    private var stepOne: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 28) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Name your experiment")
                        .font(.system(size: 22, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)

                    ZStack(alignment: .leading) {
                        if name.isEmpty {
                            Text("e.g. Wake before 5am")
                                .font(.system(size: 18, design: .rounded))
                                .foregroundStyle(.white.opacity(0.2))
                        }
                        TextField("", text: $name)
                            .font(.system(size: 18, design: .rounded))
                            .foregroundStyle(.white)
                            .tint(Color.white)
                            .submitLabel(.next)
                    }
                    .padding(.vertical, 16)
                    .padding(.horizontal, 2)

                    Rectangle()
                        .fill(.white.opacity(0.15))
                        .frame(height: 1)
                }

                VStack(alignment: .leading, spacing: 16) {
                    Text("Pick your planet")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.6))

                    // Planet grid
                    LazyVGrid(columns: Array(repeating: .init(.flexible(), spacing: 8), count: 4), spacing: 16) {
                        ForEach(allPlanets, id: \.self) { asset in
                            let isSelected = selectedPlanet == asset
                            let mockExp = mockExperiment(for: asset)

                            ZStack {
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(isSelected ? Color.white.opacity(0.1) : Color.clear)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(isSelected ? Color.white.opacity(0.4) : Color.white.opacity(0.08), lineWidth: 1)
                                    )

                                PlanetView(experiment: mockExp, size: 42)
                                    .padding(10)
                            }
                            .frame(height: 72)
                            .onTapGesture { withAnimation(.spring(response: 0.3)) { selectedPlanet = asset } }
                        }
                    }
                }

                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) { step = 1 }
                } label: {
                    Text("Continue")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundStyle(name.isEmpty ? .black.opacity(0.3) : .black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 17)
                        .background(name.isEmpty ? Color.white.opacity(0.3) : Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .disabled(name.isEmpty)
                .padding(.top, 8)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Step 2: Details

    private var stepTwo: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 28) {

                // Intention
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Set an intention")
                            .font(.system(size: 22, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                        Text("optional")
                            .font(.system(size: 12, design: .rounded))
                            .foregroundStyle(.white.opacity(0.3))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.white.opacity(0.08))
                            .clipShape(Capsule())
                    }

                    Text("Why are you trying this?")
                        .font(.system(size: 14, design: .rounded))
                        .foregroundStyle(.white.opacity(0.35))

                    ZStack(alignment: .topLeading) {
                        if intention.isEmpty {
                            Text("In 1–2 sentences…")
                                .font(.system(size: 15, design: .rounded))
                                .foregroundStyle(.white.opacity(0.2))
                                .padding(.top, 14)
                                .padding(.leading, 16)
                        }
                        TextEditor(text: $intention)
                            .font(.system(size: 15, design: .rounded))
                            .foregroundStyle(.white)
                            .scrollContentBackground(.hidden)
                            .frame(minHeight: 80)
                            .padding(12)
                    }
                    .background(Color.white.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                // Frequency
                VStack(alignment: .leading, spacing: 14) {
                    Text("How often?")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.6))

                    HStack(spacing: 8) {
                        ForEach(CheckInFrequency.allCases, id: \.self) { f in
                            let selected = frequency == f
                            Button { withAnimation(.spring(response: 0.3)) { frequency = f } } label: {
                                Text(f.rawValue)
                                    .font(.system(size: 13, weight: selected ? .semibold : .regular, design: .rounded))
                                    .foregroundStyle(selected ? .black : .white.opacity(0.55))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 10)
                                    .background(selected ? Color.white : Color.white.opacity(0.07))
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                // Duration
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Text("Duration")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.6))
                        Spacer()
                        Toggle("Open-ended", isOn: $openEnded)
                            .font(.system(size: 13, design: .rounded))
                            .foregroundStyle(.white.opacity(0.4))
                            .toggleStyle(SwitchToggleStyle(tint: .white.opacity(0.6)))
                            .labelsHidden()
                        Text("Open-ended")
                            .font(.system(size: 13, design: .rounded))
                            .foregroundStyle(.white.opacity(0.4))
                    }

                    if !openEnded {
                        HStack(spacing: 8) {
                            ForEach([7, 14, 21, 30], id: \.self) { d in
                                let selected = durationDays == d
                                Button { withAnimation(.spring(response: 0.3)) { durationDays = d } } label: {
                                    Text("\(d)d")
                                        .font(.system(size: 13, weight: selected ? .semibold : .regular, design: .rounded))
                                        .foregroundStyle(selected ? .black : .white.opacity(0.55))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(selected ? Color.white : Color.white.opacity(0.07))
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }

                // Visibility
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Make it public")
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                .foregroundStyle(.white.opacity(0.6))
                            Text("Others can see your experiment name + intention")
                                .font(.system(size: 12, design: .rounded))
                                .foregroundStyle(.white.opacity(0.3))
                        }
                        Spacer()
                        Toggle("", isOn: $isPublic)
                            .toggleStyle(SwitchToggleStyle(tint: .white.opacity(0.7)))
                    }
                }
                .padding(16)
                .background(Color.white.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: 14))

                // Action buttons
                HStack(spacing: 12) {
                    Button {
                        withAnimation(.spring(response: 0.4)) { step = 0 }
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.6))
                            .frame(width: 52, height: 54)
                            .background(Color.white.opacity(0.07))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)

                    Button {
                        launch()
                    } label: {
                        Text("Plant in sky")
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 17)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                }
                .padding(.top, 8)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Actions

    private func launch() {
        let experiment = Experiment(
            name: name,
            intention: intention.isEmpty ? nil : intention,
            frequency: frequency,
            durationDays: openEnded ? nil : durationDays,
            isPublic: isPublic,
            planetAsset: selectedPlanet
        )
        store.add(experiment)
        dismiss()
    }

    private func mockExperiment(for asset: String) -> Experiment {
        Experiment(name: "", frequency: .daily, planetAsset: asset)
    }
}
