//
//  CosmosApp.swift
//  Cosmos
//
//  Created by stephleung ü on 12/03/2026.
//

import SwiftUI
import CoreText

@main
struct CosmosApp: App {
    @StateObject private var supabaseService = SupabaseService()
    @StateObject private var store: SupabaseExperimentStore

    init() {
        Self.registerFonts()
        let service = SupabaseService()
        _supabaseService = StateObject(wrappedValue: service)
        _store = StateObject(wrappedValue: SupabaseExperimentStore(supabaseService: service))
    }

    private static func registerFonts() {
        for name in ["BalooBhai2-Regular", "BalooBhai2-SemiBold"] {
            guard let url = Bundle.main.url(forResource: name, withExtension: "ttf") else { continue }
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environmentObject(store)
                .environmentObject(supabaseService)
                .preferredColorScheme(.light)
        }
    }
}

struct AppRootView: View {
    @EnvironmentObject var supabaseService: SupabaseService
    @AppStorage("hasSkippedAuth") private var hasSkippedAuth = false

    var body: some View {
        if supabaseService.isAuthenticated || hasSkippedAuth {
            RootView()
        } else {
            AuthView(hasSkippedAuth: $hasSkippedAuth)
        }
    }
}
