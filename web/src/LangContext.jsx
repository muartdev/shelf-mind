import { createContext, useContext, useState, useEffect } from 'react'

const translations = {
  en: {
    // Nav
    'nav.openApp': 'Open App',
    'nav.myBookmarks': 'My Bookmarks',
    'nav.signOut': 'Sign out',
    'nav.signIn': 'Sign In',
    'nav.getStarted': 'Get Started',

    // Landing
    'landing.hero': 'Save and organize your',
    'landing.heroHighlight': 'favorite content',
    'landing.subtitle': 'MindShelf is a beautiful bookmark manager. Access your bookmarks on iOS and web with the same account.',
    'landing.cta': 'Sign In to Web App',
    'landing.download': 'Download for iOS',
    'landing.feature1.title': 'Smart Organization',
    'landing.feature1.desc': 'Categories for X, Instagram, YouTube, articles and more.',
    'landing.feature2.title': 'Cloud Sync',
    'landing.feature2.desc': 'Same account on iOS and web. Your bookmarks everywhere.',
    'landing.feature3.title': 'Beautiful UI',
    'landing.feature3.desc': 'Modern design with themes. A joy to use.',
    'landing.stat1': 'Free',
    'landing.stat1.label': 'Web Access',
    'landing.stat2': 'iOS + Web',
    'landing.stat2.label': 'Cross Platform',
    'landing.stat3': 'Real-time',
    'landing.stat3.label': 'Cloud Sync',

    // Bookmarks
    'bookmarks.title': 'Bookmarks',
    'bookmarks.total': 'total',
    'bookmarks.read': 'read',
    'bookmarks.favorites': 'favorites',
    'bookmarks.add': 'Add Bookmark',
    'bookmarks.adding': 'Adding...',
    'bookmarks.search': 'Search bookmarks...',
    'bookmarks.all': 'All',
    'bookmarks.noMatch': 'No bookmarks match your search',
    'bookmarks.tryDifferent': 'Try a different search term',
    'bookmarks.empty': 'No bookmarks yet',
    'bookmarks.emptyHint': 'Add one above or use the iOS app',
    'bookmarks.cancel': 'Cancel',
    'bookmarks.titleOptional': 'Title (optional)',
    'bookmarks.markRead': 'Mark read',
    'bookmarks.markUnread': 'Mark unread',
    'bookmarks.delete': 'Delete',
    'bookmarks.deleteConfirm': 'Delete this bookmark?',
    'bookmarks.favorite': 'Favorite',
    'bookmarks.loading': 'Loading...',

    // Categories
    'category.general': 'General',
    'category.x': 'X (Twitter)',
    'category.instagram': 'Instagram',
    'category.youtube': 'YouTube',
    'category.article': 'Article',
    'category.video': 'Video',

    // Login
    'login.back': 'Back to MindShelf',
    'login.welcome': 'Welcome back',
    'login.create': 'Create account',
    'login.subtitle': 'Use the same account as the iOS app',
    'login.name': 'Name',
    'login.namePlaceholder': 'Your name',
    'login.email': 'Email',
    'login.emailPlaceholder': 'you@example.com',
    'login.password': 'Password',
    'login.signIn': 'Sign In',
    'login.signUp': 'Create Account',
    'login.wait': 'Please wait...',
    'login.checkEmail': 'We sent a verification code to your email.',
    'login.verifyTitle': 'Verify Email',
    'login.verifySubtitle': 'Enter the 6-digit code from your email',
    'login.verifySentTo': 'Code sent to',
    'login.verify': 'Verify',
    'login.changeEmail': 'Change email',
    'login.resend': 'Resend code',
    'login.resent': 'Code sent again! Check your inbox.',
    'login.resendWait': 'Resend in',
    'login.hasAccount': 'Already have an account? ',
    'login.noAccount': "Don't have an account? ",
    'login.signInLink': 'Sign in',
    'login.signUpLink': 'Sign up',

    // Settings
    'settings.title': 'Settings',
    'settings.theme': 'Theme',
    'settings.language': 'Language',
    'settings.light': 'Light',
    'settings.dark': 'Dark',

    // Footer
    'footer.copyright': '© 2026 MindShelf · Ideloc Studio',
    'footer.privacy': 'Privacy',
    'footer.contact': 'Contact',
  },
  tr: {
    // Nav
    'nav.openApp': 'Uygulamayı Aç',
    'nav.myBookmarks': 'Yer İmlerim',
    'nav.signOut': 'Çıkış Yap',
    'nav.signIn': 'Giriş Yap',
    'nav.getStarted': 'Başla',

    // Landing
    'landing.hero': 'Favori içeriklerini',
    'landing.heroHighlight': 'kaydet ve düzenle',
    'landing.subtitle': 'MindShelf güzel bir yer imi yöneticisidir. Yer imlerine iOS ve web\'den aynı hesapla erişin.',
    'landing.cta': 'Web Uygulamasına Giriş Yap',
    'landing.download': 'iOS için İndir',
    'landing.feature1.title': 'Akıllı Organizasyon',
    'landing.feature1.desc': 'X, Instagram, YouTube, makaleler ve daha fazlası için kategoriler.',
    'landing.feature2.title': 'Bulut Senkronizasyonu',
    'landing.feature2.desc': 'iOS ve web\'de aynı hesap. Yer imleriniz her yerde.',
    'landing.feature3.title': 'Güzel Arayüz',
    'landing.feature3.desc': 'Temalarla modern tasarım. Kullanması zevkli.',
    'landing.stat1': 'Ücretsiz',
    'landing.stat1.label': 'Web Erişim',
    'landing.stat2': 'iOS + Web',
    'landing.stat2.label': 'Çapraz Platform',
    'landing.stat3': 'Gerçek Zamanlı',
    'landing.stat3.label': 'Bulut Senk.',

    // Bookmarks
    'bookmarks.title': 'Yer İmleri',
    'bookmarks.total': 'toplam',
    'bookmarks.read': 'okundu',
    'bookmarks.favorites': 'favori',
    'bookmarks.add': 'Yer İmi Ekle',
    'bookmarks.adding': 'Ekleniyor...',
    'bookmarks.search': 'Yer imlerini ara...',
    'bookmarks.all': 'Tümü',
    'bookmarks.noMatch': 'Aramanızla eşleşen yer imi yok',
    'bookmarks.tryDifferent': 'Farklı bir arama terimi deneyin',
    'bookmarks.empty': 'Henüz yer imi yok',
    'bookmarks.emptyHint': 'Yukarıdan ekleyin veya iOS uygulamasını kullanın',
    'bookmarks.cancel': 'İptal',
    'bookmarks.titleOptional': 'Başlık (isteğe bağlı)',
    'bookmarks.markRead': 'Okundu işaretle',
    'bookmarks.markUnread': 'Okunmadı işaretle',
    'bookmarks.delete': 'Sil',
    'bookmarks.deleteConfirm': 'Bu yer imini silmek istiyor musunuz?',
    'bookmarks.favorite': 'Favori',
    'bookmarks.loading': 'Yükleniyor...',

    // Categories
    'category.general': 'Genel',
    'category.x': 'X (Twitter)',
    'category.instagram': 'Instagram',
    'category.youtube': 'YouTube',
    'category.article': 'Makale',
    'category.video': 'Video',

    // Login
    'login.back': 'MindShelf\'e Dön',
    'login.welcome': 'Tekrar hoş geldiniz',
    'login.create': 'Hesap oluştur',
    'login.subtitle': 'iOS uygulamasıyla aynı hesabı kullanın',
    'login.name': 'Ad',
    'login.namePlaceholder': 'Adınız',
    'login.email': 'E-posta',
    'login.emailPlaceholder': 'siz@ornek.com',
    'login.password': 'Şifre',
    'login.signIn': 'Giriş Yap',
    'login.signUp': 'Hesap Oluştur',
    'login.wait': 'Lütfen bekleyin...',
    'login.checkEmail': 'E-postanıza doğrulama kodu gönderdik.',
    'login.verifyTitle': 'E-posta Doğrula',
    'login.verifySubtitle': 'E-postanızdaki 6 haneli kodu girin',
    'login.verifySentTo': 'Kod gönderildi:',
    'login.verify': 'Doğrula',
    'login.changeEmail': 'E-posta değiştir',
    'login.resend': 'Kodu tekrar gönder',
    'login.resent': 'Kod tekrar gönderildi! Gelen kutunuzu kontrol edin.',
    'login.resendWait': 'Tekrar gönder',
    'login.hasAccount': 'Zaten hesabınız var mı? ',
    'login.noAccount': 'Hesabınız yok mu? ',
    'login.signInLink': 'Giriş yap',
    'login.signUpLink': 'Kayıt ol',

    // Settings
    'settings.title': 'Ayarlar',
    'settings.theme': 'Tema',
    'settings.language': 'Dil',
    'settings.light': 'Açık',
    'settings.dark': 'Koyu',

    // Footer
    'footer.copyright': '© 2026 MindShelf · Ideloc Studio',
    'footer.privacy': 'Gizlilik',
    'footer.contact': 'İletişim',
  },
}

const LangContext = createContext()

export function LangProvider({ children }) {
  const [lang, setLang] = useState(() => localStorage.getItem('mindshelf-lang') || 'en')

  useEffect(() => {
    localStorage.setItem('mindshelf-lang', lang)
    document.documentElement.lang = lang
  }, [lang])

  function t(key) {
    return translations[lang]?.[key] || translations.en[key] || key
  }

  return (
    <LangContext.Provider value={{ lang, setLang, t }}>
      {children}
    </LangContext.Provider>
  )
}

export function useLang() {
  return useContext(LangContext)
}
