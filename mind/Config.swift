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
            preconditionFailure("SUPABASE_URL not found. Add Config.xcconfig and link it in Build Settings.")
        }
        let urlString = sanitized(raw)
        guard !urlString.hasPrefix("$("), let url = URL(string: urlString), let host = url.host, !host.isEmpty else {
            preconditionFailure("Invalid SUPABASE_URL. Check Config.xcconfig has SUPABASE_URL with full https://... URL.")
        }
        return url
    }()
    
    static let supabaseAnonKey: String = {
        guard let raw = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String else {
            preconditionFailure("SUPABASE_ANON_KEY not found. Add Config.xcconfig and link it in Build Settings.")
        }
        let key = sanitized(raw)
        guard !key.hasPrefix("$("), !key.isEmpty else {
            preconditionFailure("Invalid SUPABASE_ANON_KEY. Check Config.xcconfig has your project's anon key.")
        }
        return key
    }()
}
