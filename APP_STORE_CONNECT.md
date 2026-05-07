# App Store Connect Checklist

## StoreKit
- **Products.storekit** — Aktif config (Xcode scheme'de kullanılıyor)
- ~~MindShelf.storekit~~ — Silindi (kullanılmıyordu)
- **EULA** — Apple Standard EULA URL kullanılıyor
- **Subscription management** — App içindeki yönetim aksiyonu native StoreKit/App Store sheet kullanıyor; external subscription URL yok.

## App Review Reject Fixleri
- **5.1.1(v)** — Onboarding sonrası hesap zorunluluğu yok; kullanıcı direkt local bookmark manager'a giriyor. Hesap sadece Settings'te cloud sync/web access için opsiyonel.
- **3.1.1** — iOS Premium sadece StoreKit IAP ile açılıyor; external payment/subscription URL kullanılmıyor.

## İletişim (Tutarlı)
- **README** — ideloc.studio@gmail.com
- **Privacy Policy** — ideloc.studio@gmail.com

## App Store Connect'te Yapılacaklar

### 1. App Privacy (Gizlilik Etiketleri)
Giriş yaptığında şunları işaretle:
- **Contact Info** → Email Address (hesap oluşturma)
- **User ID** (Supabase auth)
- **Purchase History** (StoreKit abonelik)
- **User Content → Other User Content** (senkronlanan yer imleri, notlar, etiketler)

Terms of Use / EULA:
- Apple Standard EULA: `https://www.apple.com/legal/internet-services/itunes/dev/stdeula/`

### 2. Export Compliance
- **ITSAppUsesNonExemptEncryption = NO** — Info.plist'e eklendi ✓
- App Store Connect'te "No" olarak işaretle

### 3. Age Rating
- Uygulama içeriğine göre uygun yaş sınırı seç
