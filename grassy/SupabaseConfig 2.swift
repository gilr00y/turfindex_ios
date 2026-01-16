//
//  SupabaseConfig.swift
//  grassy
//
//  Created by jason on 1/14/26.
//

import Foundation
import Supabase

/// Supabase configuration and client setup
struct SupabaseConfig {
    // TODO: Replace with your actual Supabase project URL and anon key
    static let supabaseURL = URL(string: "https://your-project.supabase.co")!
    static let supabaseAnonKey = "your-anon-key-here"
    
    // Digital Ocean Spaces configuration (S3-compatible)
    // TODO: Replace with your Digital Ocean Spaces credentials
    static let spacesEndpoint = "https://your-region.digitaloceanspaces.com"
    static let spacesRegion = "nyc3" // e.g., nyc3, sfo3, etc.
    static let spacesBucket = "grassy-photos"
    static let spacesAccessKey = "your-access-key"
    static let spacesSecretKey = "your-secret-key"
    
    static let client = SupabaseClient(
        supabaseURL: supabaseURL,
        supabaseKey: supabaseAnonKey
    )
}

/// Extension to access the Supabase client easily
extension SupabaseClient {
    static var shared: SupabaseClient {
        SupabaseConfig.client
    }
}
