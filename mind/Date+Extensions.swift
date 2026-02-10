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
        formatter.locale = Locale(identifier: language)
        
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}
