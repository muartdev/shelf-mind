# iOS Password AutoFill (Otomatik Şifre Kaydetme)

MindShelf, iOS'un yerleşik şifre yöneticisi ile entegre çalışır.

## Nasıl Çalışır?

1. **İlk giriş:** Email ve şifre ile giriş yaptığında iOS "Bu şifreyi kaydetmek ister misiniz?" diye sorar → **Kaydet** de
2. **Sonraki girişler:** Çıkış yapıp tekrar giriş ekranına geldiğinde:
   - Şifre alanına dokunduğunda klavyenin üstünde kayıtlı hesap görünür
   - Face ID / Touch ID ile onaylayınca email ve şifre otomatik dolar

## Teknik Detaylar

- Giriş formunda email: `textContentType(.username)` — iOS kayıtlı şifreleri eşleştirir
- Giriş formunda şifre: `textContentType(.password)` — otomatik doldurma için
- Kayıt formunda şifre: `textContentType(.newPassword)` — güçlü şifre önerisi için

**Ek yapılandırma gerekmez.** Gerçek cihazda test edin (Simulator'da AutoFill sınırlı çalışır).
