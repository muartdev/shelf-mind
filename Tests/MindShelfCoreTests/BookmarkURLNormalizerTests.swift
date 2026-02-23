import Testing
import Foundation
@testable import MindShelfCore

// MARK: - normalizedURLString

@Suite("BookmarkURLNormalizer.normalizedURLString")
struct NormalizedURLStringTests {

    @Test("strips www prefix")
    func stripWWW() {
        let result = BookmarkURLNormalizer.normalizedURLString("https://www.example.com/page")
        #expect(result == "https://example.com/page")
    }

    @Test("lowercases host")
    func lowercaseHost() {
        let result = BookmarkURLNormalizer.normalizedURLString("https://EXAMPLE.COM/Path")
        #expect(result == "https://example.com/Path")
    }

    @Test("removes trailing slash")
    func removeTrailingSlash() {
        let result = BookmarkURLNormalizer.normalizedURLString("https://example.com/page/")
        #expect(result == "https://example.com/page")
    }

    @Test("preserves root slash or strips it")
    func preserveRootSlash() {
        let result = BookmarkURLNormalizer.normalizedURLString("https://example.com/")
        // Root "/" may be stripped (path.count == 1 check) — either form is valid
        #expect(result == "https://example.com" || result == "https://example.com/")
    }

    @Test("removes fragment")
    func removeFragment() {
        let result = BookmarkURLNormalizer.normalizedURLString("https://example.com/page#section")
        #expect(!result.contains("#"))
        #expect(result == "https://example.com/page")
    }

    @Test("removes utm_source tracking param")
    func removeUTMSource() {
        let result = BookmarkURLNormalizer.normalizedURLString("https://example.com/page?utm_source=twitter&id=42")
        #expect(!result.contains("utm_source"))
        #expect(result.contains("id=42"))
    }

    @Test("removes all tracking params")
    func removeAllTracking() {
        let url = "https://example.com/?utm_source=a&utm_medium=b&utm_campaign=c&utm_term=d&utm_content=e&fbclid=f&gclid=g&igshid=h"
        let result = BookmarkURLNormalizer.normalizedURLString(url)
        #expect(!result.contains("utm_"))
        #expect(!result.contains("fbclid"))
        #expect(!result.contains("gclid"))
        #expect(!result.contains("igshid"))
    }

    @Test("sorts remaining query params")
    func sortQueryParams() {
        let result = BookmarkURLNormalizer.normalizedURLString("https://example.com?z=1&a=2")
        #expect(result == "https://example.com?a=2&z=1")
    }

    @Test("removes default HTTP port 80")
    func removePort80() {
        let result = BookmarkURLNormalizer.normalizedURLString("http://example.com:80/page")
        #expect(!result.contains(":80"))
    }

    @Test("removes default HTTPS port 443")
    func removePort443() {
        let result = BookmarkURLNormalizer.normalizedURLString("https://example.com:443/page")
        #expect(!result.contains(":443"))
    }

    @Test("keeps non-default port")
    func keepNonDefaultPort() {
        let result = BookmarkURLNormalizer.normalizedURLString("https://example.com:8080/page")
        #expect(result.contains(":8080"))
    }

    @Test("handles non-URL string gracefully")
    func invalidURL() {
        // URLComponents may parse non-URL strings as relative paths — result should be non-nil and trimmed
        let result = BookmarkURLNormalizer.normalizedURLString("  some-path  ")
        #expect(!result.isEmpty)
        #expect(!result.hasPrefix(" "))
        #expect(!result.hasSuffix(" "))
    }

    @Test("handles whitespace trimming")
    func whitespaceTrimming() {
        let result = BookmarkURLNormalizer.normalizedURLString("  https://example.com  ")
        #expect(result == "https://example.com")
    }

    @Test("combines all normalizations")
    func combined() {
        let url = "HTTPS://WWW.Example.Com:443/Path/?utm_source=test&real=value#frag"
        let result = BookmarkURLNormalizer.normalizedURLString(url)
        #expect(result == "https://example.com/Path?real=value")
    }
}

// MARK: - tweetID

@Suite("BookmarkURLNormalizer.tweetID")
struct TweetIDTests {

    @Test("extracts from twitter.com /status/ URL")
    func twitterStatus() {
        let id = BookmarkURLNormalizer.tweetID(from: "https://twitter.com/user/status/1234567890")
        #expect(id == "1234567890")
    }

    @Test("extracts from x.com /status/ URL")
    func xStatus() {
        let id = BookmarkURLNormalizer.tweetID(from: "https://x.com/user/status/9876543210")
        #expect(id == "9876543210")
    }

    @Test("extracts from /statuses/ URL")
    func statuses() {
        let id = BookmarkURLNormalizer.tweetID(from: "https://twitter.com/user/statuses/111222333")
        #expect(id == "111222333")
    }

    @Test("extracts from /i/status/ URL")
    func iStatus() {
        let id = BookmarkURLNormalizer.tweetID(from: "https://twitter.com/i/status/444555666")
        #expect(id == "444555666")
    }

    @Test("returns nil for non-tweet Twitter URL")
    func nonTweetURL() {
        let id = BookmarkURLNormalizer.tweetID(from: "https://twitter.com/user")
        #expect(id == nil)
    }

    @Test("returns nil for non-Twitter URL")
    func nonTwitterURL() {
        let id = BookmarkURLNormalizer.tweetID(from: "https://github.com/user/status/123")
        #expect(id == nil)
    }

    @Test("returns nil for invalid URL")
    func invalidURL() {
        let id = BookmarkURLNormalizer.tweetID(from: "not a url")
        #expect(id == nil)
    }

    @Test("returns nil for non-numeric status ID")
    func nonNumericID() {
        let id = BookmarkURLNormalizer.tweetID(from: "https://twitter.com/user/status/abc")
        #expect(id == nil)
    }
}

// MARK: - dedupeKey

@Suite("BookmarkURLNormalizer.dedupeKey")
struct DedupeKeyTests {

    @Test("regular URL returns normalized URL")
    func regularURL() {
        let key = BookmarkURLNormalizer.dedupeKey("https://www.example.com/page/")
        #expect(key == "https://example.com/page")
    }

    @Test("Twitter URL returns tweet:<id>")
    func twitterURL() {
        let key = BookmarkURLNormalizer.dedupeKey("https://twitter.com/user/status/123456")
        #expect(key == "tweet:123456")
    }

    @Test("X.com URL returns tweet:<id>")
    func xURL() {
        let key = BookmarkURLNormalizer.dedupeKey("https://x.com/user/status/123456")
        #expect(key == "tweet:123456")
    }

    @Test("same tweet on twitter.com and x.com produces same key")
    func crossPlatformDedup() {
        let twitterKey = BookmarkURLNormalizer.dedupeKey("https://twitter.com/user/status/789")
        let xKey = BookmarkURLNormalizer.dedupeKey("https://x.com/user/status/789")
        #expect(twitterKey == xKey)
    }

    @Test("non-tweet Twitter URL returns normalized URL")
    func twitterProfileURL() {
        let key = BookmarkURLNormalizer.dedupeKey("https://twitter.com/user")
        #expect(!key.hasPrefix("tweet:"))
    }
}

// MARK: - suggestCategory

@Suite("BookmarkURLNormalizer.suggestCategory")
struct SuggestCategoryTests {

    @Test("Twitter → x")
    func twitter() {
        #expect(BookmarkURLNormalizer.suggestCategory(for: "https://twitter.com/user/status/1") == "x")
    }

    @Test("X.com → x")
    func xcom() {
        #expect(BookmarkURLNormalizer.suggestCategory(for: "https://x.com/user") == "x")
    }

    @Test("Instagram → instagram")
    func instagram() {
        #expect(BookmarkURLNormalizer.suggestCategory(for: "https://www.instagram.com/p/abc") == "instagram")
    }

    @Test("YouTube → youtube")
    func youtube() {
        #expect(BookmarkURLNormalizer.suggestCategory(for: "https://www.youtube.com/watch?v=abc") == "youtube")
    }

    @Test("youtu.be → youtube")
    func youtubeShort() {
        #expect(BookmarkURLNormalizer.suggestCategory(for: "https://youtu.be/abc123") == "youtube")
    }

    @Test("Medium → article")
    func medium() {
        #expect(BookmarkURLNormalizer.suggestCategory(for: "https://medium.com/@user/post") == "article")
    }

    @Test("dev.to → article")
    func devTo() {
        #expect(BookmarkURLNormalizer.suggestCategory(for: "https://dev.to/user/post") == "article")
    }

    @Test("Substack → article")
    func substack() {
        #expect(BookmarkURLNormalizer.suggestCategory(for: "https://newsletter.substack.com/p/issue") == "article")
    }

    @Test("Vimeo → video")
    func vimeo() {
        #expect(BookmarkURLNormalizer.suggestCategory(for: "https://vimeo.com/123") == "video")
    }

    @Test("TikTok → video")
    func tiktok() {
        #expect(BookmarkURLNormalizer.suggestCategory(for: "https://www.tiktok.com/@user/video/123") == "video")
    }

    @Test("Dailymotion → video")
    func dailymotion() {
        #expect(BookmarkURLNormalizer.suggestCategory(for: "https://www.dailymotion.com/video/xyz") == "video")
    }

    @Test("unknown domain → nil")
    func unknownDomain() {
        #expect(BookmarkURLNormalizer.suggestCategory(for: "https://example.com") == nil)
    }

    @Test("invalid URL → nil")
    func invalidURL() {
        #expect(BookmarkURLNormalizer.suggestCategory(for: "not a url") == nil)
    }
}

// MARK: - normalizeCategory

@Suite("BookmarkURLNormalizer.normalizeCategory")
struct NormalizeCategoryTests {

    @Test("storage key passthrough")
    func storageKeys() {
        #expect(BookmarkURLNormalizer.normalizeCategory("x") == "x")
        #expect(BookmarkURLNormalizer.normalizeCategory("instagram") == "instagram")
        #expect(BookmarkURLNormalizer.normalizeCategory("youtube") == "youtube")
        #expect(BookmarkURLNormalizer.normalizeCategory("article") == "article")
        #expect(BookmarkURLNormalizer.normalizeCategory("video") == "video")
        #expect(BookmarkURLNormalizer.normalizeCategory("general") == "general")
    }

    @Test("case insensitive storage keys")
    func caseInsensitive() {
        #expect(BookmarkURLNormalizer.normalizeCategory("X") == "x")
        #expect(BookmarkURLNormalizer.normalizeCategory("YouTube") == "youtube")
        #expect(BookmarkURLNormalizer.normalizeCategory("GENERAL") == "general")
    }

    @Test("legacy 'X (Twitter)' maps to 'x'")
    func legacyTwitter() {
        #expect(BookmarkURLNormalizer.normalizeCategory("X (Twitter)") == "x")
        #expect(BookmarkURLNormalizer.normalizeCategory("x (twitter)") == "x")
    }

    @Test("legacy 'Twitter' maps to 'x'")
    func legacyTwitterName() {
        #expect(BookmarkURLNormalizer.normalizeCategory("Twitter") == "x")
        #expect(BookmarkURLNormalizer.normalizeCategory("twitter") == "x")
    }

    @Test("trims whitespace")
    func whitespace() {
        #expect(BookmarkURLNormalizer.normalizeCategory("  youtube  ") == "youtube")
    }

    @Test("unknown category lowercased passthrough")
    func unknown() {
        #expect(BookmarkURLNormalizer.normalizeCategory("Podcast") == "podcast")
    }
}

// MARK: - Paywall limits

@Suite("BookmarkURLNormalizer Paywall Limits")
struct PaywallLimitTests {

    @Test("free bookmark limit is 10")
    func bookmarkLimit() {
        #expect(BookmarkURLNormalizer.freeBookmarkLimit == 10)
    }

    @Test("free URL preview limit is 5")
    func previewLimit() {
        #expect(BookmarkURLNormalizer.freeURLPreviewLimit == 5)
    }

    @Test("canAddBookmark: free user under limit → true")
    func freeUnderLimit() {
        #expect(BookmarkURLNormalizer.canAddBookmark(currentCount: 0, isPremium: false) == true)
        #expect(BookmarkURLNormalizer.canAddBookmark(currentCount: 9, isPremium: false) == true)
    }

    @Test("canAddBookmark: free user at/over limit → false")
    func freeAtLimit() {
        #expect(BookmarkURLNormalizer.canAddBookmark(currentCount: 10, isPremium: false) == false)
        #expect(BookmarkURLNormalizer.canAddBookmark(currentCount: 100, isPremium: false) == false)
    }

    @Test("canAddBookmark: premium user always → true")
    func premiumAlways() {
        #expect(BookmarkURLNormalizer.canAddBookmark(currentCount: 0, isPremium: true) == true)
        #expect(BookmarkURLNormalizer.canAddBookmark(currentCount: 10, isPremium: true) == true)
        #expect(BookmarkURLNormalizer.canAddBookmark(currentCount: 1000, isPremium: true) == true)
    }

    @Test("canUseURLPreview: free user under limit → true")
    func previewFreeUnder() {
        #expect(BookmarkURLNormalizer.canUseURLPreview(currentCount: 0, isPremium: false) == true)
        #expect(BookmarkURLNormalizer.canUseURLPreview(currentCount: 4, isPremium: false) == true)
    }

    @Test("canUseURLPreview: free user at/over limit → false")
    func previewFreeAt() {
        #expect(BookmarkURLNormalizer.canUseURLPreview(currentCount: 5, isPremium: false) == false)
        #expect(BookmarkURLNormalizer.canUseURLPreview(currentCount: 50, isPremium: false) == false)
    }

    @Test("canUseURLPreview: premium user always → true")
    func previewPremium() {
        #expect(BookmarkURLNormalizer.canUseURLPreview(currentCount: 0, isPremium: true) == true)
        #expect(BookmarkURLNormalizer.canUseURLPreview(currentCount: 100, isPremium: true) == true)
    }
}
