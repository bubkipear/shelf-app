import SwiftUI

struct AbandonedView: View {
    @EnvironmentObject var store: SupabaseExperimentStore

    private let bg       = Color(red: 245/255, green: 238/255, blue: 232/255)
    private let inkDark  = Color(red: 44/255,  green: 44/255,  blue: 42/255)
    private let inkMuted = Color(red: 154/255, green: 145/255, blue: 136/255)

    private var abandoned: [Experiment] {
        store.myExperiments.filter { $0.status == .abandoned }
    }

    var body: some View {
        ZStack {
            bg.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                Text("ABANDONED")
                    .font(.custom("BalooBhai2-SemiBold", size: 12))
                    .tracking(2.5)
                    .foregroundColor(inkDark)
                    .padding(.top, 60)
                    .padding(.bottom, 4)

                Text("experiments you let go")
                    .font(.custom("BalooBhai2-Regular", size: 12))
                    .foregroundColor(inkMuted)

                if abandoned.isEmpty {
                    Spacer()
                    Text("Nothing here yet")
                        .font(.custom("BalooBhai2-Regular", size: 16))
                        .foregroundColor(inkMuted)
                    Spacer()
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 12) {
                            ForEach(abandoned) { exp in
                                HStack {
                                    Image(systemName: exp.iconPreset.rawValue)
                                        .font(.system(size: 18, weight: .light))
                                        .foregroundColor(inkMuted)
                                        .frame(width: 36)
                                    Text(exp.name)
                                        .font(.custom("BalooBhai2-Regular", size: 15))
                                        .foregroundColor(inkDark)
                                    Spacer()
                                }
                                .padding(.horizontal, 24)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(red: 237/255, green: 231/255, blue: 223/255))
                                )
                                .padding(.horizontal, 20)
                            }
                        }
                        .padding(.top, 24)
                        .padding(.bottom, 40)
                    }
                }
            }
        }
    }
}
