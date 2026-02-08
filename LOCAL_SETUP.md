# 🔧 Local Setup for MindShelf

## 📋 Prerequisites
- Xcode 15+
- Supabase account and project
- Git

## 🚀 Setup Steps

### 1. Clone Repository
```bash
git clone https://github.com/muartdev/shelf-mind.git
cd shelf-mind/mind
```

### 2. Configure Supabase Credentials

1. Copy the example config file:
```bash
cp Config.xcconfig.example Config.xcconfig
```

2. Get your Supabase credentials:
   - Go to your Supabase dashboard
   - Navigate to **Settings** → **API**
   - Copy **Project URL** and **anon public key**

3. Open `Config.xcconfig` and add your credentials:
```
SUPABASE_URL = https://your-project-id.supabase.co
SUPABASE_ANON_KEY = eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

### 3. Setup Database

1. Go to Supabase **SQL Editor**
2. Run the SQL from `supabase-schema.sql`
3. Verify tables are created in **Table Editor**

### 4. Add Supabase Package (First Time Only)

1. Open `mind.xcodeproj` in Xcode
2. Go to **File** → **Add Package Dependencies**
3. Add: `https://github.com/supabase/supabase-swift`
4. Select version **2.0.0** or later

### 5. Configure Xcode Project (First Time Only)

1. Select **mind** project in navigator
2. Select **mind** target
3. Go to **Info** tab
4. Add these keys:
   - Key: `SUPABASE_URL`, Value: `$(SUPABASE_URL)`
   - Key: `SUPABASE_ANON_KEY`, Value: `$(SUPABASE_ANON_KEY)`

5. Go to **Build Settings** tab
6. Search for "xcconfig"
7. Set **Debug** and **Release** configuration files to `Config.xcconfig`

### 6. Build & Run

```bash
# Clean build folder
Cmd + Shift + K

# Build
Cmd + B

# Run
Cmd + R
```

## 🔒 Security Notes

- `Config.xcconfig` is gitignored and will NOT be committed
- Only `Config.xcconfig.example` is in version control
- Each developer needs their own `Config.xcconfig` file
- Never commit real credentials to Git

## 🆘 Troubleshooting

**"SUPABASE_URL not found" error:**
- Make sure `Config.xcconfig` exists
- Verify values are set in Info.plist
- Clean build folder and rebuild

**Supabase import error:**
- Add the package via SPM (step 4)
- Clean build: `Cmd + Shift + K`

## 📚 More Info

See `SUPABASE_SETUP.md` for detailed Supabase setup guide.
