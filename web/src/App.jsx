import { Routes, Route, Navigate } from 'react-router-dom'
import { useEffect, useState } from 'react'
import { supabase, isConfigured } from './supabase'
import { ThemeProvider } from './ThemeContext'
import { LangProvider } from './LangContext'
import Landing from './pages/Landing'
import Login from './pages/Login'
import Bookmarks from './pages/Bookmarks'

function App() {
  const [user, setUser] = useState(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    if (!supabase) {
      setLoading(false)
      return
    }
    supabase.auth.getSession().then(({ data: { session } }) => {
      setUser(session?.user ?? null)
      setLoading(false)
    }).catch(() => setLoading(false))
    const { data: { subscription } } = supabase.auth.onAuthStateChange((_event, session) => {
      setUser(session?.user ?? null)
    })
    return () => subscription.unsubscribe()
  }, [])

  if (!isConfigured()) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-slate-900 p-6">
        <div className="max-w-md text-center">
          <h1 className="text-xl font-bold text-white mb-2">Configuration Required</h1>
          <p className="text-slate-400 mb-4">
            Create <code className="bg-slate-800 px-2 py-1 rounded">web/.env</code> with:
          </p>
          <pre className="text-left text-sm text-slate-300 bg-slate-800 p-4 rounded-xl overflow-x-auto">
{`VITE_SUPABASE_URL=https://xxx.supabase.co
VITE_SUPABASE_ANON_KEY=your-anon-key`}
          </pre>
          <p className="text-slate-500 text-sm mt-4">Copy from Config.xcconfig (SUPABASE_URL, SUPABASE_ANON_KEY)</p>
        </div>
      </div>
    )
  }

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="animate-pulse text-gray-400">Loading...</div>
      </div>
    )
  }

  return (
    <ThemeProvider>
      <LangProvider>
        <Routes>
          <Route path="/" element={<Landing user={user} />} />
          <Route path="/login" element={user ? <Navigate to="/app" /> : <Login />} />
          <Route path="/app" element={user ? <Bookmarks user={user} /> : <Navigate to="/login" />} />
          <Route path="*" element={<Navigate to="/" />} />
        </Routes>
      </LangProvider>
    </ThemeProvider>
  )
}

export default App
