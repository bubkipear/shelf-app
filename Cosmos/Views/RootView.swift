import SwiftUI

struct RootView: View {
    @State private var selectedTab: Tab = .sky

    enum Tab { case sky, stargazing }

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                MySkyView()
                    .tag(Tab.sky)

                StargrazingView()
                    .tag(Tab.stargazing)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            // Custom bottom bar
            HStack(spacing: 0) {
                TabButton(icon: "sparkles", label: "My Sky", isSelected: selectedTab == .sky) {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { selectedTab = .sky }
                }
                TabButton(icon: "binoculars", label: "Stargazing", isSelected: selectedTab == .stargazing) {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { selectedTab = .stargazing }
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial.opacity(0.9))
            .clipShape(Capsule())
            .padding(.bottom, 28)
            .shadow(color: .black.opacity(0.4), radius: 20, y: 4)
        }
        .ignoresSafeArea()
    }
}

struct TabButton: View {
    let icon: String
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                if isSelected {
                    Text(label)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .trailing)),
                            removal: .opacity
                        ))
                }
            }
            .foregroundStyle(isSelected ? .white : .white.opacity(0.35))
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .background(isSelected ? Color.white.opacity(0.12) : .clear)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isSelected)
    }
}
