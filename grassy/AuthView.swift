//
//  AuthView.swift
//  grassy
//
//  Created by jason on 1/14/26.
//

import SwiftUI

struct AuthView: View {
    @Environment(AppState.self) private var appState
    @State private var isSignUp = true
    @State private var email = ""
    @State private var password = ""
    @State private var username = ""
    @State private var errorMessage: String?
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // App branding
            Image(systemName: "photo.stack.fill")
                .font(.system(size: 80))
                .foregroundStyle(.green.gradient)
            
            Text("Welcome to Grassy")
                .font(.largeTitle.bold())
            
            Text("Share your moments with the world")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Spacer()
            
            // Auth form
            VStack(spacing: 16) {
                if isSignUp {
                    TextField("Username", text: $username)
                        .textFieldStyle(.roundedBorder)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
                
                TextField("Email", text: $email)
                    .textFieldStyle(.roundedBorder)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.emailAddress)
                
                SecureField("Password", text: $password)
                    .textFieldStyle(.roundedBorder)
                    .submitLabel(.done)
                    .onSubmit(authenticate)
                
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(.horizontal, 40)
            
            Button(action: authenticate) {
                if appState.isLoading {
                    ProgressView()
                        .tint(.white)
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
            .disabled(appState.isLoading || !isValidInput)
            
            Button {
                withAnimation {
                    isSignUp.toggle()
                    errorMessage = nil
                }
            } label: {
                Text(isSignUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                    .font(.subheadline)
                    .foregroundStyle(.green)
            }
            
            Spacer()
        }
        .padding()
    }
    
    private var isValidInput: Bool {
        !email.isEmpty && password.count >= 6 && (isSignUp ? !username.isEmpty : true)
    }
    
    private func authenticate() {
        errorMessage = nil
        
        Task {
            do {
                if isSignUp {
                    try await appState.signUp(email: email, password: password, username: username)
                } else {
                    try await appState.signIn(email: email, password: password)
                }
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

#Preview {
    AuthView()
        .environment(AppState())
}
