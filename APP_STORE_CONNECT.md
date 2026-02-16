# App Store Connect Checklist

## StoreKit
- **Products.storekit** — Aktif config (Xcode scheme'de kullanılıyor)
- ~~MindShelf.storekit~~ — Silindi (kullanılmıyordu)
- **EULA** — Privacy Policy URL eklendi

## İletişim (Tutarlı)
- **README** — ideloc.studio@gmail.com
- **Privacy Policy** — ideloc.studio@gmail.com

## App Store Connect'te Yapılacaklar

### 1. App Privacy (Gizlilik Etiketleri)
Giriş yaptığında şunları işaretle:
- **Contact Info** → Email Address (hesap oluşturma)
- **User ID** (Supabase auth)
- **Purchase History** (StoreKit abonelik)
- **Product Interaction** (yer imleri, notlar)

### 2. Export Compliance
- **ITSAppUsesNonExemptEncryption = NO** — Info.plist'e eklendi ✓
- App Store Connect'te "No" olarak işaretle

### 3. Age Rating
- Uygulama içeriğine göre uygun yaş sınırı seç
