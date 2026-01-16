//
//  SupabaseConfig.swift
//  grassy
//
//  Created by jason on 1/14/26.
//

import Foundation
import Supabase

/// Configuration for Supabase client
enum SupabaseConfig {
    // TODO: Replace with your Supabase project credentials
    static let url = URL(string: "https://your-project.supabase.co")!
    static let anonKey = "your-anon-key-here"
    
    static let client = SupabaseClient(
        supabaseURL: url,
        supabaseKey: anonKey
    )
}

/// Configuration for Digital Ocean Spaces (S3-compatible)
enum SpacesConfig {
    // TODO: Replace with your Digital Ocean Spaces credentials
    static let endpoint = "https://nyc3.digitaloceanspaces.com"
    static let region = "nyc3"
    static let bucket = "grassy-photos"
    static let accessKey = "your-access-key"
    static let secretKey = "your-secret-key"
    
    // Public URL for uploaded photos
    static func photoURL(for key: String) -> URL? {
        URL(string: "\(endpoint)/\(bucket)/\(key)")
    }
}
