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
        VStack(spacing: 30) {
            Spacer()
            
            // App branding
            Image(systemName: "photo.stack.fill")
                .font(.system(size: 80))
                .foregroundStyle(.green.gradient)
            
            Text("Welcome to Grassy")
                .font(.largeTitle.bold())
            
            Text(isSignUp ? "Share your moments with the world" : "Welcome back!")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Spacer()
            
            // Auth form
            VStack(alignment: .leading, spacing: 16) {
                if isSignUp {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Username")
                            .font(.headline)
                        
                        TextField("Choose a username", text: $username)
                            .textFieldStyle(.roundedBorder)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Email")
                        .font(.headline)
                    
                    TextField("email@example.com", text: $email)
                        .textFieldStyle(.roundedBorder)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.emailAddress)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Password")
                        .font(.headline)
                    
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
                        .frame(maxWidth: .infinity)
                        .padding()
                } else {
                    Text(isSignUp ? "Sign Up" : "Sign In")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                }
            }
            .background(.green.gradient)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal, 40)
            .disabled(isFormInvalid || appState.isLoading)
            
            // Toggle sign up/sign in
            Button {
                isSignUp.toggle()
                showError = false
            } label: {
                Text(isSignUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                    .font(.subheadline)
                    .foregroundStyle(.green)
            }
            
            Spacer()
        }
        .padding()
        .onChange(of: appState.error) { oldValue, newValue in
            if let error = newValue {
                errorMessage = error.localizedDescription
                showError = true
            }
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
