//
//  AuthDebugView.swift
//  grassy
//
//  Created by jason on 1/18/26.
//

import SwiftUI
import Auth
import Supabase

#if DEBUG
/// Debug view for testing authentication
struct AuthDebugView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var username = ""
    @State private var result = ""
    @State private var isLoading = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Test Credentials") {
                    TextField("Email", text: $email)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                    
                    SecureField("Password", text: $password)
                    
                    TextField("Username", text: $username)
                        .textInputAutocapitalization(.never)
                }
                
                Section("Actions") {
                    Button("Test Sign Up") {
                        testSignUp()
                    }
                    .disabled(isLoading)
                    
                    Button("Test Sign In") {
                        testSignIn()
                    }
                    .disabled(isLoading)
                    
                    Button("Check Current Session") {
                        checkSession()
                    }
                    .disabled(isLoading)
                    
                    Button("Fix Orphaned Account") {
                        fixOrphanedAccount()
                    }
                    .disabled(isLoading)
                    
                    Button("Test Sign Out") {
                        testSignOut()
                    }
                    .disabled(isLoading)
                }
                
                if !result.isEmpty {
                    Section("Result") {
                        Text(result)
                            .font(.caption)
                            .monospaced()
                    }
                }
                
                Section("Supabase Status") {
                    LabeledContent("URL", value: SupabaseConfig.url.absoluteString)
                    LabeledContent("Key", value: String(SupabaseConfig.anonKey.prefix(20)) + "...")
                }
            }
            .navigationTitle("Auth Debug")
            .overlay {
                if isLoading {
                    ProgressView()
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }
    
    private func testSignUp() {
        Task {
            isLoading = true
            result = ""
            
            do {
                let profile = try await AuthService.shared.signUp(
                    email: email,
                    password: password,
                    username: username
                )
                result = """
                ✅ Sign Up Successful!
                
                User ID: \(profile.id)
                Username: @\(profile.username)
                Created: \(profile.createdAt.formatted())
                
                ⚠️ Check Supabase Dashboard:
                1. Authentication → Users
                2. Look for: \(email)
                3. Check if email is confirmed
                """
            } catch {
                result = """
                ❌ Sign Up Failed
                
                Error: \(error.localizedDescription)
                
                Details: \(error)
                
                💡 Common Issues:
                • Username already taken
                • Email already registered
                • Password too weak (min 6 chars)
                • Network connection
                """
            }
            
            isLoading = false
        }
    }
    
    private func testSignIn() {
        Task {
            isLoading = true
            result = ""
            
            do {
                let profile = try await AuthService.shared.signIn(
                    email: email,
                    password: password
                )
                result = """
                ✅ Sign In Successful!
                
                User ID: \(profile.id)
                Username: @\(profile.username)
                
                Session is active.
                """
            } catch {
                result = """
                ❌ Sign In Failed
                
                Error: \(error.localizedDescription)
                
                Details: \(error)
                
                💡 Common Issues:
                • Email not confirmed (check Supabase)
                • Wrong password
                • Account doesn't exist
                • Profile not created
                
                🔧 Fix:
                1. Go to Supabase Dashboard
                2. Authentication → Users
                3. Find user: \(email)
                4. Click "..." → "Confirm email"
                5. Try signing in again
                
                OR disable email confirmations:
                Authentication → Settings → Email Auth
                → Disable "Enable email confirmations"
                """
            }
            
            isLoading = false
        }
    }
    
    private func checkSession() {
        Task {
            isLoading = true
            result = ""
            
            do {
                if let session = try await AuthService.shared.getCurrentSession() {
                    result = """
                    ✅ Session Active
                    
                    User ID: \(session.user.id.uuidString)
                    Email: \(session.user.email ?? "N/A")
                    Confirmed: \(session.user.confirmedAt != nil ? "Yes" : "No ⚠️")
                    Created: \(session.user.createdAt.formatted())
                    
                    Access Token (first 30 chars):
                    \(String(session.accessToken.prefix(30)))...
                    """
                } else {
                    result = """
                    ℹ️ No Active Session
                    
                    User is not signed in.
                    """
                }
            } catch {
                result = """
                ❌ Session Check Failed
                
                Error: \(error.localizedDescription)
                """
            }
            
            isLoading = false
        }
    }
    
    private func testSignOut() {
        Task {
            isLoading = true
            result = ""
            
            do {
                try await AuthService.shared.signOut()
                result = """
                ✅ Sign Out Successful
                
                Session cleared.
                """
            } catch {
                result = """
                ❌ Sign Out Failed
                
                Error: \(error.localizedDescription)
                """
            }
            
            isLoading = false
        }
    }
    
    private func fixOrphanedAccount() {
        Task {
            isLoading = true
            result = ""
            
            do {
                // First, try to sign in to get the session
                let session = try await SupabaseConfig.client.auth.signIn(
                    email: email,
                    password: password
                )
                
                let userId = session.user.id.uuidString
                
                // Check if profile exists
                let profileExists = try await AuthService.shared.profileExists(for: userId)
                
                if profileExists {
                    result = """
                    ℹ️ Profile Already Exists
                    
                    User ID: \(userId)
                    
                    This is NOT an orphaned account.
                    The sign-in issue is something else.
                    
                    Try using "Check Current Session" to see more details.
                    """
                } else {
                    // Create profile for this user
                    let profile = try await AuthService.shared.createProfileForExistingUser(
                        userId: userId,
                        username: username
                    )
                    
                    result = """
                    ✅ Orphaned Account Fixed!
                    
                    Created profile:
                    User ID: \(profile.id)
                    Username: @\(profile.username)
                    
                    You can now sign in normally!
                    """
                }
            } catch {
                result = """
                ❌ Fix Failed
                
                Error: \(error.localizedDescription)
                
                Details: \(error)
                
                💡 Make sure:
                • Email and password are correct
                • Username is filled in
                • You can sign in to Supabase (email confirmed)
                """
            }
            
            isLoading = false
        }
    }
}

#Preview {
    AuthDebugView()
}
#endif
