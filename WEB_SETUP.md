# MindShelf Web - Landing Page & Web App

Aynı Supabase hesabı ile iOS ve tarayıcıdan erişilebilen web uygulaması.

## Özellikler

- **Landing page** — Uygulamayı tanıtan sayfa
- **Web app** — Giriş yap, yer imlerini görüntüle/ekle/sil
- **Aynı hesap** — iOS app ile aynı email/şifre

## Kurulum

```bash
cd web
cp .env.example .env
# .env dosyasına Supabase URL ve Anon Key ekle (Config.xcconfig'deki değerler)
npm install
npm run dev
```

## .env Örneği

```
VITE_SUPABASE_URL=https://xxxxx.supabase.co
VITE_SUPABASE_ANON_KEY=your-anon-key
```

## Build & Deploy

```bash
npm run build
# dist/ klasörü Vercel, Netlify veya GitHub Pages'e deploy edilebilir
```

### Vercel (Önerilen)

1. [vercel.com](https://vercel.com) → Import project
2. Root directory: `web`
3. Build command: `npm run build`
4. Output directory: `dist`
5. Environment variables: `VITE_SUPABASE_URL`, `VITE_SUPABASE_ANON_KEY`

### GitHub Pages

`vite.config.js` içinde `base: '/mindshelf/'` gibi repo adına göre ayarla.
GitHub Actions ile `npm run build` sonrası `dist` deploy edilebilir.

## Supabase Redirect URL

Web app için Supabase Dashboard → Authentication → URL Configuration:
- **Site URL**: `https://your-domain.com`
- **Redirect URLs**: `https://your-domain.com/**` ekle

## App Store

Web versiyonu App Store için sorun oluşturmaz. Birçok uygulama (Notion, Spotify vb.) hem iOS hem web sunuyor.
