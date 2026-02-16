import { useState, useRef, useEffect } from 'react'
import { createPortal } from 'react-dom'
import { useTheme } from '../ThemeContext'
import { useLang } from '../LangContext'

export default function SettingsDropdown() {
  const { theme, themeId, setThemeId, themes } = useTheme()
  const { lang, setLang, t } = useLang()
  const [open, setOpen] = useState(false)
  const btnRef = useRef(null)
  const panelRef = useRef(null)

  useEffect(() => {
    if (!open) return
    function handleClick(e) {
      if (btnRef.current?.contains(e.target)) return
      if (panelRef.current?.contains(e.target)) return
      setOpen(false)
    }
    document.addEventListener('mousedown', handleClick)
    return () => document.removeEventListener('mousedown', handleClick)
  }, [open])

  // Lock body scroll on mobile when open
  useEffect(() => {
    if (open && window.innerWidth < 640) {
      document.body.style.overflow = 'hidden'
      return () => { document.body.style.overflow = '' }
    }
  }, [open])

  const themeList = [
    { id: 'orangePinkLight', mode: 'light' },
    { id: 'bluePurpleLight', mode: 'light' },
    { id: 'orangePinkDark', mode: 'dark' },
    { id: 'bluePurpleDark', mode: 'dark' },
  ]

  // Calculate desktop dropdown position
  const [pos, setPos] = useState({ top: 0, right: 0 })
  useEffect(() => {
    if (open && btnRef.current && window.innerWidth >= 640) {
      const rect = btnRef.current.getBoundingClientRect()
      setPos({
        top: rect.bottom + 8,
        right: window.innerWidth - rect.right,
      })
    }
  }, [open])

  const dropdown = open ? createPortal(
    <>
      {/* Overlay */}
      <div
        className="fixed inset-0 z-[998] sm:bg-transparent bg-black/30"
        onClick={() => setOpen(false)}
      />

      {/* Panel */}
      <div
        ref={panelRef}
        className={`
          fixed z-[999]
          inset-x-0 bottom-0
          sm:inset-auto sm:bottom-auto
          w-full sm:w-64
          rounded-t-2xl sm:rounded-2xl
          ${theme.mode === 'dark' ? 'bg-slate-800 border-slate-700' : 'bg-white border-gray-200'}
          border shadow-2xl p-4 space-y-4
        `}
        style={window.innerWidth >= 640 ? { top: pos.top, right: pos.right, position: 'fixed' } : undefined}
      >
        {/* Handle bar - mobile only */}
        <div className="flex justify-center sm:hidden mb-1">
          <div className={`w-10 h-1 rounded-full ${theme.mode === 'dark' ? 'bg-slate-600' : 'bg-gray-300'}`} />
        </div>

        {/* Theme */}
        <div>
          <div className={`text-xs font-semibold uppercase tracking-wider ${theme.textMuted} mb-2`}>{t('settings.theme')}</div>
          <div className="grid grid-cols-2 gap-2">
            {themeList.map((item) => {
              const th = themes[item.id]
              const isActive = themeId === item.id
              return (
                <button
                  key={item.id}
                  onClick={() => setThemeId(item.id)}
                  className={`flex items-center gap-2 px-3 py-2.5 sm:py-2 rounded-xl text-sm font-medium transition-all ${
                    isActive
                      ? `ring-2 ${theme.mode === 'dark' ? 'bg-slate-700 ring-white/20' : 'bg-gray-100 ring-gray-300'}`
                      : `${theme.mode === 'dark' ? 'hover:bg-slate-700/50' : 'hover:bg-gray-50'}`
                  }`}
                >
                  <span
                    className="w-5 h-5 rounded-full flex-shrink-0"
                    style={{ background: `linear-gradient(135deg, ${th.primary}, ${th.secondary})` }}
                  />
                  <span className={`${theme.text} text-xs truncate`}>
                    {th.name[lang]} {item.mode === 'dark' ? t('settings.dark') : t('settings.light')}
                  </span>
                </button>
              )
            })}
          </div>
        </div>

        {/* Language */}
        <div>
          <div className={`text-xs font-semibold uppercase tracking-wider ${theme.textMuted} mb-2`}>{t('settings.language')}</div>
          <div className="flex gap-2">
            {[
              { code: 'en', flag: '🇺🇸', label: 'English' },
              { code: 'tr', flag: '🇹🇷', label: 'Türkçe' },
            ].map((l) => (
              <button
                key={l.code}
                onClick={() => setLang(l.code)}
                className={`flex-1 flex items-center justify-center gap-2 px-3 py-2.5 sm:py-2 rounded-xl text-sm font-medium transition-all ${
                  lang === l.code
                    ? `ring-2 ${theme.mode === 'dark' ? 'bg-slate-700 ring-white/20' : 'bg-gray-100 ring-gray-300'}`
                    : `${theme.mode === 'dark' ? 'hover:bg-slate-700/50' : 'hover:bg-gray-50'}`
                }`}
              >
                <span>{l.flag}</span>
                <span className={theme.text}>{l.label}</span>
              </button>
            ))}
          </div>
        </div>

        {/* Close button - mobile only */}
        <button
          onClick={() => setOpen(false)}
          className={`w-full py-2.5 rounded-xl text-sm font-medium sm:hidden ${theme.mode === 'dark' ? 'bg-slate-700 text-white' : 'bg-gray-100 text-gray-700'}`}
        >
          {t('bookmarks.cancel') || 'Close'}
        </button>
      </div>
    </>,
    document.body
  ) : null

  return (
    <>
      <button
        ref={btnRef}
        onClick={() => setOpen(!open)}
        className={`p-2 rounded-xl ${theme.textSecondary} transition ${open ? theme.cardBg : ''}`}
        title={t('settings.title')}
      >
        <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.8}>
          <path strokeLinecap="round" strokeLinejoin="round" d="M9.594 3.94c.09-.542.56-.94 1.11-.94h2.593c.55 0 1.02.398 1.11.94l.213 1.281c.063.374.313.686.645.87.074.04.147.083.22.127.325.196.72.257 1.075.124l1.217-.456a1.125 1.125 0 011.37.49l1.296 2.247a1.125 1.125 0 01-.26 1.431l-1.003.827c-.293.241-.438.613-.43.992a7.723 7.723 0 010 .255c-.008.378.137.75.43.991l1.004.827c.424.35.534.955.26 1.43l-1.298 2.247a1.125 1.125 0 01-1.369.491l-1.217-.456c-.355-.133-.75-.072-1.076.124a6.47 6.47 0 01-.22.128c-.331.183-.581.495-.644.869l-.213 1.281c-.09.543-.56.941-1.11.941h-2.594c-.55 0-1.019-.398-1.11-.94l-.213-1.281c-.062-.374-.312-.686-.644-.87a6.52 6.52 0 01-.22-.127c-.325-.196-.72-.257-1.076-.124l-1.217.456a1.125 1.125 0 01-1.369-.49l-1.297-2.247a1.125 1.125 0 01.26-1.431l1.004-.827c.292-.24.437-.613.43-.991a6.932 6.932 0 010-.255c.007-.38-.138-.751-.43-.992l-1.004-.827a1.125 1.125 0 01-.26-1.43l1.297-2.247a1.125 1.125 0 011.37-.491l1.216.456c.356.133.751.072 1.076-.124.072-.044.146-.086.22-.128.332-.183.582-.495.644-.869l.214-1.28z" />
          <path strokeLinecap="round" strokeLinejoin="round" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
        </svg>
      </button>
      {dropdown}
    </>
  )
}
