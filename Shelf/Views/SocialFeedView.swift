import SwiftUI

struct SocialFeedView: View {
    @EnvironmentObject var store: SupabaseExperimentStore
    @State private var appeared = false
    
    private let cream = Color(red: 0.98, green: 0.96, blue: 0.93)
    private let graphite = Color(red: 0.25, green: 0.23, blue: 0.22)
    private let shelfLine = Color(red: 0.72, green: 0.68, blue: 0.63)
    
    var body: some View {
        ZStack {
            cream.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 0) {
                    // Header
                    VStack(alignment: .leading, spacing: 4) {
                        Text("DISCOVER")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .tracking(2.5)
                            .foregroundStyle(graphite.opacity(0.35))
                        Text("\(store.communityExperiments.count) experiments from the community")
                            .font(.system(size: 14, weight: .regular, design: .rounded))
                            .foregroundStyle(graphite.opacity(0.5))
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    .padding(.bottom, 32)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Loading State
                    if store.isLoading {
                        VStack(spacing: 16) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: graphite))
                            Text("Loading experiments...")
                                .font(.system(size: 14, design: .rounded))
                                .foregroundStyle(graphite.opacity(0.5))
                        }
                        .padding(.top, 60)
                    }
                    // Empty State
                    else if store.communityExperiments.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "globe.badge.chevron.backward")
                                .font(.system(size: 36, weight: .thin))
                                .foregroundStyle(graphite.opacity(0.2))
                            Text("No community experiments yet")
                                .font(.system(size: 18, weight: .light, design: .rounded))
                                .foregroundStyle(graphite.opacity(0.4))
                            Text("Be the first to share your experiments!")
                                .font(.system(size: 13, design: .rounded))
                                .foregroundStyle(graphite.opacity(0.25))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 60)
                    }
                    // Experiments Feed
                    else {
                        ForEach(Array(store.communityExperiments.enumerated()), id: \.element.id) { index, experiment in
                            CommunityExperimentCard(experiment: experiment)
                                .padding(.horizontal, 24)
                                .padding(.bottom, 20)
                                .opacity(appeared ? 1 : 0)
                                .scaleEffect(appeared ? 1 : 0.8)
                                .animation(
                                    .spring(response: 0.6, dampingFraction: 0.8)
                                        .delay(Double(index) * 0.05),
                                    value: appeared
                                )
                        }
                    }
                    
                    Spacer(minLength: 100)
                }
            }
            .refreshable {
                store.loadCommunityExperiments()
            }
        }
        .onAppear {
            appeared = true
            if store.communityExperiments.isEmpty {
                store.loadCommunityExperiments()
            }
        }
    }
}

// MARK: - Community Experiment Card

struct CommunityExperimentCard: View {
    let experiment: Experiment
    @EnvironmentObject var store: SupabaseExperimentStore
    @State private var isOrbitSheetPresented = false
    
    private let cream = Color(red: 0.98, green: 0.96, blue: 0.93)
    private let graphite = Color(red: 0.25, green: 0.23, blue: 0.22)
    private let shelfLine = Color(red: 0.72, green: 0.68, blue: 0.63)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with author info
            HStack(spacing: 12) {
                // Author avatar placeholder
                Circle()
                    .fill(graphite.opacity(0.1))
                    .frame(width: 32, height: 32)
                    .overlay(
                        Text("A") // Could be first initial of author name
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundStyle(graphite.opacity(0.5))
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Anonymous") // Could pull from experiment.author?.displayName
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(graphite.opacity(0.7))
                    
                    Text(timeAgoString(from: experiment.startDate))
                        .font(.system(size: 11, weight: .regular, design: .rounded))
                        .foregroundStyle(graphite.opacity(0.4))
                }
                
                Spacer()
                
                // Like button
                Button {
                    store.likeExperiment(experiment)
                } label: {
                    Image(systemName: "heart")
                        .font(.system(size: 16, weight: .light))
                        .foregroundStyle(graphite.opacity(0.4))
                }
            }
            
            // Experiment content
            HStack(alignment: .top, spacing: 16) {
                // Object representation
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.white.opacity(0.9))
                        .frame(width: 60, height: 60)
                        .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
                    
                    Image(systemName: experiment.iconPreset.rawValue)
                        .font(.system(size: 24, weight: .thin))
                        .foregroundStyle(graphite.opacity(0.6))
                }
                .opacity(experiment.brightness)
                .rotationEffect(.degrees(experiment.tiltDegrees * 0.3))
                
                // Experiment details
                VStack(alignment: .leading, spacing: 8) {
                    Text(experiment.name)
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundStyle(graphite.opacity(0.85))
                    
                    if let intention = experiment.intention {
                        Text(intention)
                            .font(.system(size: 14, weight: .regular, design: .rounded))
                            .foregroundStyle(graphite.opacity(0.55))
                            .lineLimit(3)
                    }
                    
                    // Stats
                    HStack(spacing: 16) {
                        StatView(
                            value: "\(experiment.totalCheckIns)",
                            label: "check-ins"
                        )
                        
                        if experiment.currentStreakDays > 0 {
                            StatView(
                                value: "\(experiment.currentStreakDays)",
                                label: "day streak"
                            )
                        }
                        
                        StatView(
                            value: "\(experiment.daysSinceStart)",
                            label: "days running"
                        )
                    }
                }
                
                Spacer()
            }
            
            // Action button
            Button {
                isOrbitSheetPresented = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle")
                        .font(.system(size: 14, weight: .light))
                    Text("Try This")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                }
                .foregroundStyle(graphite.opacity(0.6))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(cream)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(graphite.opacity(0.15), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
        .padding(20)
        .background(Color.white.opacity(0.6))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(shelfLine.opacity(0.3), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .sheet(isPresented: $isOrbitSheetPresented) {
            OrbitExperimentSheet(experiment: experiment)
                .environmentObject(store)
        }
    }
    
    private func timeAgoString(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Stat View

struct StatView: View {
    let value: String
    let label: String
    
    private let graphite = Color(red: 0.25, green: 0.23, blue: 0.22)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(graphite.opacity(0.7))
            Text(label)
                .font(.system(size: 10, weight: .regular, design: .rounded))
                .foregroundStyle(graphite.opacity(0.4))
        }
    }
}

// MARK: - Orbit Experiment Sheet

struct OrbitExperimentSheet: View {
    let experiment: Experiment
    @EnvironmentObject var store: SupabaseExperimentStore
    @Environment(\.dismiss) var dismiss
    
    private let cream = Color(red: 0.98, green: 0.96, blue: 0.93)
    private let graphite = Color(red: 0.25, green: 0.23, blue: 0.22)
    
    var body: some View {
        NavigationView {
            ZStack {
                cream.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Experiment preview
                        VStack(spacing: 16) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.white.opacity(0.9))
                                    .frame(width: 80, height: 80)
                                    .shadow(color: .black.opacity(0.1), radius: 6, x: 0, y: 3)
                                
                                Image(systemName: experiment.iconPreset.rawValue)
                                    .font(.system(size: 32, weight: .thin))
                                    .foregroundStyle(graphite.opacity(0.7))
                            }
                            
                            VStack(spacing: 8) {
                                Text(experiment.name)
                                    .font(.system(size: 20, weight: .medium, design: .rounded))
                                    .foregroundStyle(graphite)
                                    .multilineTextAlignment(.center)
                                
                                if let intention = experiment.intention {
                                    Text(intention)
                                        .font(.system(size: 15, weight: .regular, design: .rounded))
                                        .foregroundStyle(graphite.opacity(0.6))
                                        .multilineTextAlignment(.center)
                                }
                            }
                        }
                        .padding(.top, 20)
                        
                        // Info
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Starting this experiment will:")
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                .foregroundStyle(graphite.opacity(0.8))
                            
                            VStack(alignment: .leading, spacing: 12) {
                                InfoRow(
                                    icon: "plus.circle",
                                    title: "Add it to your shelf",
                                    description: "You'll have your own copy to track"
                                )
                                InfoRow(
                                    icon: "calendar",
                                    title: "Reset the start date",
                                    description: "Begin fresh from today"
                                )
                                InfoRow(
                                    icon: "chart.line.uptrend.xyaxis",
                                    title: "Track your progress",
                                    description: "Build your own check-in history"
                                )
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Spacer(minLength: 40)
                        
                        // Action Button
                        Button {
                            store.orbitCommunityExperiment(experiment)
                            dismiss()
                        } label: {
                            Text("Start This Experiment")
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                .foregroundStyle(cream)
                                .frame(maxWidth: .infinity, minHeight: 44)
                                .background(graphite)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                    .padding(24)
                }
            }
            .navigationTitle("Try Experiment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(graphite.opacity(0.6))
                }
            }
        }
    }
}

// MARK: - Info Row

struct InfoRow: View {
    let icon: String
    let title: String
    let description: String
    
    private let graphite = Color(red: 0.25, green: 0.23, blue: 0.22)
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .light))
                .foregroundStyle(graphite.opacity(0.5))
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(graphite.opacity(0.8))
                
                Text(description)
                    .font(.system(size: 13, weight: .regular, design: .rounded))
                    .foregroundStyle(graphite.opacity(0.5))
            }
        }
    }
}

// MARK: - Preview

#Preview {
    SocialFeedView()
        .environmentObject(SupabaseExperimentStore(supabaseService: SupabaseService()))
}