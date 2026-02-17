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

    static var isConfigured: Bool {
        supabaseURL != nil && supabaseAnonKey != nil
    }

    static let supabaseURL: URL? = {
        guard let raw = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String else {
            return nil
        }
        let urlString = sanitized(raw)
        guard !urlString.hasPrefix("$("), let url = URL(string: urlString), let host = url.host, !host.isEmpty else {
            return nil
        }
        return url
    }()

    static let supabaseAnonKey: String? = {
        guard let raw = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String else {
            return nil
        }
        let key = sanitized(raw)
        guard !key.hasPrefix("$("), !key.isEmpty else {
            return nil
        }
        return key
    }()
}
