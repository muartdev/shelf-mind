import Testing
import Foundation
@testable import MindShelfCore

// MARK: - extractMetaTag

@Suite("HTMLMetaParser.extractMetaTag")
struct ExtractMetaTagTests {

    @Test("extracts og:title with property before content")
    func ogTitlePropertyFirst() {
        let html = """
        <html><head>
        <meta property="og:title" content="My Page Title">
        </head></html>
        """
        #expect(HTMLMetaParser.extractMetaTag(html: html, property: "og:title") == "My Page Title")
    }

    @Test("extracts og:title with content before property")
    func ogTitleContentFirst() {
        let html = """
        <html><head>
        <meta content="Reversed Order Title" property="og:title">
        </head></html>
        """
        #expect(HTMLMetaParser.extractMetaTag(html: html, property: "og:title") == "Reversed Order Title")
    }

    @Test("extracts og:image")
    func ogImage() {
        let html = """
        <meta property="og:image" content="https://example.com/image.jpg">
        """
        #expect(HTMLMetaParser.extractMetaTag(html: html, property: "og:image") == "https://example.com/image.jpg")
    }

    @Test("extracts twitter:title by name")
    func twitterTitle() {
        let html = """
        <meta name="twitter:title" content="Twitter Card Title">
        """
        #expect(HTMLMetaParser.extractMetaTag(html: html, name: "twitter:title") == "Twitter Card Title")
    }

    @Test("extracts description by name")
    func descriptionByName() {
        let html = """
        <meta name="description" content="A page about testing">
        """
        #expect(HTMLMetaParser.extractMetaTag(html: html, name: "description") == "A page about testing")
    }

    @Test("returns nil for missing tag")
    func missingTag() {
        let html = "<html><head><title>Only Title</title></head></html>"
        #expect(HTMLMetaParser.extractMetaTag(html: html, property: "og:title") == nil)
    }

    @Test("returns nil when no property or name given")
    func noPropertyOrName() {
        let html = "<meta property=\"og:title\" content=\"Test\">"
        #expect(HTMLMetaParser.extractMetaTag(html: html) == nil)
    }

    @Test("case insensitive tag matching")
    func caseInsensitive() {
        let html = """
        <META PROPERTY="og:title" CONTENT="Uppercase Tags">
        """
        #expect(HTMLMetaParser.extractMetaTag(html: html, property: "og:title") == "Uppercase Tags")
    }

    @Test("handles single quotes")
    func singleQuotes() {
        let html = """
        <meta property='og:title' content='Single Quoted'>
        """
        #expect(HTMLMetaParser.extractMetaTag(html: html, property: "og:title") == "Single Quoted")
    }
}

// MARK: - extractTitle

@Suite("HTMLMetaParser.extractTitle")
struct ExtractTitleTests {

    @Test("extracts standard title")
    func standardTitle() {
        let html = "<html><head><title>My Page</title></head></html>"
        #expect(HTMLMetaParser.extractTitle(html: html) == "My Page")
    }

    @Test("extracts title with attributes")
    func titleWithAttributes() {
        let html = "<html><head><title lang=\"en\">Attributed Title</title></head></html>"
        #expect(HTMLMetaParser.extractTitle(html: html) == "Attributed Title")
    }

    @Test("returns nil when no title")
    func missingTitle() {
        let html = "<html><head><meta charset=\"utf-8\"></head></html>"
        #expect(HTMLMetaParser.extractTitle(html: html) == nil)
    }

    @Test("extracts first title when multiple exist")
    func multipleTitle() {
        let html = "<title>First</title><title>Second</title>"
        #expect(HTMLMetaParser.extractTitle(html: html) == "First")
    }
}

// MARK: - resolveImageURL

@Suite("HTMLMetaParser.resolveImageURL")
struct ResolveImageURLTests {

    let base = URL(string: "https://example.com/page/article")!

    @Test("returns absolute URL as-is")
    func absoluteURL() {
        let result = HTMLMetaParser.resolveImageURL("https://cdn.example.com/img.jpg", baseURL: base)
        #expect(result == "https://cdn.example.com/img.jpg")
    }

    @Test("resolves protocol-relative URL")
    func protocolRelative() {
        let result = HTMLMetaParser.resolveImageURL("//cdn.example.com/img.jpg", baseURL: base)
        #expect(result == "https://cdn.example.com/img.jpg")
    }

    @Test("resolves root-relative URL")
    func rootRelative() {
        let result = HTMLMetaParser.resolveImageURL("/images/photo.png", baseURL: base)
        #expect(result == "https://example.com/images/photo.png")
    }

    @Test("resolves relative path")
    func relativePath() {
        let result = HTMLMetaParser.resolveImageURL("photo.png", baseURL: base)
        #expect(result == "https://example.com/photo.png")
    }

    @Test("returns nil for nil input")
    func nilInput() {
        #expect(HTMLMetaParser.resolveImageURL(nil, baseURL: base) == nil)
    }

    @Test("returns nil for empty string")
    func emptyString() {
        #expect(HTMLMetaParser.resolveImageURL("", baseURL: base) == nil)
    }

    @Test("handles http absolute URL")
    func httpAbsolute() {
        let result = HTMLMetaParser.resolveImageURL("http://other.com/img.jpg", baseURL: base)
        #expect(result == "http://other.com/img.jpg")
    }
}

// MARK: - decodeHTMLEntities

@Suite("HTMLMetaParser.decodeHTMLEntities")
struct DecodeHTMLEntitiesTests {

    @Test("decodes &amp;")
    func ampersand() {
        #expect(HTMLMetaParser.decodeHTMLEntities("Tom &amp; Jerry") == "Tom & Jerry")
    }

    @Test("decodes &lt; and &gt;")
    func angleBrackets() {
        #expect(HTMLMetaParser.decodeHTMLEntities("&lt;div&gt;") == "<div>")
    }

    @Test("decodes &quot;")
    func doubleQuote() {
        #expect(HTMLMetaParser.decodeHTMLEntities("Say &quot;hello&quot;") == "Say \"hello\"")
    }

    @Test("decodes &#39; and &apos;")
    func singleQuotes() {
        #expect(HTMLMetaParser.decodeHTMLEntities("It&#39;s") == "It's")
        #expect(HTMLMetaParser.decodeHTMLEntities("It&apos;s") == "It's")
    }

    @Test("decodes curly quotes")
    func curlyQuotes() {
        #expect(HTMLMetaParser.decodeHTMLEntities("&ldquo;Hello&rdquo;") == "\"Hello\"")
        #expect(HTMLMetaParser.decodeHTMLEntities("&lsquo;Hi&rsquo;") == "'Hi'")
    }

    @Test("decodes &nbsp;")
    func nbsp() {
        #expect(HTMLMetaParser.decodeHTMLEntities("Hello&nbsp;World") == "Hello World")
    }

    @Test("handles multiple entities in one string")
    func multipleEntities() {
        #expect(HTMLMetaParser.decodeHTMLEntities("A &amp; B &lt; C &gt; D") == "A & B < C > D")
    }

    @Test("returns nil for nil input")
    func nilInput() {
        #expect(HTMLMetaParser.decodeHTMLEntities(nil) == nil)
    }

    @Test("returns plain string unchanged")
    func noEntities() {
        #expect(HTMLMetaParser.decodeHTMLEntities("No entities here") == "No entities here")
    }
}
