# 📚 MindShelf - Modern Bookmark Manager

A minimalist, modern SwiftUI bookmark management app for iOS, powered by Supabase backend.

![iOS](https://img.shields.io/badge/iOS-17.0%2B-blue)
![Swift](https://img.shields.io/badge/Swift-6.0-orange)
![SwiftUI](https://img.shields.io/badge/SwiftUI-✓-green)
![Supabase](https://img.shields.io/badge/Supabase-✓-brightgreen)

## ✨ Features

### 📱 Core Features
- **Beautiful UI** - iOS-inspired Material Design with "liquid glass" aesthetic
- **Smart Organization** - Category-based bookmark management (X, Instagram, YouTube, Articles, Videos, General)
- **Quick Filters** - Filter by category, read/unread status
- **Rich Details** - Add notes, tags, and thumbnails to bookmarks
- **Search** - Find bookmarks quickly with full-text search

### 🎨 User Experience
- **Modern Themes** - 4 beautiful theme variants (Blue-Purple, Orange-Pink, Light & Dark modes)
- **Onboarding Flow** - Smooth first-time user experience
- **Statistics Dashboard** - Track your reading habits
- **Smart Empty States** - Contextual guidance based on active filters

### 🔐 Backend & Sync
- **Supabase Integration** - Secure backend with PostgreSQL database
- **User Authentication** - Email/password sign up & sign in
- **Row Level Security (RLS)** - User data is isolated and secure
- **Real-time Sync** - Changes sync across devices

### 🧩 Technical Highlights
- **SwiftData** - Local persistence for offline support
- **Observable Pattern** - Modern state management with `@Observable`
- **Async/Await** - Clean async code with Swift Concurrency
- **Material Design** - `.ultraThinMaterial`, `.thinMaterial` for depth
- **Gradient Theming** - Dynamic color schemes with smooth transitions

## 📸 Screenshots

*(Coming soon)*

## 🚀 Getting Started

### Prerequisites
- macOS 15.0+ with Xcode 16.1+
- iOS 17.0+ device or simulator
- Supabase account (free tier works great)

### 1. Clone the Repository

```bash
git clone https://github.com/muartdev/shelf-mind.git
cd mindshelf/mind
```

### 2. Set Up Supabase Backend

Follow the detailed setup guide: **[SUPABASE_SETUP.md](SUPABASE_SETUP.md)**

Quick summary:
1. Create a new Supabase project at [supabase.com](https://supabase.com)
2. Run the SQL schema from `supabase-schema.sql` in Supabase SQL Editor
3. Get your Project URL and Anon Key from Supabase Settings

### 3. Configure Local Environment

Follow the local setup guide: **[LOCAL_SETUP.md](LOCAL_SETUP.md)**

Quick summary:
1. Copy `Config.xcconfig.example` to `Config.xcconfig`
2. Add your Supabase credentials to `Config.xcconfig`:
   ```
   // NOTE: In .xcconfig, `//` starts a comment, so avoid writing https:// directly.
   SUPABASE_SLASH = /
   SUPABASE_URL = https:$(SUPABASE_SLASH)$(SUPABASE_SLASH)your-project.supabase.co
   SUPABASE_ANON_KEY = your_anon_key_here
   ```
3. Add Swift Package Dependencies in Xcode (File > Add Package Dependencies)
   - Supabase: `https://github.com/supabase/supabase-swift`
   - Select `Auth` and `PostgREST` modules
4. Link `Config.xcconfig` in Xcode Build Settings

### 4. Build & Run

1. Open `mind.xcodeproj` in Xcode
2. Select your target device or simulator
3. Press `Cmd + R` to build and run

## 📂 Project Structure

```
mind/
├── mind/                        # Main app source
│   ├── mindApp.swift           # App entry point
│   ├── Config.swift            # Configuration reader
│   │
│   ├── Models/                 # Data models
│   │   ├── Item.swift          # Bookmark & Category
│   │   └── User.swift          # User model
│   │
│   ├── Managers/               # Business logic
│   │   ├── AuthManager.swift  # Authentication
│   │   ├── ThemeManager.swift # Theme management
│   │   └── SupabaseManager.swift # Supabase API
│   │
│   ├── Views/                  # UI screens
│   │   ├── MainTabView.swift
│   │   ├── ContentView.swift
│   │   ├── AddBookmarkView.swift
│   │   ├── BookmarkDetailView.swift
│   │   ├── StatisticsView.swift
│   │   ├── SettingsView.swift
│   │   ├── OnboardingView.swift
│   │   └── AuthView.swift
│   │
│   ├── Components/             # Reusable UI
│   │   ├── BookmarkCard.swift
│   │   └── TagView.swift
│   │
│   └── Assets.xcassets/        # App assets
│
├── Config.xcconfig             # Environment config (gitignored)
├── Config.xcconfig.example     # Config template
├── Info.plist                  # App info & config keys
└── supabase-schema.sql         # Database schema

```

## 🔧 Technologies Used

- **Swift 6.0** - Modern Swift with strict concurrency
- **SwiftUI** - Declarative UI framework
- **SwiftData** - Apple's data persistence framework
- **Supabase Swift SDK** - Backend integration
  - `Auth` - User authentication
  - `PostgREST` - Database queries
- **Observation Framework** - Modern state management with `@Observable`

## 🎨 Design System

### Themes
- **Blue-Purple** (Light/Dark)
- **Orange-Pink** (Light/Dark)

### UI Components
- **Glass Morphism** - Translucent `.ultraThinMaterial` backgrounds
- **Stroke Borders** - Subtle white `.strokeBorder()` outlines
- **Multi-layer Shadows** - Depth with `.shadow()` layers
- **Gradient Accents** - Smooth `LinearGradient` transitions
- **Dynamic Typography** - SF Pro system fonts with weight variations

## 🔐 Security

- **Environment Variables** - Sensitive keys stored in `Config.xcconfig` (gitignored)
- **Row Level Security (RLS)** - Supabase policies enforce user isolation
- **No Hardcoded Secrets** - All credentials in config files
- **Config Template** - `Config.xcconfig.example` for easy setup

## 📝 Configuration Files

### `.gitignore`
- Excludes `Config.xcconfig` to prevent credential leaks
- Ignores Xcode build artifacts

### `Config.xcconfig.example`
- Template for required environment variables
- Safe to commit to version control

### `Config.swift`
- Safely reads config values from `Info.plist`
- Crashes gracefully if keys are missing

## 🚧 Roadmap

- [x] URL metadata fetching (Open Graph)
- [x] Widget support
- [ ] Browser extension for easy bookmark saving
- [ ] iCloud sync as alternative to Supabase
- [ ] Import/Export bookmarks (JSON, CSV)
- [ ] Sharing bookmarks with friends
- [ ] Dark mode auto-switching based on time

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the project
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👤 Author

**Murat (Ideloc Studio)**
- GitHub: [@muartdev](https://github.com/muartdev)
- Email: ideloc.studio@gmail.com

## 🙏 Acknowledgments

- [Supabase](https://supabase.com) - For the amazing backend platform
- [Apple](https://developer.apple.com) - For SwiftUI & SwiftData
- Icons by [SF Symbols](https://developer.apple.com/sf-symbols/)

---

**Made with ❤️ and SwiftUI**
