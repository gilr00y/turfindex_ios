//
//  OnboardingView.swift
//  grassy
//
//  Created by jason on 1/14/26.
//

import SwiftUI

struct OnboardingView: View {
    @Environment(AppState.self) private var appState
    @State private var isSignUp = true
    @State private var email = ""
    @State private var password = ""
    @State private var username = ""
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        ZStack {
            // Dark navy background
            TurfTheme.navyBackground
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                Spacer()
                
                // App branding with logo
                VStack(spacing: 20) {
                    // Logo - using no-bg version for navy background
                    Image("turf-index-no-bg")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 200, height: 200)
                        .padding(.bottom, 10)
                    
                    Text(isSignUp ? "Join the community" : "Welcome back!")
                        .font(.title2)
                        .foregroundStyle(.white)
                }
                
                Spacer()
                
                // Auth form
                VStack(alignment: .leading, spacing: 16) {
                    if isSignUp {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Username")
                                .font(.headline)
                                .foregroundStyle(.white)
                            
                            TextField("Choose a username", text: $username)
                                .textFieldStyle(.roundedBorder)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email")
                            .font(.headline)
                            .foregroundStyle(.white)
                        
                        TextField("email@example.com", text: $email)
                            .textFieldStyle(.roundedBorder)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .keyboardType(.emailAddress)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Password")
                            .font(.headline)
                            .foregroundStyle(.white)
                        
                        SecureField("Enter password", text: $password)
                            .textFieldStyle(.roundedBorder)
                    }
                    
                    if showError {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .padding(.top, 4)
                    }
                }
                .padding(.horizontal, 40)
                
                // Action button
                Button(action: handleAuth) {
                    if appState.isLoading {
                        ProgressView()
                            .tint(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else {
                        Text(isSignUp ? "Sign Up" : "Sign In")
                    }
                }
                .buttonStyle(.turfPrimary)
                .padding(.horizontal, 40)
                .disabled(isFormInvalid || appState.isLoading)
                
                // Toggle sign up/sign in
                Button {
                    isSignUp.toggle()
                    showError = false
                } label: {
                    Text(isSignUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                        .font(.subheadline)
                        .foregroundStyle(TurfTheme.primary)
                }
                
                Spacer()
            }
            .padding()
        }
    }
    
    private var isFormInvalid: Bool {
        if isSignUp {
            return email.isEmpty || password.isEmpty || username.isEmpty
        } else {
            return email.isEmpty || password.isEmpty
        }
    }
    
    private func handleAuth() {
        showError = false
        
        Task {
            if isSignUp {
                await appState.signUp(email: email, password: password, username: username)
            } else {
                await appState.signIn(email: email, password: password)
            }
        }
    }
}

#Preview {
    OnboardingView()
        .environment(AppState())
}
