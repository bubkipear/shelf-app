import SwiftUI

struct AuthView: View {
    @EnvironmentObject var supabaseService: SupabaseService
    @Binding var hasSkippedAuth: Bool
    @State private var email = ""
    @State private var password = ""
    @State private var displayName = ""
    @State private var isSigningUp = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    private let cream = Color(red: 0.98, green: 0.96, blue: 0.93)
    private let graphite = Color(red: 0.25, green: 0.23, blue: 0.22)
    
    var body: some View {
        ZStack {
            cream.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 32) {
                    Spacer(minLength: 60)
                    
                    // Header
                    VStack(spacing: 16) {
                        VStack(spacing: 8) {
                            Text("🗂️")
                                .font(.system(size: 64))
                            Text("SHELF")
                                .font(.system(size: 28, weight: .light, design: .serif))
                                .tracking(8)
                                .foregroundStyle(graphite)
                        }
                        
                        Text("Your life experiments,\nbeautifully organized")
                            .font(.system(size: 16, weight: .regular, design: .rounded))
                            .multilineTextAlignment(.center)
                            .foregroundStyle(graphite.opacity(0.7))
                    }
                    .padding(.bottom, 20)
                    
                    // Auth Form
                    VStack(spacing: 20) {
                        if isSigningUp {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("DISPLAY NAME")
                                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                                    .foregroundStyle(graphite.opacity(0.4))
                                    .tracking(1)
                                
                                TextField("What should we call you?", text: $displayName)
                                    .textFieldStyle(ShelfTextFieldStyle())
                                    .textContentType(.name)
                                    .autocapitalization(.words)
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("EMAIL")
                                .font(.system(size: 10, weight: .semibold, design: .rounded))
                                .foregroundStyle(graphite.opacity(0.4))
                                .tracking(1)
                            
                            TextField("your@email.com", text: $email)
                                .textFieldStyle(ShelfTextFieldStyle())
                                .textContentType(.emailAddress)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("PASSWORD")
                                .font(.system(size: 10, weight: .semibold, design: .rounded))
                                .foregroundStyle(graphite.opacity(0.4))
                                .tracking(1)
                            
                            SecureField("••••••••", text: $password)
                                .textFieldStyle(ShelfTextFieldStyle())
                                .textContentType(isSigningUp ? .newPassword : .password)
                        }
                        
                        if let error = errorMessage {
                            Text(error)
                                .font(.system(size: 13, weight: .regular, design: .rounded))
                                .foregroundStyle(.red)
                                .multilineTextAlignment(.center)
                        }
                        
                        // Action Button
                        Button {
                            Task { await handleAuth() }
                        } label: {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: cream))
                                        .scaleEffect(0.8)
                                } else {
                                    Text(isSigningUp ? "Create Account" : "Sign In")
                                        .font(.system(size: 16, weight: .medium, design: .rounded))
                                }
                            }
                            .foregroundStyle(cream)
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .background(graphite)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .disabled(isLoading || email.isEmpty || password.isEmpty || (isSigningUp && displayName.isEmpty))
                        .opacity(formIsValid ? 1.0 : 0.6)
                        
                        // Toggle Auth Mode
                        Button {
                            isSigningUp.toggle()
                            errorMessage = nil
                        } label: {
                            HStack(spacing: 4) {
                                Text(isSigningUp ? "Already have an account?" : "Need an account?")
                                    .foregroundStyle(graphite.opacity(0.6))
                                Text(isSigningUp ? "Sign in" : "Sign up")
                                    .foregroundStyle(graphite)
                                    .fontWeight(.medium)
                            }
                            .font(.system(size: 14, design: .rounded))
                        }
                        .padding(.top, 8)
                    }
                    .padding(.horizontal, 24)
                    
                    // Continue Without Account (Limited)
                    VStack(spacing: 12) {
                        Text("or")
                            .font(.system(size: 13, weight: .regular, design: .rounded))
                            .foregroundStyle(graphite.opacity(0.4))
                        
                        Button("Continue Without Account") {
                            hasSkippedAuth = true
                        }
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundStyle(graphite.opacity(0.6))
                    }
                    .padding(.top, 20)
                    
                    Spacer(minLength: 40)
                }
            }
        }
    }
    
    private var formIsValid: Bool {
        !email.isEmpty && !password.isEmpty && (isSigningUp ? !displayName.isEmpty : true)
    }
    
    private func handleAuth() async {
        guard formIsValid else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            if isSigningUp {
                let _ = try await supabaseService.signUp(
                    email: email,
                    password: password,
                    displayName: displayName
                )
            } else {
                let _ = try await supabaseService.signIn(
                    email: email,
                    password: password
                )
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}

// MARK: - Custom Text Field Style

struct ShelfTextFieldStyle: TextFieldStyle {
    private let graphite = Color(red: 0.25, green: 0.23, blue: 0.22)
    
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .font(.system(size: 16, weight: .regular, design: .rounded))
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color.white.opacity(0.8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(graphite.opacity(0.1), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Preview

#Preview {
    AuthView(hasSkippedAuth: .constant(false))
        .environmentObject(SupabaseService())
}