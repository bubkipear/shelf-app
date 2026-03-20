import SwiftUI
import Combine

struct MyShelfView: View {
    @EnvironmentObject var store: SupabaseExperimentStore
    @Binding var selectedTab: Int
    @State private var showNewExperiment = false
    @State private var selectedExperiment: Experiment?
    @State private var showBrowse = false
    @State private var catFrameIdx = 0

    private let catSequence = [0, 1, 2, 1]
    private let catImages   = ["cat-1", "cat-2", "cat-3"]

    // MARK: Colors
    private let bg        = Color(red: 245/255, green: 238/255, blue: 232/255)
    private let inkDark   = Color(red: 44/255,  green: 44/255,  blue: 42/255)
    private let inkMid    = Color(red: 114/255, green: 106/255, blue: 100/255)
    private let inkMuted  = Color(red: 154/255, green: 145/255, blue: 136/255)
    private let dotGreen  = Color(red: 123/255, green: 198/255, blue: 122/255)
    private let dotYellow = Color(red: 232/255, green: 200/255, blue: 74/255)
    private let slotBg    = Color(red: 237/255, green: 231/255, blue: 223/255)

    // MARK: Computed
    private var actives: [Experiment] { store.activeExperiments }

    private var dayCount: Int {
        guard let earliest = store.myExperiments.min(by: { $0.startDate < $1.startDate }) else { return 1 }
        let cal = Calendar.current
        let days = cal.dateComponents(
            [.day],
            from: cal.startOfDay(for: earliest.startDate),
            to: cal.startOfDay(for: Date())
        ).day ?? 0
        return days + 1
    }

    private func expAt(_ idx: Int) -> Experiment? {
        idx < actives.count ? actives[idx] : nil
    }

    // Absolute slot index for the Create New button, or -1 if shelf is full
    private var createNewSlot: Int {
        actives.count < 8 ? actives.count : -1
    }

    // MARK: Body
    var body: some View {
        GeometryReader { geo in
            ZStack {
                bg.ignoresSafeArea()

                VStack(spacing: 0) {
                    headerView
                        .padding(.top, geo.safeAreaInsets.top + 12)
                        .padding(.bottom, 6)
                        .padding(.horizontal, 20)

                    Spacer(minLength: 0)

                    shelfView(shelfIdx: 0, slotRange: 0..<3, geo: geo)

                    Spacer(minLength: 0)

                    shelfView(shelfIdx: 1, slotRange: 3..<6, geo: geo)

                    Spacer(minLength: 0)

                    shelfView(shelfIdx: 2, slotRange: 6..<8, geo: geo)

                    Spacer(minLength: 0)

                    bottomNav
                        .padding(.horizontal, 24)
                        .padding(.bottom, geo.safeAreaInsets.bottom + 14)
                }
            }
        }
        .ignoresSafeArea()
        .onReceive(Timer.publish(every: 0.4, on: .main, in: .common).autoconnect()) { _ in
            catFrameIdx = (catFrameIdx + 1) % catSequence.count
        }
        .sheet(isPresented: $showNewExperiment) {
            NewExperimentView().environmentObject(store)
        }
        .sheet(item: $selectedExperiment) { exp in
            ExperimentDetailView(experiment: exp).environmentObject(store)
        }
        .fullScreenCover(isPresented: $showBrowse) {
            BrowseView().environmentObject(store)
        }
    }

    // MARK: - Header
    var headerView: some View {
        HStack(alignment: .center) {
            // Hamburger (decorative)
            VStack(spacing: 5) {
                ForEach(0..<3, id: \.self) { _ in
                    Capsule()
                        .fill(inkDark)
                        .frame(width: 22, height: 2)
                }
            }

            Spacer()

            VStack(spacing: 1) {
                Text("MY EXPERIMENTS")
                    .font(.custom("BalooBhai2-SemiBold", size: 12))
                    .tracking(2.5)
                    .foregroundColor(inkDark)
                Text("— Day \(dayCount) of growing —")
                    .font(.custom("BalooBhai2-Regular", size: 12))
                    .foregroundColor(inkMuted)
            }

            Spacer()

            Button { showBrowse = true } label: {
                Image(systemName: "globe")
                    .font(.system(size: 22, weight: .light))
                    .foregroundColor(inkDark)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Shelf
    @ViewBuilder
    func shelfView(shelfIdx: Int, slotRange: Range<Int>, geo: GeometryProxy) -> some View {
        let slotCount  = slotRange.count
        let slotWidth  = (geo.size.width - 40) / CGFloat(slotCount)
        let expsOnShelf = max(0, min(slotCount, actives.count - slotRange.lowerBound))

        VStack(spacing: 0) {
            // Items row
            HStack(spacing: 0) {
                ForEach(slotRange, id: \.self) { absIdx in
                    ZStack {
                        if absIdx == createNewSlot {
                            createNewButton
                        } else if let exp = expAt(absIdx) {
                            expItem(exp: exp)
                                .onTapGesture { selectedExperiment = exp }
                        }
                    }
                    .frame(width: slotWidth, height: 100)
                }
            }
            // Cat sits on the shelf image for shelf 3
            .overlay(alignment: .bottomLeading) {
                if shelfIdx == 2, expsOnShelf < 2 {
                    let catName = catImages[catSequence[catFrameIdx]]
                    Image(catName)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 46)
                        .offset(
                            x: expsOnShelf == 0 ? 24 : slotWidth + 4,
                            y: 16
                        )
                        .allowsHitTesting(false)
                }
            }

            // Shelf image
            Image("shelf")
                .resizable()
                .scaledToFit()
                .padding(.horizontal, 20)
        }
    }

    // MARK: - Experiment item
    @ViewBuilder
    func expItem(exp: Experiment) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Circle()
                    .fill(stateColor(exp))
                    .frame(width: 6, height: 6)
                Text(exp.name)
                    .font(.custom("BalooBhai2-Regular", size: 10))
                    .foregroundColor(inkMid)
                    .lineLimit(1)
            }

            Group {
                if exp.hasCustomImage, let img = store.loadCustomImage(for: exp.id) {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFit()
                } else {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(slotBg)
                            .frame(width: 54, height: 64)
                        Image(systemName: exp.iconPreset.rawValue)
                            .font(.system(size: 26, weight: .light))
                            .foregroundColor(inkMid)
                    }
                }
            }
            .frame(maxHeight: 72)
            .rotationEffect(.degrees(exp.tiltDegrees))
            .shadow(color: .black.opacity(0.10), radius: 5, x: 0, y: 4)
        }
    }

    // MARK: - Create New
    var createNewButton: some View {
        Button { showNewExperiment = true } label: {
            VStack(spacing: 5) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(
                            inkMuted.opacity(0.45),
                            style: StrokeStyle(lineWidth: 1.5, dash: [5, 4])
                        )
                        .frame(width: 52, height: 62)
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .light))
                        .foregroundColor(inkMuted)
                }
                Text("create new")
                    .font(.custom("BalooBhai2-Regular", size: 10))
                    .foregroundColor(inkMuted)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Bottom nav
    var bottomNav: some View {
        HStack {
            Button { withAnimation { selectedTab = 0 } } label: {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 11, weight: .medium))
                    Text("abandoned")
                        .font(.custom("BalooBhai2-Regular", size: 13))
                }
                .foregroundColor(inkMuted)
            }
            .buttonStyle(.plain)

            Spacer()

            Button { withAnimation { selectedTab = 2 } } label: {
                HStack(spacing: 4) {
                    Text("completed")
                        .font(.custom("BalooBhai2-Regular", size: 13))
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .medium))
                }
                .foregroundColor(inkMuted)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Helpers
    func stateColor(_ exp: Experiment) -> Color {
        switch exp.experimentState {
        case .tended:             return dotGreen
        case .neglected, .adrift: return dotYellow
        case .abandoned:          return inkMuted
        case .completed:          return dotGreen
        }
    }
}

// MARK: - ShelfLineView (retained for ExperimentDetailView)
struct ShelfLineView: View {
    let color: Color
    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(color.opacity(0.55))
                .frame(height: 1.5)
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [color.opacity(0.12), .clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(height: 8)
        }
    }
}
