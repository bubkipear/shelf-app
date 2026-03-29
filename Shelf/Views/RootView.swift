import SwiftUI

struct RootView: View {
    @State private var selectedTab = 1

    var body: some View {
        TabView(selection: $selectedTab) {
            AbandonedView(selectedTab: $selectedTab)
                .tag(0)
            MyShelfView(selectedTab: $selectedTab)
                .tag(1)
            CompletedView(selectedTab: $selectedTab)
                .tag(2)
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .ignoresSafeArea()
    }
}
