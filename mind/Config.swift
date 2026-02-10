//
//  Config.swift
//  MindShelf
//
//  Created by Murat on 8.02.2026.
//  Updated: 2026-02-08 22:11 - Direct credentials
//

import Foundation

enum Config {
    private static func sanitized(_ value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "\""))
    }
    
    static let supabaseURL: URL = {
        guard let raw = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String else {
            fatalError("SUPABASE_URL not found in Info.plist")
        }
        let urlString = sanitized(raw)
        guard let url = URL(string: urlString), let host = url.host, !host.isEmpty else {
            fatalError("Invalid SUPABASE_URL. Ensure Config.xcconfig has full https://... (wrap in quotes if needed).")
        }
        return url
    }()
    
    static let supabaseAnonKey: String = {
        guard let raw = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String else {
            fatalError("SUPABASE_ANON_KEY not found in Info.plist")
        }
        let key = sanitized(raw)
        guard !key.isEmpty else {
            fatalError("SUPABASE_ANON_KEY not found in Info.plist")
        }
        return key
    }()
}
