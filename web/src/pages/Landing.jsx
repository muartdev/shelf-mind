import { Link } from 'react-router-dom'
import { supabase } from '../supabase'
import { useTheme } from '../ThemeContext'
import { useLang } from '../LangContext'
import SettingsDropdown from '../components/SettingsDropdown'

export default function Landing({ user }) {
  const { theme } = useTheme()
  const { t } = useLang()

  async function signOut() {
    await supabase.auth.signOut()
  }

  return (
    <div className={`min-h-screen ${theme.bg}`}>
      {/* Navbar */}
      <nav className="flex items-center justify-between px-4 sm:px-6 py-3 max-w-6xl mx-auto">
        <div className="flex items-center gap-2">
          <img src="/icon.png" alt="MindShelf" className="w-8 h-8 rounded-xl" />
          <span className={`text-lg sm:text-xl font-bold ${theme.text} tracking-tight`}>MindShelf</span>
        </div>
        <div className="flex items-center gap-1.5 sm:gap-3">
          <SettingsDropdown />
          {user ? (
            <>
              <span className={`text-xs sm:text-sm ${theme.textMuted} hidden sm:inline max-w-[160px] truncate`}>{user.email}</span>
              <Link
                to="/app"
                className={`px-3 sm:px-4 py-2 rounded-xl ${theme.btnPrimary} text-white text-sm font-medium transition-all hover:shadow-lg no-underline`}
              >
                {t('nav.myBookmarks')}
              </Link>
              <button
                onClick={signOut}
                className={`px-2 sm:px-4 py-2 text-xs sm:text-sm ${theme.textSecondary} transition`}
              >
                {t('nav.signOut')}
              </button>
            </>
          ) : (
            <>
              <Link to="/login" className={`px-3 py-2 text-sm ${theme.textSecondary} transition hidden sm:block`}>
                {t('nav.signIn')}
              </Link>
              <Link
                to="/login"
                className={`px-3 sm:px-4 py-2 rounded-xl ${theme.btnPrimary} text-white text-sm font-medium transition-all hover:shadow-lg`}
              >
                {t('nav.getStarted')}
              </Link>
            </>
          )}
        </div>
      </nav>

      <main className="max-w-6xl mx-auto px-5 sm:px-6 pt-12 sm:pt-24 pb-20 sm:pb-32">
        {/* Hero */}
        <div className="text-center max-w-3xl mx-auto relative">
          <div className="absolute -top-20 left-1/2 -translate-x-1/2 w-64 sm:w-96 h-64 sm:h-96 rounded-full blur-3xl pointer-events-none" style={{ background: `${theme.primary}15` }} />
          <div className="absolute -top-10 left-1/3 w-40 sm:w-64 h-40 sm:h-64 rounded-full blur-3xl pointer-events-none" style={{ background: `${theme.secondary}10` }} />

          <h1 className={`relative text-3xl sm:text-5xl md:text-6xl font-bold ${theme.text} leading-tight tracking-tight`}>
            {t('landing.hero')}{' '}
            <span className="bg-clip-text text-transparent" style={{ backgroundImage: `linear-gradient(135deg, ${theme.primary}, ${theme.secondary})` }}>
              {t('landing.heroHighlight')}
            </span>
          </h1>
          <p className={`relative mt-4 sm:mt-6 text-base sm:text-xl ${theme.textSecondary} leading-relaxed px-2`}>
            {t('landing.subtitle')}
          </p>
          <div className="relative mt-8 sm:mt-10 flex flex-col sm:flex-row gap-3 sm:gap-4 justify-center px-4 sm:px-0">
            {user ? (
              <Link
                to="/app"
                className="px-6 sm:px-8 py-3.5 sm:py-4 rounded-2xl text-white font-semibold text-base sm:text-lg shadow-lg transition-all hover:-translate-y-0.5 hover:shadow-xl text-center no-underline"
                style={{ background: `linear-gradient(135deg, ${theme.primary}, ${theme.secondary})` }}
              >
                {t('nav.myBookmarks')}
              </Link>
            ) : (
              <Link
                to="/login"
                className="px-6 sm:px-8 py-3.5 sm:py-4 rounded-2xl text-white font-semibold text-base sm:text-lg shadow-lg transition-all hover:-translate-y-0.5 hover:shadow-xl text-center no-underline"
                style={{ background: `linear-gradient(135deg, ${theme.primary}, ${theme.secondary})` }}
              >
                {t('landing.cta')}
              </Link>
            )}
            <a
              href="https://apps.apple.com/app/mindshelf"
              target="_blank"
              rel="noopener noreferrer"
              className={`inline-flex items-center justify-center gap-2 px-6 sm:px-8 py-3.5 sm:py-4 rounded-2xl ${theme.cardBg} border ${theme.cardBorder} ${theme.text} font-semibold text-base sm:text-lg transition-all hover:-translate-y-0.5 backdrop-blur no-underline`}
            >
              <svg className="w-5 h-5 sm:w-6 sm:h-6" viewBox="0 0 24 24" fill="currentColor">
                <path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.81-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M13 3.5c.73-.83 1.94-1.46 2.94-1.5.13 1.17-.34 2.35-1.04 3.19-.69.85-1.83 1.51-2.95 1.42-.15-1.15.41-2.35 1.05-3.11z"/>
              </svg>
              {t('landing.download')}
            </a>
          </div>
        </div>

        {/* Features */}
        <div className="mt-16 sm:mt-28 grid grid-cols-1 sm:grid-cols-3 gap-4 sm:gap-6">
          {[
            {
              icon: (
                <svg className="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.5}>
                  <path strokeLinecap="round" strokeLinejoin="round" d="M3.75 6A2.25 2.25 0 016 3.75h2.25A2.25 2.25 0 0110.5 6v2.25a2.25 2.25 0 01-2.25 2.25H6a2.25 2.25 0 01-2.25-2.25V6zM3.75 15.75A2.25 2.25 0 016 13.5h2.25a2.25 2.25 0 012.25 2.25V18a2.25 2.25 0 01-2.25 2.25H6A2.25 2.25 0 013.75 18v-2.25zM13.5 6a2.25 2.25 0 012.25-2.25H18A2.25 2.25 0 0120.25 6v2.25A2.25 2.25 0 0118 10.5h-2.25a2.25 2.25 0 01-2.25-2.25V6zM13.5 15.75a2.25 2.25 0 012.25-2.25H18a2.25 2.25 0 012.25 2.25V18A2.25 2.25 0 0118 20.25h-2.25A2.25 2.25 0 0113.5 18v-2.25z" />
                </svg>
              ),
              title: t('landing.feature1.title'), desc: t('landing.feature1.desc'),
            },
            {
              icon: (
                <svg className="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.5}>
                  <path strokeLinecap="round" strokeLinejoin="round" d="M2.25 15a4.5 4.5 0 004.5 4.5H18a3.75 3.75 0 001.332-7.257 3 3 0 00-3.758-3.848 5.25 5.25 0 00-10.233 2.33A4.502 4.502 0 002.25 15z" />
                  <path strokeLinecap="round" strokeLinejoin="round" d="M16.5 12L12 16.5m0 0L7.5 12m4.5 4.5V3" style={{ transform: 'rotate(180deg)', transformOrigin: '12px 12px' }} />
                </svg>
              ),
              title: t('landing.feature2.title'), desc: t('landing.feature2.desc'),
            },
            {
              icon: (
                <svg className="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.5}>
                  <path strokeLinecap="round" strokeLinejoin="round" d="M9.53 16.122a3 3 0 00-5.78 1.128 2.25 2.25 0 01-2.4 2.245 4.5 4.5 0 008.4-2.245c0-.399-.078-.78-.22-1.128zm0 0a15.998 15.998 0 003.388-1.62m-5.043-.025a15.994 15.994 0 011.622-3.395m3.42 3.42a15.995 15.995 0 004.764-4.648l3.876-5.814a1.151 1.151 0 00-1.597-1.597L14.146 6.32a15.996 15.996 0 00-4.649 4.763m3.42 3.42a6.776 6.776 0 00-3.42-3.42" />
                </svg>
              ),
              title: t('landing.feature3.title'), desc: t('landing.feature3.desc'),
            },
          ].map((f) => (
            <div
              key={f.title}
              className={`group flex sm:flex-col items-center sm:items-start gap-4 sm:gap-0 p-4 sm:p-6 rounded-2xl ${theme.cardBg} border ${theme.cardBorder} ${theme.cardHover} transition-all duration-300 hover:-translate-y-1 hover:shadow-lg backdrop-blur`}
            >
              <div className="w-11 h-11 sm:w-12 sm:h-12 rounded-xl flex items-center justify-center sm:mb-4 flex-shrink-0 group-hover:scale-110 transition-transform duration-300" style={{ background: `${theme.primary}15`, color: theme.primary }}>
                {f.icon}
              </div>
              <div>
                <h3 className={`text-base sm:text-lg font-semibold ${theme.text}`}>{f.title}</h3>
                <p className={`mt-1 sm:mt-2 text-sm sm:text-base ${theme.textSecondary} leading-relaxed`}>{f.desc}</p>
              </div>
            </div>
          ))}
        </div>

        {/* Stats */}
        <div className="mt-14 sm:mt-20 flex justify-center gap-8 sm:gap-12 text-center">
          {[
            { value: t('landing.stat1'), label: t('landing.stat1.label') },
            { value: t('landing.stat2'), label: t('landing.stat2.label') },
            { value: t('landing.stat3'), label: t('landing.stat3.label') },
          ].map((s) => (
            <div key={s.label}>
              <div className={`text-xl sm:text-3xl font-bold ${theme.text}`}>{s.value}</div>
              <div className={`mt-0.5 text-xs sm:text-sm ${theme.textMuted}`}>{s.label}</div>
            </div>
          ))}
        </div>
      </main>

      {/* Footer */}
      <footer className={`border-t ${theme.cardBorder} py-6 sm:py-8`}>
        <div className="max-w-6xl mx-auto px-5 sm:px-6 flex flex-col sm:flex-row justify-between items-center gap-3">
          <span className={`${theme.textMuted} text-xs sm:text-sm`}>{t('footer.copyright')}</span>
          <div className="flex gap-6">
            <a href="https://muartdev.github.io/mindshelf-privacy/" className={`text-xs sm:text-sm ${theme.textMuted} transition`}>{t('footer.privacy')}</a>
            <a href="mailto:ideloc.studio@gmail.com" className={`text-xs sm:text-sm ${theme.textMuted} transition`}>{t('footer.contact')}</a>
          </div>
        </div>
      </footer>
    </div>
  )
}
