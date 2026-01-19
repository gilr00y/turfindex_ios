//
//  AuthService.swift
//  grassy
//
//  Created by jason on 1/14/26.
//

import Foundation
import Supabase
import Auth

/// Service for handling authentication with Supabase
actor AuthService {
    static let shared = AuthService()
    let currentToken = String()
    
    private let client = SupabaseConfig.client
    
    private init() {}
    
    // MARK: - Authentication
    
    /// Sign up with email and password, then create username
    func signUp(email: String, password: String, username: String) async throws -> UserProfile {
        // Create auth user
        let authResponse = try await client.auth.signUp(
            email: email,
            password: password
        )
        
        let user = authResponse.user
        
        print("✅ Auth user created: \(user.id.uuidString)")
        print("📧 Email: \(user.email ?? "N/A")")
        
        // Create profile with username
        let profile = UserProfile(
            id: user.id.uuidString,
            username: username,
            createdAt: Date()
        )
        
        do {
            try await client
                .from(Tables.profiles)
                .insert(profile)
                .execute()
            
            print("✅ Profile created: @\(username)")
            return profile
            
        } catch {
            print("❌ Failed to create profile: \(error)")
            print("📋 This might mean:")
            print("   - Username already taken")
            print("   - RLS policy blocking insert")
            print("   - Network error")
            throw error
        }
    }
    
    /// Sign in with email and password
    func signIn(email: String, password: String) async throws -> UserProfile {
        do {
            let session = try await client.auth.signIn(
                email: email,
                password: password
            )
            
            let userId = session.user.id.uuidString
            
            print("✅ Sign in successful. User ID: \(userId)")
            print("📧 Email confirmed: \(session.user.confirmedAt != nil)")
            
            // Try to fetch user profile
            do {
                let profile: UserProfile = try await client
                    .from(Tables.profiles)
                    .select()
                    .eq("id", value: userId)
                    .single()
                    .execute()
                    .value
                
                print("✅ Profile fetched: @\(profile.username)")
                return profile
                
            } catch {
                // Profile doesn't exist - this is an orphaned account
                print("⚠️ Profile not found for user \(userId)")
                print("❌ This is an orphaned account (auth user without profile)")
                print("💡 Please use AuthDebugView → 'Fix Orphaned Account' to create the profile")
                
                throw AuthError.profileNotFound
            }
            
        } catch AuthError.profileNotFound {
            // Re-throw our custom error
            throw AuthError.profileNotFound
            
        } catch {
            print("❌ Sign in error: \(error)")
            print("📋 Error details: \(error.localizedDescription)")
            
            // Provide more specific error messages
            if let authError = error as? AuthError {
                throw authError
            }
            
            throw AuthError.signInFailed
        }
    }
    
    /// Sign out current user
    func signOut() async throws {
        try await client.auth.signOut()
    }
    
    /// Get current session
    func getCurrentSession() async throws -> Session? {
        try await client.auth.session
    }
    
    /// Get current user profile
    func getCurrentUserProfile() async throws -> UserProfile? {
        let session = try await client.auth.session
        
        let userId = session.user.id.uuidString
        
        let profile: UserProfile = try await client
            .from(Tables.profiles)
            .select()
            .eq("id", value: userId)
            .single()
            .execute()
            .value
        
        return profile
    }
    
    /// Check if username is available
    func isUsernameAvailable(_ username: String) async throws -> Bool {
        let response = try await client
            .from(Tables.profiles)
            .select("username")
            .eq("username", value: username)
            .execute()
        
        // If we get data back, username is taken
        return response.data.isEmpty
    }
    
    /// Update username
    func updateUsername(_ username: String, userId: String) async throws {
        try await client
            .from(Tables.profiles)
            .update(["username": username])
            .eq("id", value: userId)
            .execute()
    }
    
    /// Check if profile exists for a user ID
    func profileExists(for userId: String) async throws -> Bool {
        do {
            let _: UserProfile = try await client
                .from(Tables.profiles)
                .select()
                .eq("id", value: userId)
                .single()
                .execute()
                .value
            return true
        } catch {
            return false
        }
    }
    
    /// Create profile for existing auth user (for fixing orphaned accounts)
    func createProfileForExistingUser(userId: String, username: String) async throws -> UserProfile {
        let profile = UserProfile(
            id: userId,
            username: username,
            createdAt: Date()
        )
        
        try await client
            .from(Tables.profiles)
            .insert(profile)
            .execute()
        
        print("✅ Profile created for existing user: @\(username)")
        return profile
    }
}

enum AuthError: LocalizedError {
    case signUpFailed
    case signInFailed
    case invalidCredentials
    case usernameTaken
    case networkError
    case profileNotFound
    
    var errorDescription: String? {
        switch self {
        case .signUpFailed:
            return "Failed to create account"
        case .signInFailed:
            return "Failed to sign in"
        case .invalidCredentials:
            return "Invalid email or password"
        case .usernameTaken:
            return "Username is already taken"
        case .networkError:
            return "Network error. Please try again."
        case .profileNotFound:
            return "Account profile not found. Please contact support or use 'Fix Orphaned Account' in debug tools."
        }
    }
}
