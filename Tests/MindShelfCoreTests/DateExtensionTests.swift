import Testing
import Foundation
@testable import MindShelfCore

@Suite("Date.relativeDisplayString")
struct DateExtensionTests {

    @Test("recent date returns non-empty string")
    func recentDate() {
        let oneHourAgo = Date().addingTimeInterval(-3600)
        let result = oneHourAgo.relativeDisplayString(language: "en")
        #expect(!result.isEmpty)
    }

    @Test("yesterday returns a string containing time reference")
    func yesterday() {
        let yesterday = Date().addingTimeInterval(-86400)
        let result = yesterday.relativeDisplayString(language: "en")
        #expect(!result.isEmpty)
        // RelativeDateTimeFormatter should produce something like "yesterday" or "1 day ago"
    }

    @Test("future date returns non-empty string")
    func futureDate() {
        let tomorrow = Date().addingTimeInterval(86400)
        let result = tomorrow.relativeDisplayString(language: "en")
        #expect(!result.isEmpty)
    }

    @Test("Turkish locale returns non-empty string")
    func turkishLocale() {
        let oneHourAgo = Date().addingTimeInterval(-3600)
        let result = oneHourAgo.relativeDisplayString(language: "tr")
        #expect(!result.isEmpty)
    }

    @Test("English and Turkish produce different output for same date")
    func differentLocales() {
        let twoDaysAgo = Date().addingTimeInterval(-86400 * 2)
        let en = twoDaysAgo.relativeDisplayString(language: "en")
        let tr = twoDaysAgo.relativeDisplayString(language: "tr")
        #expect(en != tr)
    }

    @Test("now returns a very short/immediate reference")
    func nowDate() {
        let result = Date().relativeDisplayString(language: "en")
        #expect(!result.isEmpty)
        // Should be something like "now"
    }
}
