//
//  SupabaseConfig-Template.swift
//  grassy
//
//  INSTRUCTIONS:
//  1. Rename this file to "SupabaseConfig.swift"
//  2. Fill in your actual credentials below
//  3. Never commit SupabaseConfig.swift to git
//

import Foundation
import Supabase

/// Configuration for Supabase client
enum SupabaseConfig {
    // Get these from your Supabase project settings
    // URL format: https://your-project-ref.supabase.co
    static let url = URL(string: "https://your-project.supabase.co")!
    
    // This is your public anon key (safe to use in client apps)
    static let anonKey = "your-anon-key-here"
    
    static let client = SupabaseClient(
        supabaseURL: url,
        supabaseKey: anonKey
    )
}

/// Configuration for Digital Ocean Spaces (S3-compatible)
enum SpacesConfig {
    // Digital Ocean Spaces endpoint
    // Format: https://{region}.digitaloceanspaces.com
    // Regions: nyc3, sfo3, ams3, sgp1, fra1, etc.
    static let endpoint = "https://nyc3.digitaloceanspaces.com"
    static let region = "nyc3"
    
    // Your Space name
    static let bucket = "grassy-photos"
    
    // Digital Ocean Spaces API credentials
    // Generate at: https://cloud.digitalocean.com/account/api/tokens
    static let accessKey = "your-access-key"
    static let secretKey = "your-secret-key"
    
    // Public URL for uploaded photos
    static func photoURL(for key: String) -> URL? {
        // For public Spaces, use the CDN endpoint
        URL(string: "\(endpoint)/\(bucket)/\(key)")
        
        // Alternative: Use custom domain if configured
        // URL(string: "https://cdn.yourdomain.com/\(key)")
    }
}
