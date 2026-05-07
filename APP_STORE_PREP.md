# App Store Öncesi Kontrol Listesi

## Kritik (Mutlaka Yapılmalı)

### 1. Gereksiz / Kullanılmayan Kod
- **Sign in with Apple kalıntıları** — Kodda aktif Sign in with Apple akışı bulunmamalı; privacy policy de bunu servis olarak listelememeli.

### 2. Gereksiz Dosyalar
- **File.txt** — İçinde sadece bir Google image URL var, projede kullanılmıyor. Sil veya `.gitignore`'a ekle.

### 3. App Store Gereksinimleri
- **LICENSE** — README "MIT License - see LICENSE" diyor ama `LICENSE` dosyası yok. Eklenmeli.
- **Privacy Policy URL** — `https://muartdev.github.io/mindshelf-privacy/` Güncel metin bu repoda `privacy/index.html`; yayına almak için `mindshelf-privacy` GitHub repo’sundaki `index.html` ile değiştir (bkz. `APP_STORE_METADATA.md` → Deploy Privacy Policy).
- **App Privacy (App Store Connect)** — Giriş yaptığında App Store Connect’te gizlilik etiketlerini doldur (Email, User ID, Purchase History vb.).

### 4. Info.plist Eksikleri
- **NSAppTransportSecurity** — HTTPS zorunluluğu (Supabase zaten HTTPS kullanıyor, genelde sorun olmaz).
- **ITSAppUsesNonExemptEncryption** — Şifreleme kullanıyorsan `NO` ekle (Supabase SSL kullanıyor, export compliance için).
- **UIBackgroundModes** — Gerekirse (örn. remote-notification) eklenmeli.

---

## Önerilen İyileştirmeler

### 5. Hata Yönetimi
- **Config.swift** — `fatalError` production’da uygulamayı çökertir. Config eksikse daha yumuşak bir hata mesajı göster.
- **mindApp fallback** — In-memory store’a düşerse kullanıcıya anlamlı bir mesaj göster (şu an `showDatabaseError` var, iyi).

### 6. Kullanıcı Deneyimi
- **Boş ekran durumları** — Tüm boş state’lerde net mesaj ve aksiyon var mı kontrol et.
- **Offline mod** — İnternet yokken anlamlı bir mesaj göster.
- **Yükleme göstergeleri** — Uzun işlemlerde (sync, fetch) loading state’ler tutarlı mı?

### 7. Yerelleştirme
- **auth.signin.apple** — Sign in with Apple kaldırıldığı için localization içinde kalıntı varsa silinebilir.
- **Eksik çeviriler** — Tüm kullanıcıya görünen metinler EN/TR için kontrol edilmeli.

### 8. Test
- **Gerçek cihaz** — Simulator’da çalışan her şey gerçek cihazda da test edilmeli.
- **Farklı ekran boyutları** — iPhone SE, Pro Max vb.
- **Hesap değiştirme** — Çıkış → farklı hesap → veri doğru mu?

---

## Opsiyonel (İstersen)

### 9. README Güncellemesi
- Roadmap’te "Widget support" artık var, işaretle.
- "URL metadata fetching" — Open Graph zaten var gibi (URLPreviewManager), güncelle.
- GitHub username: `@YOUR_USERNAME` → gerçek kullanıcı adın.

### 10. Proje Temizliği
- **Package.resolved** — `.gitignore`’da ama projede görünüyor olabilir; SPM için genelde commit edilir, sorun değil.
- **xcschememanagement.plist** — `xcuserdata` içinde, kişisel ayar; genelde commit edilmez.

### 11. StoreKit / In-App Purchase
- **Products.storekit** — Xcode scheme StoreKit test config olarak kullanıyor; production bundle resource listesine eklenmemeli.
- **EULA** — App içi Terms linki ve Products.storekit EULA değeri Apple Standard EULA URL’sini kullanmalı.
- **Subscription management** — App içinde external subscription URL açılmamalı; StoreKit native subscription management sheet kullanılmalı.

### 12. Geliştirici Bilgileri
- Privacy Policy’de **ideloc.studio@gmail.com** var.
- README’de **muartmac@gmail.com** var.
- Hangisi resmi iletişim olacak, tutarlı ol.

---

## Özet Aksiyon Listesi

| Öncelik | Aksiyon |
|---------|---------|
| 🟢 | App Review 5.1.1(v): onboarding sonrası local/guest erişimi zorunlu login olmadan aç |
| 🟢 | App Review 3.1.1: external subscription URL yerine native StoreKit management sheet kullan |
| 🟡 | Sign in with Apple kalıntılarını arada bir kontrol et |
| 🔴 | File.txt’i sil veya .gitignore’a ekle |
| 🔴 | LICENSE dosyası ekle (MIT) |
| 🔴 | Info.plist’e ITSAppUsesNonExemptEncryption = NO ekle |
| 🟡 | Config hatalarında fatalError yerine kullanıcı dostu mesaj |
| 🟡 | auth.signin.apple localization’ı sil |
| 🟢 | README roadmap ve author bilgilerini güncelle |
