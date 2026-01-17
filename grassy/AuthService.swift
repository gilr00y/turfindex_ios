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
        
        // Create profile with username
        let profile = UserProfile(
            id: user.id.uuidString,
            username: username,
            createdAt: Date()
        )
        
        try await client
            .from(Tables.profiles)
            .insert(profile)
            .execute()
        
        return profile
    }
    
    /// Sign in with email and password
    func signIn(email: String, password: String) async throws -> UserProfile {
        let session = try await client.auth.signIn(
            email: email,
            password: password
        )
        
        guard let userId = session.user.id.uuidString as String? else {
            throw AuthError.signInFailed
        }
        
        // Fetch user profile
        let profile: UserProfile = try await client
            .from(Tables.profiles)
            .select()
            .eq("id", value: userId)
            .single()
            .execute()
            .value
        
        return profile
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
}

enum AuthError: LocalizedError {
    case signUpFailed
    case signInFailed
    case invalidCredentials
    case usernameTaken
    case networkError
    
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
        }
    }
}
