# 🧠 MindShelf - Modern Bookmark Manager

<img src="https://img.shields.io/badge/iOS-17.0+-blue.svg" alt="iOS 17.0+">
<img src="https://img.shields.io/badge/Swift-5.9+-orange.svg" alt="Swift 5.9+">
<img src="https://img.shields.io/badge/SwiftUI-Liquid_Glass-purple.svg" alt="SwiftUI Liquid Glass">

A beautiful, modern bookmark manager for iOS featuring Apple's new Liquid Glass design language. Save and organize content from X (Twitter), articles, videos, and more to read later.

## ✨ Features

- 🎨 **Liquid Glass Design** - Beautiful iOS 26+ native glass effects with Material fallbacks
- 📚 **Smart Organization** - 6 categories (Article, Video, Tweet, Research, Tutorial, General)
- 🔍 **Powerful Search** - Quick search across titles, URLs, and notes
- 🏷️ **Filter & Sort** - Filter by category and read status
- ✅ **Read Tracking** - Mark bookmarks as read/unread
- 📝 **Rich Metadata** - Titles, notes, dates automatically tracked
- 💾 **SwiftData Storage** - Modern persistent storage
- 🎯 **Context Menu Actions** - Quick actions on each bookmark
- 📱 **Modern SwiftUI** - SwiftData + latest SwiftUI patterns

## 🚀 Getting Started

### Prerequisites
- Xcode 15.0+
- iOS 17.0+ (iOS 26.0+ for Liquid Glass effects)
- macOS Sonoma or later

### Installation

1. Open `mind.xcodeproj` in Xcode
2. Select your simulator or device
3. Press `⌘R` to build and run

### Project Structure

```
mind/
├── mindApp.swift           # App entry point
├── Item.swift              # Bookmark model (SwiftData)
├── ContentView.swift       # Main list view
├── BookmarkCard.swift      # Card component
├── AddBookmarkView.swift   # Add bookmark sheet
└── BookmarkDetailView.swift # Detail & edit view
```

## 📱 Usage

### Adding a Bookmark
1. Tap the "+" button in the top right
2. Enter the title, URL, and optional notes
3. Select a category
4. Tap "Save"

### Managing Bookmarks
- **Tap a card** to view details
- **Long press** for context menu (Mark as Read, Open, Delete)
- **Use search** to find bookmarks
- **Tap filter chips** to filter by category or unread status

### Detail View
- View full bookmark information
- Edit any field
- Mark as read/unread
- Open in Safari
- Share bookmark
- Delete bookmark

## 🎨 Design Features

### Liquid Glass Effects (iOS 26+)
- Glass effect cards with translucent backgrounds
- Interactive glass buttons
- GlassEffectContainer for grouped elements
- Smooth animations

### Fallback Design (iOS 17-25)
- Material backgrounds
- Standard button styles
- Same functionality with different visuals

## 🛠️ Technical Details

### SwiftData
This app uses SwiftData for persistent storage:
- `@Model` macro for Bookmark
- `@Query` for reactive updates
- SwiftData ModelContext for CRUD operations

### SwiftUI Best Practices
- Modern property wrappers
- LazyVStack for performance
- Stable ForEach identity
- Proper animations
- Modern APIs (foregroundStyle, clipShape, etc.)

## 🎯 Customization

### Adding New Categories
Edit `Item.swift` and add new cases to the `Category` enum:

```swift
enum Category: String, CaseIterable {
    case yourNewCategory = "Your New Category"
    // Add icon in the icon property
}
```

### Changing Colors
Modify background gradients in views:

```swift
LinearGradient(
    colors: [.blue.opacity(0.1), .purple.opacity(0.1)],
    startPoint: .topLeading,
    endPoint: .bottomTrailing
)
```

## 🔧 Testing

1. Build and run in Xcode (⌘R)
2. Sample data will be empty initially
3. Add bookmarks using the "+" button
4. Test filtering, search, and detail views
5. For iOS 26 Liquid Glass: Use iOS 26+ simulator
6. For iOS 17-25: Material fallbacks will be used

## 📚 Future Enhancements

- [ ] iCloud sync
- [ ] Browser extension
- [ ] Tags system
- [ ] Export/Import
- [ ] Widget support
- [ ] Share Extension (Safari)
- [ ] Dark mode customization

## 📄 License

This project is open source and available under the MIT License.

## 🙏 Acknowledgments

- Built with SwiftUI Expert Skill best practices
- Follows Apple's Human Interface Guidelines
- Uses iOS 26+ Liquid Glass design language
- Implements modern SwiftData patterns

---

Made with ❤️ using SwiftUI and Liquid Glass
