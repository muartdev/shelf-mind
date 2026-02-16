# App Store Öncesi Kontrol Listesi

## Kritik (Mutlaka Yapılmalı)

### 1. Gereksiz / Kullanılmayan Kod
- **AuthManager.signInWithApple** — Sign in with Apple kaldırıldı ama fonksiyon hâlâ duruyor. Sil.
- **SupabaseManager.signInWithApple** — Aynı şekilde kullanılmıyor, sil.

### 2. Gereksiz Dosyalar
- **File.txt** — İçinde sadece bir Google image URL var, projede kullanılmıyor. Sil veya `.gitignore`'a ekle.

### 3. App Store Gereksinimleri
- **LICENSE** — README "MIT License - see LICENSE" diyor ama `LICENSE` dosyası yok. Eklenmeli.
- **Privacy Policy URL** — `https://muartdev.github.io/mindshelf-privacy/` mevcut ve çalışıyor.
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
- **auth.signin.apple** — LocalizationManager’da hâlâ var, Sign in with Apple kaldırıldığı için silinebilir.
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
- **Products.storekit** vs **MindShelf.storekit** — İki StoreKit config var; hangisinin kullanıldığını netleştir.
- **EULA** — Products.storekit’te `"eula": ""` boş; gerekirse doldur.

### 12. Geliştirici Bilgileri
- Privacy Policy’de **ideloc.studio@gmail.com** var.
- README’de **muartmac@gmail.com** var.
- Hangisi resmi iletişim olacak, tutarlı ol.

---

## Özet Aksiyon Listesi

| Öncelik | Aksiyon |
|---------|---------|
| 🔴 | signInWithApple kodunu AuthManager ve SupabaseManager’dan sil |
| 🔴 | File.txt’i sil veya .gitignore’a ekle |
| 🔴 | LICENSE dosyası ekle (MIT) |
| 🔴 | Info.plist’e ITSAppUsesNonExemptEncryption = NO ekle |
| 🟡 | Config hatalarında fatalError yerine kullanıcı dostu mesaj |
| 🟡 | auth.signin.apple localization’ı sil |
| 🟢 | README roadmap ve author bilgilerini güncelle |
