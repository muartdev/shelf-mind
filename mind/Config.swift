//
//  Config.swift
//  MindShelf
//
//  Created by Murat on 8.02.2026.
//  Updated: 2026-02-08 22:11 - Direct credentials
//

import Foundation

enum Config {
    // TEMPORARY: Hardcoded credentials for debugging
    // TODO: Fix xcconfig integration later
    
    static let supabaseURL: URL = {
        let urlString = "https://bhrukmualirlkapcdiso.supabase.co"
        guard let url = URL(string: urlString) else {
            fatalError("Invalid Supabase URL: \(urlString)")
        }
        print("✅ CONFIG: Using URL: \(urlString)")
        return url
    }()
    
    static let supabaseAnonKey: String = {
        let key = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJocnVrbXVhbGlybGthcGNkaXNvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzA1Njk1MTAsImV4cCI6MjA4NjE0NTUxMH0.oOniwkM8mCcPCP8chrTxeTdNBMVqqbnoQtTbnuEMO3I"
        print("✅ CONFIG: Using key: \(key.prefix(20))...")
        return key
    }()
}
