import SwiftUI
import Combine
import UIKit

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

    // MARK: Fixed asset constants (shelf.png dimensions — do not scale)
    private let shelfImageHeight: CGFloat = 82
    private let shelfOverlap: CGFloat     = 50
    private let interShelfGap: CGFloat    = 16

    // MARK: Proportional layout helpers (calibrated for iPhone 17 Pro, 852pt logical height)
    // Pass geo.size.height so every device scales automatically.
    private func shelvesPadding(h: CGFloat) -> CGFloat { h * 0.235 }  // ≈ 200pt @ 852
    private func itemRowHeight(h: CGFloat) -> CGFloat  { h * 0.106 }  // ≈  90pt @ 852

    private func shelfTotalHeight(h: CGFloat) -> CGFloat {
        itemRowHeight(h: h) + shelfImageHeight - shelfOverlap
    }
    private func shelf3PlankY(h: CGFloat) -> CGFloat {
        shelvesPadding(h: h)
            + shelfTotalHeight(h: h) + interShelfGap   // shelf 1 + gap
            + shelfTotalHeight(h: h) + interShelfGap   // shelf 2 + gap
            + itemRowHeight(h: h)                        // shelf 3 items → plank surface
    }
    // +100pt compensates for transparent padding at the bottom of the cat sprite
    private func catTopY(h: CGFloat) -> CGFloat { shelf3PlankY(h: h) - 256 + 100 }

    private func shelf1BottomY(h: CGFloat) -> CGFloat { shelvesPadding(h: h) + shelfTotalHeight(h: h) }
    // Button sits visually between shelf 1 and shelf 2
    private func createNewTopY(h: CGFloat) -> CGFloat  { shelf1BottomY(h: h) + 8 }

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
            let h = geo.size.height
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
                    bottomNav
                        .padding(.horizontal, 24)
                        .padding(.top, 16)
                }
                .padding(.top, shelvesPadding(h: h))

                // ── Create-new overlay — does NOT affect shelf spacing ──────
                if actives.count < 8 {
                    Button { showNewExperiment = true } label: {
                        VStack(spacing: 0) {
                            Text("+")
                                .font(.system(size: 64, weight: .regular, design: .rounded))
                                .foregroundColor(inkMid)
                                .padding(.bottom, -18) // collapse dead space below glyph
                            Text("create new")
                                .font(.custom("BalooBhai2-Regular", size: 12))
                                .foregroundColor(inkMid)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.plain)
                    .offset(y: createNewTopY(h: h))
                }

                // ── Cat — absolutely positioned, bottom on shelf-3 plank ───
                Image(catImages[catSequence[catFrameIdx]])
                    .resizable()
                    .frame(width: 256, height: 256)
                    .offset(y: catTopY(h: h))
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
                    .font(.custom("BalooBhai2-Regular", size: 24))
                    .tracking(24 * 0.14)
                    .foregroundColor(inkMid)
                Text("— Day \(dayCount) of growing —")
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
                    // Bottom-aligned: image bottom sits on the shelf plank,
                    // label floats above the image.
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
        // Pre-compute frame in regular Swift (not inside @ViewBuilder)
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

    /// Anchors to slot width, preserves aspect ratio, caps height at maxHeight.
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
        case .tended:             return dotGreen
        case .neglected, .adrift: return dotYellow
        case .abandoned:          return inkMuted
        case .completed:          return dotGreen
        }
    }
}

// MARK: - TightLineLabel
// SwiftUI lineSpacing() can only add space, not reduce below the font's natural line height.
// This UIViewRepresentable uses NSParagraphStyle.lineHeightMultiple to actually compress lines.
struct TightLineLabel: UIViewRepresentable {
    let text: String
    var dotColor: UIColor? = nil
    private static let font     = UIFont(name: "BalooBhai2-Regular", size: 12) ?? .systemFont(ofSize: 12)
    private static let color    = UIColor(red: 114/255, green: 106/255, blue: 100/255, alpha: 1)

    func makeUIView(context: Context) -> UILabel {
        let label = UILabel()
        label.numberOfLines = 2
        label.textAlignment = .center
        label.lineBreakMode = .byWordWrapping
        apply(to: label)
        return label
    }
    func updateUIView(_ label: UILabel, context: Context) { apply(to: label) }

    private func apply(to label: UILabel) {
        let style = NSMutableParagraphStyle()
        style.lineHeightMultiple = 0.82
        style.alignment = .center
        let attributed = NSMutableAttributedString(string: text, attributes: [
            .paragraphStyle: style,
            .font: Self.font,
            .foregroundColor: Self.color
        ])
        if let dotColor {
            // Render a 6×6 circle and attach it inline after the last word
            let dotSize = CGSize(width: 6, height: 6)
            let renderer = UIGraphicsImageRenderer(size: dotSize)
            let dotImage = renderer.image { ctx in
                dotColor.setFill()
                ctx.cgContext.fillEllipse(in: CGRect(origin: .zero, size: dotSize))
            }
            let attachment = NSTextAttachment()
            attachment.image = dotImage
            // Vertically centre the dot on the font's cap-height
            let capHeight = Self.font.capHeight
            attachment.bounds = CGRect(x: 0, y: (capHeight - dotSize.height) / 2,
                                       width: dotSize.width, height: dotSize.height)
            let prefix = NSMutableAttributedString(attachment: attachment)
            prefix.append(NSAttributedString(string: " "))
            attributed.insert(prefix, at: 0)
        }
        label.attributedText = attributed
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: UILabel, context: Context) -> CGSize? {
        let w = proposal.width ?? uiView.intrinsicContentSize.width
        return uiView.sizeThatFits(CGSize(width: w, height: .greatestFiniteMagnitude))
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
