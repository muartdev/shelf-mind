import { useState } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import { supabase } from '../supabase'
import { useTheme } from '../ThemeContext'
import { useLang } from '../LangContext'

export default function Login() {
  const { theme } = useTheme()
  const { t } = useLang()
  const [isSignUp, setIsSignUp] = useState(false)
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [name, setName] = useState('')
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')
  const [message, setMessage] = useState('')
  const navigate = useNavigate()

  async function handleSubmit(e) {
    e.preventDefault()
    setError('')
    setMessage('')
    setLoading(true)

    try {
      if (isSignUp) {
        const { error } = await supabase.auth.signUp({ email, password, options: { data: { name } } })
        if (error) throw error
        setMessage(t('login.checkEmail'))
      } else {
        const { error } = await supabase.auth.signInWithPassword({ email, password })
        if (error) throw error
        navigate('/app')
      }
    } catch (err) {
      setError(err.message || 'Something went wrong')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className={`min-h-screen flex items-center justify-center px-4 py-8 ${theme.bg} relative overflow-hidden`}>
      <div className="absolute top-1/4 left-1/2 -translate-x-1/2 w-72 sm:w-96 h-72 sm:h-96 rounded-full blur-3xl pointer-events-none" style={{ background: `${theme.primary}10` }} />

      <div className="w-full max-w-md relative">
        <Link to="/" className="inline-flex items-center gap-1 mb-6 sm:mb-8 text-sm no-underline transition" style={{ color: theme.primary }}>
          <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
            <path strokeLinecap="round" strokeLinejoin="round" d="M15.75 19.5L8.25 12l7.5-7.5" />
          </svg>
          {t('login.back')}
        </Link>
        <div className={`p-6 sm:p-8 rounded-2xl ${theme.cardBg} border ${theme.cardBorder} backdrop-blur-xl shadow-2xl`}>
          {/* Logo */}
          <div className="flex items-center gap-3 mb-5 sm:mb-6">
            <img src="/icon.png" alt="MindShelf" className="w-10 h-10 rounded-xl shadow-lg" />
            <div>
              <h1 className={`text-lg sm:text-xl font-bold ${theme.text}`}>
                {isSignUp ? t('login.create') : t('login.welcome')}
              </h1>
              <p className={`text-xs sm:text-sm ${theme.textMuted}`}>
                {t('login.subtitle')}
              </p>
            </div>
          </div>

          <form onSubmit={handleSubmit} className="space-y-3.5 sm:space-y-4">
            {isSignUp && (
              <div>
                <label className={`block text-sm font-medium ${theme.textSecondary} mb-1.5`}>{t('login.name')}</label>
                <input
                  type="text"
                  value={name}
                  onChange={(e) => setName(e.target.value)}
                  className={`w-full px-4 py-3 rounded-xl ${theme.inputBg} border ${theme.inputBorder} ${theme.text} placeholder-gray-400 focus:outline-none focus:ring-2 ${theme.inputFocus} transition text-sm`}
                  placeholder={t('login.namePlaceholder')}
                  required={isSignUp}
                />
              </div>
            )}
            <div>
              <label className={`block text-sm font-medium ${theme.textSecondary} mb-1.5`}>{t('login.email')}</label>
              <input
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                className={`w-full px-4 py-3 rounded-xl ${theme.inputBg} border ${theme.inputBorder} ${theme.text} placeholder-gray-400 focus:outline-none focus:ring-2 ${theme.inputFocus} transition text-sm`}
                placeholder={t('login.emailPlaceholder')}
                required
              />
            </div>
            <div>
              <label className={`block text-sm font-medium ${theme.textSecondary} mb-1.5`}>{t('login.password')}</label>
              <input
                type="password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                className={`w-full px-4 py-3 rounded-xl ${theme.inputBg} border ${theme.inputBorder} ${theme.text} placeholder-gray-400 focus:outline-none focus:ring-2 ${theme.inputFocus} transition text-sm`}
                placeholder="••••••••"
                required
                minLength={6}
              />
            </div>
            {error && (
              <div className="flex items-start gap-2 text-red-500 text-xs sm:text-sm bg-red-500/10 border border-red-500/20 rounded-xl px-3.5 py-2.5">
                <svg className="w-4 h-4 flex-shrink-0 mt-0.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                  <path strokeLinecap="round" strokeLinejoin="round" d="M12 9v3.75m9-.75a9 9 0 11-18 0 9 9 0 0118 0zm-9 3.75h.008v.008H12v-.008z" />
                </svg>
                {error}
              </div>
            )}
            {message && (
              <div className="flex items-start gap-2 text-green-500 text-xs sm:text-sm bg-green-500/10 border border-green-500/20 rounded-xl px-3.5 py-2.5">
                <svg className="w-4 h-4 flex-shrink-0 mt-0.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                  <path strokeLinecap="round" strokeLinejoin="round" d="M9 12.75L11.25 15 15 9.75M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                </svg>
                {message}
              </div>
            )}
            <button
              type="submit"
              disabled={loading}
              className={`w-full py-3 rounded-xl ${theme.btnPrimary} text-white font-semibold text-sm sm:text-base transition-all hover:shadow-lg disabled:opacity-50`}
            >
              {loading ? t('login.wait') : isSignUp ? t('login.signUp') : t('login.signIn')}
            </button>
          </form>
          <div className={`mt-4 sm:mt-5 pt-4 sm:pt-5 border-t ${theme.cardBorder} text-center`}>
            <button
              type="button"
              onClick={() => { setIsSignUp(!isSignUp); setError(''); setMessage('') }}
              className={`text-xs sm:text-sm ${theme.textSecondary} transition`}
            >
              {isSignUp ? t('login.hasAccount') : t('login.noAccount')}
              <span className="font-medium" style={{ color: theme.primary }}>{isSignUp ? t('login.signInLink') : t('login.signUpLink')}</span>
            </button>
          </div>
        </div>
      </div>
    </div>
  )
}
