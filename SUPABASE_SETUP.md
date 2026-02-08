# 🗄️ Supabase Integration Guide for MindShelf

## 📋 Prerequisites
- Supabase account (https://supabase.com)
- Xcode 15+
- iOS 17+

## 🚀 Setup Steps

### 1. Create Supabase Project
1. Go to https://supabase.com and create an account
2. Create a new project
3. Wait for project initialization (takes 1-2 minutes)

### 2. Set Up Database Schema
1. Go to your Supabase project dashboard
2. Click "SQL Editor" in the left sidebar
3. Create a new query
4. Copy and paste contents from `supabase-schema.sql`
5. Click "Run" to execute the SQL
6. Verify tables are created in "Table Editor"

### 3. Get API Credentials
1. Go to "Settings" → "API" in your Supabase dashboard
2. Copy the following:
   - **Project URL**: `https://xxxxx.supabase.co`
   - **Anon/Public Key**: `eyJhbGc...` (long string)

### 4. Add Supabase Swift Package to Xcode

1. Open `mind.xcodeproj` in Xcode
2. Go to **File** → **Add Package Dependencies**
3. Paste this URL: `https://github.com/supabase/supabase-swift`
4. Select version: **2.0.0** or later
5. Click **Add Package**
6. Select **Supabase** framework
7. Click **Add Package**

### 5. Configure Credentials

1. Open `SupabaseManager.swift`
2. Replace placeholders with your credentials:

```swift
private let supabaseURL = "https://your-project.supabase.co"
private let supabaseKey = "your-anon-key-here"
```

3. Uncomment the Supabase import:
```swift
import Supabase
```

4. Uncomment the client initialization:
```swift
var client: SupabaseClient

private init() {
    self.client = SupabaseClient(
        supabaseURL: URL(string: supabaseURL)!,
        supabaseKey: supabaseKey
    )
}
```

### 6. Update AuthManager to Use Supabase

Replace the demo authentication in `AuthManager.swift` with real Supabase calls:

```swift
func signUp(email: String, name: String, password: String) async {
    isLoading = true
    error = nil
    
    do {
        let user = try await SupabaseManager.shared.signUp(
            email: email,
            password: password,
            name: name
        )
        currentUser = user
        isAuthenticated = true
        saveSession(userId: user.id.uuidString)
    } catch {
        self.error = error.localizedDescription
    }
    
    isLoading = false
}
```

### 7. Enable Authentication Providers (Optional)

In Supabase Dashboard:
1. Go to **Authentication** → **Providers**
2. Configure Email (already enabled)
3. Optional: Enable Apple Sign In, Google, etc.

## 📊 Database Structure

### Tables

**users**
- `id` (UUID, primary key)
- `email` (text)
- `name` (text)
- `avatar_url` (text, nullable)
- `created_at` (timestamp)
- `updated_at` (timestamp)
- `notifications_enabled` (boolean)
- `reminder_time` (time)

**bookmarks**
- `id` (UUID, primary key)
- `user_id` (UUID, foreign key)
- `title` (text)
- `url` (text)
- `notes` (text)
- `category` (text)
- `tags` (text array)
- `is_read` (boolean)
- `thumbnail_url` (text, nullable)
- `created_at` (timestamp)
- `updated_at` (timestamp)

## 🔒 Security

- Row Level Security (RLS) enabled on all tables
- Users can only access their own data
- Automatic user profile creation on signup
- Secure password hashing via Supabase Auth

## 🧪 Testing

1. Build and run the app
2. Sign up with a test email
3. Create a bookmark
4. Check Supabase dashboard → Table Editor to see data

## 📝 Next Steps

- [ ] Implement real-time sync
- [ ] Add bookmark sharing
- [ ] Implement URL preview/metadata fetching
- [ ] Add bookmark collections/folders
- [ ] Implement collaborative bookmarks

## 🆘 Troubleshooting

**Build Error: "Cannot find 'Supabase' in scope"**
- Make sure you added the package via SPM
- Clean build folder: `Cmd + Shift + K`
- Rebuild: `Cmd + B`

**Authentication Error**
- Check your API credentials
- Verify email confirmation is disabled in Supabase (or check email)
- Check Supabase logs in dashboard

**Database Error**
- Verify SQL schema ran successfully
- Check RLS policies are created
- View logs in Supabase dashboard

## 📚 Resources

- [Supabase Swift Docs](https://github.com/supabase/supabase-swift)
- [Supabase Auth Guide](https://supabase.com/docs/guides/auth)
- [Row Level Security](https://supabase.com/docs/guides/auth/row-level-security)
