import SwiftUI

// MARK: - Shelf Item — renders either a custom photo sticker or a preset icon

struct ShelfItemView: View {
    let experiment: Experiment
    var size: CGFloat = 80
    var showLabel: Bool = true
    var customImage: UIImage? = nil

    private let graphite = Color(red: 0.25, green: 0.23, blue: 0.22)

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                if let img = customImage {
                    // Custom photo — background removed, sticker style
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFit()
                        .frame(width: size, height: size)
                        .shadow(color: .black.opacity(0.18), radius: 4, x: 1, y: 3)
                } else {
                    // Preset icon — clean card
                    RoundedRectangle(cornerRadius: size * 0.12)
                        .fill(Color(red: 0.97, green: 0.95, blue: 0.91))
                        .frame(width: size, height: size)
                        .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 2)

                    Image(systemName: experiment.iconPreset.rawValue)
                        .font(.system(size: size * 0.42, weight: .thin))
                        .foregroundStyle(graphite.opacity(0.75))
                }
            }
            .rotationEffect(.degrees(experiment.tiltDegrees))

            if showLabel {
                Text(experiment.name)
                    .font(.system(size: 11, weight: .regular, design: .rounded))
                    .foregroundStyle(graphite.opacity(0.55))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: size * 1.3)
            }
        }
    }
}

// MARK: - Larger hero version for detail view

struct ShelfItemHeroView: View {
    let experiment: Experiment
    var customImage: UIImage? = nil

    private let graphite = Color(red: 0.25, green: 0.23, blue: 0.22)
    private let size: CGFloat = 140

    var body: some View {
        ZStack {
            if let img = customImage {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFit()
                    .frame(width: size, height: size)
                    .shadow(color: .black.opacity(0.2), radius: 8, x: 2, y: 6)
            } else {
                RoundedRectangle(cornerRadius: size * 0.12)
                    .fill(Color(red: 0.97, green: 0.95, blue: 0.91))
                    .frame(width: size, height: size)
                    .shadow(color: .black.opacity(0.1), radius: 6, x: 0, y: 4)

                Image(systemName: experiment.iconPreset.rawValue)
                    .font(.system(size: size * 0.42, weight: .thin))
                    .foregroundStyle(graphite.opacity(0.75))
            }
        }
        .rotationEffect(.degrees(experiment.tiltDegrees * 0.5))
    }
}
