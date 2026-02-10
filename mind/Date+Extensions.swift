//
//  Date+Extensions.swift
//  MindShelf
//
//  Created by Murat on 10.02.2026.
//

import Foundation

extension Date {
    func relativeDisplayString(language: String = "en") -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        formatter.dateTimeStyle = .named
        
        // Note: For multi-language, you'd set formatter.locale
        // For now, we use the system locale or pass it in
        
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}
