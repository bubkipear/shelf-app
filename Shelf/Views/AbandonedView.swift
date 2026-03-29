import SwiftUI
import UIKit

struct AbandonedView: View {
    @EnvironmentObject var store: SupabaseExperimentStore
    @Binding var selectedTab: Int
    @State private var selectedExperiment: Experiment?
    @State private var showBrowse = false

    // MARK: Colors
    private let bg        = Color(red: 245/255, green: 238/255, blue: 232/255)
    private let inkMid    = Color(red: 114/255, green: 106/255, blue: 100/255)
    private let inkMuted  = Color(red: 154/255, green: 145/255, blue: 136/255)
    private let dotGreen  = Color(red: 123/255, green: 198/255, blue: 122/255)
    private let dotYellow = Color(red: 232/255, green: 200/255, blue: 74/255)
    private let dotRed    = Color(red: 220/255, green: 100/255, blue: 90/255)
    private let slotBg    = Color(red: 237/255, green: 231/255, blue: 223/255)

    // MARK: Fixed asset constants
    private let shelfImageHeight: CGFloat = 82
    private let shelfOverlap: CGFloat     = 50
    private let interShelfGap: CGFloat    = 16

    private func shelvesPadding(h: CGFloat) -> CGFloat { h * 0.235 }
    private func itemRowHeight(h: CGFloat) -> CGFloat  { h * 0.106 }

    // MARK: Computed
    private var experiments: [Experiment] {
        store.myExperiments.filter { $0.status == .abandoned }
    }

    private func expAt(_ idx: Int) -> Experiment? {
        idx < experiments.count ? experiments[idx] : nil
    }

    // MARK: Body
    var body: some View {
        GeometryReader { geo in
            let h = geo.size.height
            ZStack(alignment: .top) {
                bg.ignoresSafeArea()

                headerView
                    .padding(.horizontal, 20)
                    .padding(.top, 16)

                VStack(spacing: 0) {
                    VStack(spacing: interShelfGap) {
                        shelfView(slotRange: 0..<3, geo: geo)
                        shelfView(slotRange: 3..<6, geo: geo)
                        shelfView(slotRange: 6..<8, geo: geo)
                    }
                    bottomNav
                        .padding(.horizontal, 24)
                        .padding(.top, 16)
                }
                .padding(.top, shelvesPadding(h: h))
            }
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
                Text("ABANDONED")
                    .font(.custom("BalooBhai2-Regular", size: 24))
                    .tracking(24 * 0.14)
                    .foregroundColor(inkMid)
                Text("— experiments you let go —")
                    .font(.custom("BalooBhai2-Regular", size: 12))
                    .foregroundColor(inkMid)
            }
        }
    }

    // MARK: - Shelf
    func shelfView(slotRange: Range<Int>, geo: GeometryProxy) -> some View {
        let h         = geo.size.height
        let irh       = itemRowHeight(h: h)
        let slotCount = slotRange.count
        let slotWidth = (geo.size.width - 40) / CGFloat(slotCount)

        return VStack(spacing: -shelfOverlap) {
            HStack(alignment: .bottom, spacing: 0) {
                ForEach(slotRange, id: \.self) { absIdx in
                    ZStack(alignment: .bottom) {
                        if let exp = expAt(absIdx) {
                            expItem(exp: exp, slotWidth: slotWidth)
                                .padding(.bottom, shelfOverlap)
                                .onTapGesture { selectedExperiment = exp }
                        }
                    }
                    .frame(width: slotWidth)
                }
            }
            .frame(height: irh)
            .zIndex(1)

            Image("shelf")
                .resizable()
                .scaledToFit()
                .padding(.horizontal, 20)
        }
    }

    // MARK: - Experiment item
    func expItem(exp: Experiment, slotWidth: CGFloat) -> some View {
        let imgFrame: CGSize = {
            if exp.hasCustomImage, let img = store.loadCustomImage(for: exp.id) {
                return aspectFitFrame(imageSize: img.size, slotWidth: slotWidth)
            } else if let name = exp.iconPreset.stickerImageName, let img = UIImage(named: name) {
                return aspectFitFrame(imageSize: img.size, slotWidth: slotWidth)
            }
            return CGSize(width: 54, height: 72)
        }()

        return VStack(spacing: 2) {
            TightLineLabel(text: exp.name, dotColor: UIColor(stateColor(exp)))
            Group {
                if exp.hasCustomImage, let img = store.loadCustomImage(for: exp.id) {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFit()
                        .frame(width: imgFrame.width, height: imgFrame.height)
                } else if let sticker = exp.iconPreset.stickerImageName {
                    Image(sticker)
                        .resizable()
                        .scaledToFit()
                        .frame(width: imgFrame.width, height: imgFrame.height)
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
            .shadow(color: .black.opacity(0.10), radius: 5, x: 0, y: 4)
        }
    }

    // MARK: - Bottom nav
    var bottomNav: some View {
        HStack {
            Spacer()
            Button { withAnimation { selectedTab = 1 } } label: {
                HStack(spacing: 4) {
                    Text("ongoing")
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
    private func aspectFitFrame(imageSize: CGSize, slotWidth: CGFloat) -> CGSize {
        let maxH: CGFloat = 110
        let targetW = slotWidth * 0.9
        let aspect = imageSize.width / imageSize.height
        let naturalH = targetW / aspect
        if naturalH <= maxH {
            return CGSize(width: targetW, height: naturalH)
        } else {
            return CGSize(width: maxH * aspect, height: maxH)
        }
    }

    func stateColor(_ exp: Experiment) -> Color {
        switch exp.experimentState {
        case .onTrack:   return dotGreen
        case .missed:    return dotYellow
        case .offTrack:  return dotRed
        case .abandoned: return inkMuted
        case .completed: return dotGreen
        }
    }
}
