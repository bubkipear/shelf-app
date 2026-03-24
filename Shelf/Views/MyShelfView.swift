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
    private let inkMid    = Color(red: 114/255, green: 106/255, blue: 100/255)
    private let inkMuted  = Color(red: 154/255, green: 145/255, blue: 136/255)
    private let dotGreen  = Color(red: 123/255, green: 198/255, blue: 122/255)
    private let dotYellow = Color(red: 232/255, green: 200/255, blue: 74/255)
    private let slotBg    = Color(red: 237/255, green: 231/255, blue: 223/255)

    // MARK: Layout constants
    // shelf.png is 352×82 logical pt (1x asset).
    // Uniform 16pt gap between every pair of shelves — nothing else touches this.
    private let shelvesPadding: CGFloat  = 200   // safe-area top → shelf 1 top
    private let itemRowHeight: CGFloat   = 90
    private let shelfImageHeight: CGFloat = 82
    private let shelfOverlap: CGFloat    = 50    // VStack(spacing: -shelfOverlap)
    private let interShelfGap: CGFloat   = 16    // uniform gap — same between ALL shelves

    private var shelfTotalHeight: CGFloat { itemRowHeight + shelfImageHeight - shelfOverlap } // 122

    // Cat bottom sits on the shelf-3 plank surface.
    // Layout (all from safe-area top):
    //   shelvesPadding | shelf1 | gap | shelf2 | gap | itemRow3  ← plank
    private var shelf3PlankY: CGFloat {
        shelvesPadding
            + shelfTotalHeight + interShelfGap   // shelf 1 + gap
            + shelfTotalHeight + interShelfGap   // shelf 2 + gap
            + itemRowHeight                       // shelf 3 items row → plank surface
    }
    private var catTopY: CGFloat { shelf3PlankY - 256 }

    // Create-new button floats between shelf 1 and shelf 2 as a ZStack overlay.
    // Its vertical centre sits at the mid-point of that 16pt gap.
    private var shelf1BottomY: CGFloat { shelvesPadding + shelfTotalHeight }
    private var createNewCentreY: CGFloat { shelf1BottomY + interShelfGap / 2 }

    // MARK: Computed
    private var actives: [Experiment] { store.activeExperiments }

    private var dayCount: Int {
        guard let earliest = store.myExperiments.min(by: { $0.startDate < $1.startDate }) else { return 1 }
        let cal = Calendar.current
        return (cal.dateComponents([.day],
            from: cal.startOfDay(for: earliest.startDate),
            to: cal.startOfDay(for: Date())).day ?? 0) + 1
    }

    private func expAt(_ idx: Int) -> Experiment? {
        idx < actives.count ? actives[idx] : nil
    }

    // MARK: Body
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .top) {
                bg.ignoresSafeArea()

                // ── Header (do not touch) ──────────────────────────────────
                headerView
                    .padding(.horizontal, 20)
                    .padding(.top, 16)

                // ── Shelves — uniform 16pt spacing, no extra gaps ──────────
                VStack(spacing: 0) {
                    VStack(spacing: interShelfGap) {
                        shelfView(slotRange: 0..<3, geo: geo)
                        shelfView(slotRange: 3..<6, geo: geo)
                        shelfView(slotRange: 6..<8, geo: geo)
                    }
                    // Bottom nav directly below shelf 3
                    bottomNav
                        .padding(.horizontal, 24)
                        .padding(.top, 16)
                }
                .padding(.top, shelvesPadding)

                // ── Create-new overlay — does NOT affect shelf spacing ──────
                // Floats visually between shelf 1 and shelf 2.
                if actives.count < 8 {
                    Button { showNewExperiment = true } label: {
                        VStack(spacing: 4) {
                            Text("+")
                                .font(.system(size: 78, weight: .regular))
                                .foregroundColor(inkMuted)
                            Text("create new")
                                .font(.custom("BalooBhai2-Regular", size: 12))
                                .foregroundColor(inkMuted)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.plain)
                    // Offset so the button's top edge starts at createNewCentreY
                    .offset(y: createNewCentreY)
                }

                // ── Cat — absolutely positioned, bottom on shelf-3 plank ───
                Image(catImages[catSequence[catFrameIdx]])
                    .resizable()
                    .frame(width: 256, height: 256)
                    .offset(y: catTopY)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .allowsHitTesting(false)
            }
        }
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

    // MARK: - Header (do not touch)
    var headerView: some View {
        VStack(spacing: 8) {
            HStack {
                VStack(spacing: 5) {
                    ForEach(0..<3, id: \.self) { _ in
                        Capsule()
                            .fill(inkMid)
                            .frame(width: 22, height: 2)
                    }
                }
                Spacer()
                Button { showBrowse = true } label: {
                    Image(systemName: "globe")
                        .font(.system(size: 22, weight: .light))
                        .foregroundColor(inkMid)
                }
                .buttonStyle(.plain)
            }
            VStack(spacing: 2) {
                Text("MY EXPERIMENTS")
                    .font(.custom("BalooBhai2-Regular", size: 20))
                    .tracking(2.5)
                    .foregroundColor(inkMid)
                Text("— Day \(dayCount) of growing —")
                    .font(.custom("BalooBhai2-Regular", size: 12))
                    .foregroundColor(inkMuted)
            }
        }
    }

    // MARK: - Shelf
    func shelfView(slotRange: Range<Int>, geo: GeometryProxy) -> some View {
        let slotCount = slotRange.count
        let slotWidth = (geo.size.width - 40) / CGFloat(slotCount)

        return VStack(spacing: -shelfOverlap) {
            HStack(alignment: .bottom, spacing: 0) {
                ForEach(slotRange, id: \.self) { absIdx in
                    ZStack(alignment: .bottom) {
                        if let exp = expAt(absIdx) {
                            expItem(exp: exp)
                                .onTapGesture { selectedExperiment = exp }
                        }
                    }
                    .frame(width: slotWidth)
                }
            }
            .frame(height: itemRowHeight)

            Image("shelf")
                .resizable()
                .scaledToFit()
                .padding(.horizontal, 20)
        }
    }

    // MARK: - Experiment item
    func expItem(exp: Experiment) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Circle()
                    .fill(stateColor(exp))
                    .frame(width: 6, height: 6)
                Text(exp.name)
                    .font(.custom("BalooBhai2-Regular", size: 12))
                    .foregroundColor(inkMid)
                    .lineLimit(1)
            }
            Group {
                if exp.hasCustomImage, let img = store.loadCustomImage(for: exp.id) {
                    Image(uiImage: img).resizable().scaledToFit()
                } else {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(slotBg)
                            .frame(width: 54, height: 72)
                        Image(systemName: exp.iconPreset.rawValue)
                            .font(.system(size: 28, weight: .light))
                            .foregroundColor(inkMid)
                    }
                }
            }
            .frame(maxHeight: 80)
            .rotationEffect(.degrees(exp.tiltDegrees))
            .shadow(color: .black.opacity(0.10), radius: 5, x: 0, y: 4)
        }
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
                .foregroundColor(inkMid)
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
                .foregroundColor(inkMid)
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
                .fill(LinearGradient(
                    colors: [color.opacity(0.12), .clear],
                    startPoint: .top, endPoint: .bottom))
                .frame(height: 8)
        }
    }
}
