//
//  SupabaseConfig.swift
//  grassy
//
//  Created by jason on 1/14/26.
//

import Foundation
import Supabase

/// Supabase configuration and client setup
class SupabaseConfig {
    static let shared = SupabaseConfig()
    
    let client: SupabaseClient
    
    private init() {
        // TODO: Replace with your actual Supabase credentials
        let supabaseURL = URL(string: "https://YOUR_PROJECT_ID.supabase.co")!
        let supabaseKey = "YOUR_SUPABASE_ANON_KEY"
        
        self.client = SupabaseClient(
            supabaseURL: supabaseURL,
            supabaseKey: supabaseKey
        )
    }
}

/// Extension for easy access to Supabase client
extension SupabaseConfig {
    var auth: AuthClient {
        client.auth
    }
    
    var database: DatabaseClient {
        client.database
    }
    
    var storage: StorageClient {
        client.storage
    }
}
