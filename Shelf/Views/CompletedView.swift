import SwiftUI

struct CompletedView: View {
    @EnvironmentObject var store: SupabaseExperimentStore

    private let bg       = Color(red: 245/255, green: 238/255, blue: 232/255)
    private let inkDark  = Color(red: 44/255,  green: 44/255,  blue: 42/255)
    private let inkMuted = Color(red: 154/255, green: 145/255, blue: 136/255)
    private let dotGreen = Color(red: 123/255, green: 198/255, blue: 122/255)

    private var completed: [Experiment] {
        store.myExperiments.filter { $0.status == .completed }
    }

    var body: some View {
        ZStack {
            bg.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                Text("COMPLETED")
                    .font(.custom("BalooBhai2-SemiBold", size: 12))
                    .tracking(2.5)
                    .foregroundColor(inkDark)
                    .padding(.top, 60)
                    .padding(.bottom, 4)

                Text("experiments you finished")
                    .font(.custom("BalooBhai2-Regular", size: 12))
                    .foregroundColor(inkMuted)

                if completed.isEmpty {
                    Spacer()
                    Text("Nothing here yet")
                        .font(.custom("BalooBhai2-Regular", size: 16))
                        .foregroundColor(inkMuted)
                    Spacer()
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 12) {
                            ForEach(completed) { exp in
                                HStack {
                                    Image(systemName: exp.iconPreset.rawValue)
                                        .font(.system(size: 18, weight: .light))
                                        .foregroundColor(dotGreen)
                                        .frame(width: 36)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(exp.name)
                                            .font(.custom("BalooBhai2-Regular", size: 15))
                                            .foregroundColor(inkDark)
                                        Text("\(exp.totalCheckIns) check-ins")
                                            .font(.custom("BalooBhai2-Regular", size: 11))
                                            .foregroundColor(inkMuted)
                                    }
                                    Spacer()
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(dotGreen)
                                        .font(.system(size: 18))
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
