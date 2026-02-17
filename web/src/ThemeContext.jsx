import { createContext, useContext, useState, useEffect } from 'react'

const themes = {
  bluePurpleLight: {
    id: 'bluePurpleLight',
    name: { en: 'Blue Purple', tr: 'Mavi Mor' },
    mode: 'light',
    primary: '#007AFF',
    secondary: '#AF52DE',
    accent: '#007AFF',
    bg: 'bg-gradient-to-br from-blue-50 via-purple-50/30 to-pink-50/20',
    navBg: 'bg-blue-50/80',
    navBorder: 'border-blue-100/60',
    cardBg: 'bg-white/60',
    cardBorder: 'border-gray-200/50',
    cardHover: 'hover:bg-white/80 hover:border-gray-300/60',
    inputBg: 'bg-white/80',
    inputBorder: 'border-gray-300',
    inputFocus: 'focus:ring-blue-500',
    text: 'text-gray-900',
    textSecondary: 'text-gray-500',
    textMuted: 'text-gray-400',
    btnPrimary: 'bg-blue-500 hover:bg-blue-600 shadow-blue-500/25',
    btnSecondary: 'bg-gray-100 hover:bg-gray-200 text-gray-700',
    filterActive: 'bg-blue-500 text-white shadow-blue-500/25',
    filterInactive: 'bg-white/60 text-gray-500 hover:text-gray-700 hover:bg-white/80',
    badge: { general: 'bg-gray-100 text-gray-600 border-gray-200', x: 'bg-gray-100 text-gray-800 border-gray-200', instagram: 'bg-pink-50 text-pink-600 border-pink-200', youtube: 'bg-red-50 text-red-600 border-red-200', article: 'bg-blue-50 text-blue-600 border-blue-200', video: 'bg-purple-50 text-purple-600 border-purple-200' },
    dot: { general: 'bg-gray-400', x: 'bg-gray-800', instagram: 'bg-pink-500', youtube: 'bg-red-500', article: 'bg-blue-500', video: 'bg-purple-500' },
    bodyBg: '#f8f7ff',
    bodyText: '#1a1a2e',
    linkColor: '#007AFF',
  },
  orangePinkLight: {
    id: 'orangePinkLight',
    name: { en: 'Orange Pink', tr: 'Turuncu Pembe' },
    mode: 'light',
    primary: '#FF9500',
    secondary: '#FF2D55',
    accent: '#FF9500',
    bg: 'bg-gradient-to-br from-orange-50 via-pink-50/30 to-rose-50/20',
    navBg: 'bg-orange-50/80',
    navBorder: 'border-orange-200/40',
    cardBg: 'bg-white/60',
    cardBorder: 'border-orange-200/30',
    cardHover: 'hover:bg-white/80 hover:border-orange-300/40',
    inputBg: 'bg-white/80',
    inputBorder: 'border-orange-200',
    inputFocus: 'focus:ring-orange-500',
    text: 'text-gray-900',
    textSecondary: 'text-gray-500',
    textMuted: 'text-gray-400',
    btnPrimary: 'bg-orange-500 hover:bg-orange-600 shadow-orange-500/25',
    btnSecondary: 'bg-orange-50 hover:bg-orange-100 text-orange-700',
    filterActive: 'bg-orange-500 text-white shadow-orange-500/25',
    filterInactive: 'bg-white/60 text-gray-500 hover:text-gray-700 hover:bg-white/80',
    badge: { general: 'bg-gray-100 text-gray-600 border-gray-200', x: 'bg-gray-100 text-gray-800 border-gray-200', instagram: 'bg-pink-50 text-pink-600 border-pink-200', youtube: 'bg-red-50 text-red-600 border-red-200', article: 'bg-blue-50 text-blue-600 border-blue-200', video: 'bg-purple-50 text-purple-600 border-purple-200' },
    dot: { general: 'bg-gray-400', x: 'bg-gray-800', instagram: 'bg-pink-500', youtube: 'bg-red-500', article: 'bg-blue-500', video: 'bg-purple-500' },
    bodyBg: '#fff8f0',
    bodyText: '#2a1a0e',
    linkColor: '#FF9500',
  },
  bluePurpleDark: {
    id: 'bluePurpleDark',
    name: { en: 'Blue Purple', tr: 'Mavi Mor' },
    mode: 'dark',
    primary: '#007AFF',
    secondary: '#AF52DE',
    accent: '#007AFF',
    bg: 'bg-gradient-to-br from-slate-950 via-indigo-950/30 to-purple-950/20',
    navBg: 'bg-slate-900/80',
    navBorder: 'border-slate-700/50',
    cardBg: 'bg-slate-800/50',
    cardBorder: 'border-slate-700/40',
    cardHover: 'hover:bg-slate-800/70 hover:border-slate-600/50',
    inputBg: 'bg-slate-800/80',
    inputBorder: 'border-slate-600',
    inputFocus: 'focus:ring-blue-500',
    text: 'text-white',
    textSecondary: 'text-slate-400',
    textMuted: 'text-slate-500',
    btnPrimary: 'bg-blue-500 hover:bg-blue-600 shadow-blue-500/25',
    btnSecondary: 'bg-slate-800 hover:bg-slate-700 text-slate-300',
    filterActive: 'bg-blue-500 text-white shadow-blue-500/25',
    filterInactive: 'bg-slate-800/60 text-slate-400 hover:text-white hover:bg-slate-700/60',
    badge: { general: 'bg-slate-700/50 text-slate-300 border-slate-600/50', x: 'bg-sky-500/20 text-sky-300 border-sky-500/30', instagram: 'bg-pink-500/20 text-pink-300 border-pink-500/30', youtube: 'bg-red-500/20 text-red-300 border-red-500/30', article: 'bg-blue-500/20 text-blue-300 border-blue-500/30', video: 'bg-purple-500/20 text-purple-300 border-purple-500/30' },
    dot: { general: 'bg-slate-400', x: 'bg-sky-400', instagram: 'bg-pink-400', youtube: 'bg-red-400', article: 'bg-blue-400', video: 'bg-purple-400' },
    bodyBg: '#0c0c14',
    bodyText: '#e4e4e7',
    linkColor: '#818cf8',
  },
  orangePinkDark: {
    id: 'orangePinkDark',
    name: { en: 'Orange Pink', tr: 'Turuncu Pembe' },
    mode: 'dark',
    primary: '#FF9500',
    secondary: '#FF2D55',
    accent: '#FF9500',
    bg: 'bg-gradient-to-br from-slate-950 via-orange-950/20 to-rose-950/10',
    navBg: 'bg-slate-900/80',
    navBorder: 'border-slate-700/50',
    cardBg: 'bg-slate-800/50',
    cardBorder: 'border-slate-700/40',
    cardHover: 'hover:bg-slate-800/70 hover:border-slate-600/50',
    inputBg: 'bg-slate-800/80',
    inputBorder: 'border-slate-600',
    inputFocus: 'focus:ring-orange-500',
    text: 'text-white',
    textSecondary: 'text-slate-400',
    textMuted: 'text-slate-500',
    btnPrimary: 'bg-orange-500 hover:bg-orange-600 shadow-orange-500/25',
    btnSecondary: 'bg-slate-800 hover:bg-slate-700 text-slate-300',
    filterActive: 'bg-orange-500 text-white shadow-orange-500/25',
    filterInactive: 'bg-slate-800/60 text-slate-400 hover:text-white hover:bg-slate-700/60',
    badge: { general: 'bg-slate-700/50 text-slate-300 border-slate-600/50', x: 'bg-sky-500/20 text-sky-300 border-sky-500/30', instagram: 'bg-pink-500/20 text-pink-300 border-pink-500/30', youtube: 'bg-red-500/20 text-red-300 border-red-500/30', article: 'bg-blue-500/20 text-blue-300 border-blue-500/30', video: 'bg-purple-500/20 text-purple-300 border-purple-500/30' },
    dot: { general: 'bg-slate-400', x: 'bg-sky-400', instagram: 'bg-pink-400', youtube: 'bg-red-400', article: 'bg-blue-400', video: 'bg-purple-400' },
    bodyBg: '#0f0a08',
    bodyText: '#e4e4e7',
    linkColor: '#FF9500',
  },
}

const ThemeContext = createContext()

export function ThemeProvider({ children }) {
  const [themeId, setThemeId] = useState(() => localStorage.getItem('mindshelf-theme') || 'orangePinkLight')
  const theme = themes[themeId] || themes.orangePinkLight

  useEffect(() => {
    localStorage.setItem('mindshelf-theme', themeId)
    document.body.style.background = theme.bodyBg
    document.body.style.color = theme.bodyText
  }, [themeId, theme])

  return (
    <ThemeContext.Provider value={{ theme, themeId, setThemeId, themes }}>
      {children}
    </ThemeContext.Provider>
  )
}

export function useTheme() {
  return useContext(ThemeContext)
}
