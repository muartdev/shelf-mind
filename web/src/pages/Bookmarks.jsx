import { useState, useEffect, useRef } from 'react'
import { Link } from 'react-router-dom'
import { supabase } from '../supabase'
import { useTheme } from '../ThemeContext'
import { useLang } from '../LangContext'
import SettingsDropdown from '../components/SettingsDropdown'

const CATEGORIES = ['general', 'x', 'instagram', 'youtube', 'article', 'video']

function normalizeCat(cat) {
  if (!cat) return 'general'
  const c = cat.toLowerCase().trim()
  if (c === 'x' || c === 'x (twitter)' || c === 'twitter') return 'x'
  if (c.startsWith('instagram')) return 'instagram'
  if (c.startsWith('youtube')) return 'youtube'
  if (c.startsWith('article')) return 'article'
  if (c.startsWith('video')) return 'video'
  if (c.startsWith('general')) return 'general'
  return c
}

function hostname(url) {
  try { return new URL(url).hostname } catch { return url }
}

function suggestCategory(urlString) {
  try {
    const host = new URL(urlString).hostname?.toLowerCase() || ''
    if (host.includes('twitter.com') || host.includes('x.com')) return 'x'
    if (host.includes('instagram.com')) return 'instagram'
    if (host.includes('youtube.com') || host.includes('youtu.be')) return 'youtube'
    if (host.includes('medium.com') || host.includes('dev.to') || host.includes('substack.com')) return 'article'
    if (host.includes('vimeo.com') || host.includes('dailymotion.com') || host.includes('tiktok.com')) return 'video'
  } catch {}
  return 'general'
}

async function fetchMetadata(url) {
  try {
    const res = await fetch(`https://api.microlink.io/?url=${encodeURIComponent(url)}`)
    const json = await res.json()
    if (json.status !== 'success' || !json.data) return null
    const d = json.data
    let title = d.title?.trim()
    if (title && (title.toLowerCase().includes('browser is deprecated') || title.toLowerCase().includes('please upgrade'))) title = null
    const image = d.image?.url || null
    return { title: title || null, image }
  } catch {
    return null
  }
}

function faviconUrl(url) {
  try {
    const h = new URL(url).hostname
    return `https://www.google.com/s2/favicons?domain=${h}&sz=32`
  } catch {
    return null
  }
}

export default function Bookmarks({ user }) {
  const { theme } = useTheme()
  const { t } = useLang()
  const [bookmarks, setBookmarks] = useState([])
  const [loading, setLoading] = useState(true)
  const [filter, setFilter] = useState('all')
  const [search, setSearch] = useState('')
  const [newUrl, setNewUrl] = useState('')
  const [newTitle, setNewTitle] = useState('')
  const [newCategory, setNewCategory] = useState('general')
  const [newThumbnail, setNewThumbnail] = useState('')
  const [adding, setAdding] = useState(false)
  const [showAddForm, setShowAddForm] = useState(false)
  const [isPremium, setIsPremium] = useState(false)
  const [isLoadingPreview, setIsLoadingPreview] = useState(false)
  const previewTimeoutRef = useRef(null)

  useEffect(() => { fetchBookmarks() }, [user?.id])

  useEffect(() => {
    if (!user?.id) return
    supabase.from('users').select('is_premium').eq('id', user.id).single()
      .then(({ data }) => setIsPremium(data?.is_premium ?? false))
  }, [user?.id])

  useEffect(() => {
    if (!isPremium || !newUrl.trim()) return
    const url = newUrl.trim()
    if (!url.startsWith('http://') && !url.startsWith('https://')) return
    clearTimeout(previewTimeoutRef.current)
    previewTimeoutRef.current = setTimeout(async () => {
      setIsLoadingPreview(true)
      const meta = await fetchMetadata(url)
      if (meta) {
        if (meta.title) setNewTitle((prev) => prev || meta.title)
        if (meta.image) setNewThumbnail(meta.image)
        const cat = suggestCategory(url)
        if (cat !== 'general') setNewCategory(cat)
      }
      setIsLoadingPreview(false)
    }, 600)
    return () => clearTimeout(previewTimeoutRef.current)
  }, [newUrl, isPremium])

  async function fetchBookmarks() {
    if (!user?.id) return
    setLoading(true)
    const { data, error } = await supabase
      .from('bookmarks')
      .select('*')
      .eq('user_id', user.id)
      .order('created_at', { ascending: false })
    if (!error) setBookmarks(data || [])
    setLoading(false)
  }

  async function addBookmark(e) {
    e.preventDefault()
    if (!newUrl.trim() || !user?.id) return
    setAdding(true)
    const { error } = await supabase.from('bookmarks').insert({
      user_id: user.id,
      title: newTitle.trim() || hostname(newUrl) || 'Untitled',
      url: newUrl.trim(),
      notes: '',
      category: newCategory,
      tags: [],
      is_read: false,
      is_favorite: false,
      thumbnail_url: newThumbnail || null,
    })
    if (!error) {
      setNewUrl('')
      setNewTitle('')
      setNewCategory('general')
      setNewThumbnail('')
      setShowAddForm(false)
      fetchBookmarks()
    }
    setAdding(false)
  }

  async function toggleRead(b) {
    await supabase.from('bookmarks').update({ is_read: !b.is_read }).eq('id', b.id)
    fetchBookmarks()
  }

  async function toggleFavorite(b) {
    await supabase.from('bookmarks').update({ is_favorite: !b.is_favorite }).eq('id', b.id)
    fetchBookmarks()
  }

  async function deleteBookmark(id) {
    if (!confirm(t('bookmarks.deleteConfirm'))) return
    await supabase.from('bookmarks').delete().eq('id', id)
    fetchBookmarks()
  }

  async function signOut() {
    await supabase.auth.signOut()
  }

  const filtered = bookmarks
    .filter((b) => filter === 'all' || normalizeCat(b.category) === filter)
    .filter((b) => {
      if (!search.trim()) return true
      const q = search.toLowerCase()
      return b.title?.toLowerCase().includes(q) || b.url?.toLowerCase().includes(q)
    })

  const favCount = bookmarks.filter((b) => b.is_favorite).length
  const readCount = bookmarks.filter((b) => b.is_read).length

  return (
    <div className={`min-h-screen ${theme.bg}`}>
      {/* Navbar */}
      <nav className={`sticky top-0 z-10 ${theme.navBg} border-b ${theme.navBorder} backdrop-blur-xl`}>
        <div className="flex items-center justify-between px-4 py-2.5 sm:py-3">
          <Link to="/" className="flex items-center gap-2 no-underline">
            <img src="/icon.png" alt="MindShelf" className="w-7 h-7 rounded-lg" />
            <span className={`text-base sm:text-lg font-bold ${theme.text} tracking-tight`}>MindShelf</span>
          </Link>
          <div className="flex items-center gap-1.5 sm:gap-2">
            <SettingsDropdown />
            <span className={`text-sm ${theme.textMuted} hidden sm:inline`}>{user?.email}</span>
            <button
              onClick={signOut}
              className={`text-xs sm:text-sm ${theme.textSecondary} transition px-2 sm:px-3 py-1.5 rounded-lg ${theme.mode === 'dark' ? 'hover:bg-slate-800' : 'hover:bg-gray-100'}`}
            >
              {t('nav.signOut')}
            </button>
          </div>
        </div>
        {/* Mobile account info bar */}
        <div className={`flex items-center justify-center px-4 py-1.5 text-xs ${theme.textMuted} border-t ${theme.navBorder} sm:hidden`}>
          {user?.email}
        </div>
      </nav>

      <main className="max-w-4xl mx-auto px-4 py-4 sm:py-6">
        {/* Header */}
        <div className="flex items-center justify-between mb-4 sm:mb-6">
          <div>
            <h1 className={`text-xl sm:text-2xl font-bold ${theme.text}`}>{t('bookmarks.title')}</h1>
            <p className={`text-xs sm:text-sm ${theme.textMuted} mt-0.5`}>
              {bookmarks.length} {t('bookmarks.total')} &middot; {readCount} {t('bookmarks.read')} &middot; {favCount} {t('bookmarks.favorites')}
            </p>
          </div>
          <button
            onClick={() => setShowAddForm(!showAddForm)}
            className={`flex items-center gap-1.5 px-3 sm:px-4 py-2 sm:py-2.5 rounded-xl ${theme.btnPrimary} text-white text-sm font-medium transition-all hover:shadow-lg`}
          >
            <svg className="w-4 h-4 sm:w-5 sm:h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2.5}>
              <path strokeLinecap="round" strokeLinejoin="round" d="M12 4.5v15m7.5-7.5h-15" />
            </svg>
            <span className="hidden sm:inline">{t('bookmarks.add')}</span>
          </button>
        </div>

        {/* Add Form */}
        {showAddForm && (
          <form onSubmit={addBookmark} className={`mb-4 sm:mb-6 p-3 sm:p-4 rounded-2xl ${theme.cardBg} border ${theme.cardBorder} space-y-2.5 sm:space-y-3 backdrop-blur`}>
            <div className="relative">
              <input
                type="url"
                value={newUrl}
                onChange={(e) => setNewUrl(e.target.value)}
                placeholder="https://..."
                className={`w-full px-3.5 py-2.5 pr-10 rounded-xl ${theme.inputBg} border ${theme.inputBorder} ${theme.text} placeholder-gray-400 focus:outline-none focus:ring-2 ${theme.inputFocus} text-sm`}
                required
                autoFocus
              />
              {isLoadingPreview && isPremium && (
                <div className="absolute right-3 top-1/2 -translate-y-1/2">
                  <svg className="animate-spin w-5 h-5 text-indigo-500" fill="none" viewBox="0 0 24 24">
                    <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
                    <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z" />
                  </svg>
                </div>
              )}
            </div>
            {(newThumbnail || newTitle) && isPremium && (
              <div className={`flex gap-3 p-2.5 rounded-xl ${theme.mode === 'dark' ? 'bg-slate-800/50' : 'bg-gray-100/80'}`}>
                {newThumbnail && (
                  <img src={newThumbnail} alt="" className="w-14 h-14 sm:w-16 sm:h-16 rounded-lg object-cover flex-shrink-0" />
                )}
                {newTitle && (
                  <p className={`text-sm font-medium ${theme.text} line-clamp-2 flex-1 min-w-0`}>{newTitle}</p>
                )}
              </div>
            )}
            <div className="flex gap-2">
              <input
                type="text"
                value={newTitle}
                onChange={(e) => setNewTitle(e.target.value)}
                placeholder={t('bookmarks.titleOptional')}
                className={`flex-1 min-w-0 px-3.5 py-2.5 rounded-xl ${theme.inputBg} border ${theme.inputBorder} ${theme.text} placeholder-gray-400 focus:outline-none text-sm`}
              />
              <select
                value={newCategory}
                onChange={(e) => setNewCategory(e.target.value)}
                className={`px-2.5 py-2.5 rounded-xl ${theme.inputBg} border ${theme.inputBorder} ${theme.text} text-sm focus:outline-none focus:ring-2 ${theme.inputFocus} max-w-[120px]`}
              >
                {CATEGORIES.map((cat) => (
                  <option key={cat} value={cat}>{t(`category.${cat}`)}</option>
                ))}
              </select>
            </div>
            <div className="flex justify-end gap-2">
              <button type="button" onClick={() => setShowAddForm(false)} className={`px-3 py-2 rounded-xl text-sm ${theme.textSecondary} transition`}>
                {t('bookmarks.cancel')}
              </button>
              <button type="submit" disabled={adding} className={`px-5 py-2 rounded-xl ${theme.btnPrimary} text-white font-medium text-sm transition disabled:opacity-50`}>
                {adding ? t('bookmarks.adding') : t('bookmarks.add')}
              </button>
            </div>
          </form>
        )}

        {/* Search */}
        <div className="relative mb-3 sm:mb-4">
          <svg className={`absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 ${theme.textMuted}`} fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
            <path strokeLinecap="round" strokeLinejoin="round" d="M21 21l-5.197-5.197m0 0A7.5 7.5 0 105.196 5.196a7.5 7.5 0 0010.607 10.607z" />
          </svg>
          <input
            type="text"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            placeholder={t('bookmarks.search')}
            className={`w-full pl-9 pr-4 py-2.5 rounded-xl ${theme.cardBg} border ${theme.cardBorder} ${theme.text} placeholder-gray-400 focus:outline-none focus:ring-2 ${theme.inputFocus} text-sm backdrop-blur`}
          />
        </div>

        {/* Category Filters */}
        <div className="flex gap-1.5 sm:gap-2 overflow-x-auto pb-3 sm:pb-4 -mx-4 px-4 scrollbar-hide">
          {['all', ...CATEGORIES].map((cat) => (
            <button
              key={cat}
              onClick={() => setFilter(cat)}
              className={`flex items-center gap-1 sm:gap-1.5 px-3 sm:px-4 py-1.5 sm:py-2 rounded-full text-xs sm:text-sm font-medium whitespace-nowrap transition-all ${
                filter === cat ? `${theme.filterActive} shadow-lg` : theme.filterInactive
              }`}
            >
              {cat !== 'all' && (
                <span className={`w-1.5 h-1.5 sm:w-2 sm:h-2 rounded-full ${theme.dot[cat] || 'bg-gray-400'}`} />
              )}
              {cat === 'all' ? `${t('bookmarks.all')} (${bookmarks.length})` : t(`category.${cat}`)}
            </button>
          ))}
        </div>

        {/* Bookmark List */}
        {loading ? (
          <div className="space-y-2 sm:space-y-3">
            {[1, 2, 3, 4, 5].map((i) => (
              <div key={i} className={`animate-pulse flex items-center gap-3 p-3 sm:p-4 rounded-xl ${theme.cardBg}`}>
                <div className={`w-8 h-8 rounded-lg flex-shrink-0 ${theme.mode === 'dark' ? 'bg-slate-700/50' : 'bg-gray-200'}`} />
                <div className="flex-1 space-y-2">
                  <div className={`h-3.5 rounded w-3/4 ${theme.mode === 'dark' ? 'bg-slate-700/50' : 'bg-gray-200'}`} />
                  <div className={`h-2.5 rounded w-1/3 ${theme.mode === 'dark' ? 'bg-slate-700/30' : 'bg-gray-100'}`} />
                </div>
              </div>
            ))}
          </div>
        ) : filtered.length === 0 ? (
          <div className="text-center py-16 sm:py-20">
            <div className="text-3xl sm:text-4xl mb-3">{search ? '🔍' : '📑'}</div>
            <p className={`${theme.textSecondary} font-medium text-sm sm:text-base`}>
              {search ? t('bookmarks.noMatch') : t('bookmarks.empty')}
            </p>
            <p className={`text-xs sm:text-sm ${theme.textMuted} mt-1`}>
              {search ? t('bookmarks.tryDifferent') : t('bookmarks.emptyHint')}
            </p>
          </div>
        ) : (
          <div className="space-y-1.5 sm:space-y-2">
            {filtered.map((b) => (
              <div
                key={b.id}
                className={`group flex items-center gap-2.5 sm:gap-3 p-3 sm:p-3.5 rounded-xl ${theme.cardBg} border ${theme.cardBorder} ${theme.cardHover} transition-all backdrop-blur`}
              >
                {/* Thumbnail or Favicon */}
                <img
                  src={b.thumbnail_url || faviconUrl(b.url)}
                  alt=""
                  className={`w-7 h-7 sm:w-8 sm:h-8 rounded-lg flex-shrink-0 ${b.thumbnail_url ? 'object-cover' : 'object-contain p-0.5 sm:p-1'} ${theme.mode === 'dark' ? 'bg-slate-700/50' : 'bg-gray-100'}`}
                  onError={(e) => { e.target.onerror = null; e.target.src = faviconUrl(b.url) }}
                />

                {/* Content */}
                <a href={b.url} target="_blank" rel="noopener noreferrer" className="flex-1 min-w-0 no-underline">
                  <div className={`font-medium ${theme.text} truncate text-sm transition`} style={{ color: 'inherit' }}>
                    {b.title}
                  </div>
                  <div className={`text-xs ${theme.textMuted} truncate mt-0.5`}>{hostname(b.url)}</div>
                </a>

                {/* Category Badge - desktop only */}
                <span className={`hidden md:inline-flex text-xs px-2.5 py-1 rounded-full border font-medium ${theme.badge[normalizeCat(b.category)] || theme.badge.general}`}>
                  {t(`category.${normalizeCat(b.category) || 'general'}`)}
                </span>

                {/* Actions */}
                <div className="flex items-center gap-0 sm:gap-0.5 flex-shrink-0">
                  <button
                    onClick={() => toggleRead(b)}
                    className={`p-1.5 sm:p-2 rounded-lg transition ${b.is_read ? 'text-green-500' : theme.textMuted}`}
                    title={b.is_read ? t('bookmarks.markUnread') : t('bookmarks.markRead')}
                  >
                    {b.is_read ? (
                      <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2.5}>
                        <path strokeLinecap="round" strokeLinejoin="round" d="M4.5 12.75l6 6 9-13.5" />
                      </svg>
                    ) : (
                      <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                        <circle cx="12" cy="12" r="9" />
                      </svg>
                    )}
                  </button>
                  <button
                    onClick={() => toggleFavorite(b)}
                    className={`p-1.5 sm:p-2 rounded-lg transition ${b.is_favorite ? 'text-yellow-500' : theme.textMuted}`}
                    title={t('bookmarks.favorite')}
                  >
                    {b.is_favorite ? (
                      <svg className="w-4 h-4" viewBox="0 0 24 24" fill="currentColor">
                        <path d="M10.788 3.21c.448-1.077 1.976-1.077 2.424 0l2.082 5.007 5.404.433c1.164.093 1.636 1.545.749 2.305l-4.117 3.527 1.257 5.273c.271 1.136-.964 2.033-1.96 1.425L12 18.354 7.373 21.18c-.996.608-2.231-.29-1.96-1.425l1.257-5.273-4.117-3.527c-.887-.76-.415-2.212.749-2.305l5.404-.433 2.082-5.006z" />
                      </svg>
                    ) : (
                      <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                        <path strokeLinecap="round" strokeLinejoin="round" d="M11.48 3.499a.562.562 0 011.04 0l2.125 5.111a.563.563 0 00.475.345l5.518.442c.499.04.701.663.321.988l-4.204 3.602a.563.563 0 00-.182.557l1.285 5.385a.562.562 0 01-.84.61l-4.725-2.885a.563.563 0 00-.586 0L6.982 20.54a.562.562 0 01-.84-.61l1.285-5.386a.562.562 0 00-.182-.557l-4.204-3.602a.563.563 0 01.321-.988l5.518-.442a.563.563 0 00.475-.345L11.48 3.5z" />
                      </svg>
                    )}
                  </button>
                  <button
                    onClick={() => deleteBookmark(b.id)}
                    className={`p-1.5 sm:p-2 rounded-lg ${theme.textMuted} hover:text-red-500 transition hidden sm:block`}
                    title={t('bookmarks.delete')}
                  >
                    <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                      <path strokeLinecap="round" strokeLinejoin="round" d="M14.74 9l-.346 9m-4.788 0L9.26 9m9.968-3.21c.342.052.682.107 1.022.166m-1.022-.165L18.16 19.673a2.25 2.25 0 01-2.244 2.077H8.084a2.25 2.25 0 01-2.244-2.077L4.772 5.79m14.456 0a48.108 48.108 0 00-3.478-.397m-12 .562c.34-.059.68-.114 1.022-.165m0 0a48.11 48.11 0 013.478-.397m7.5 0v-.916c0-1.18-.91-2.164-2.09-2.201a51.964 51.964 0 00-3.32 0c-1.18.037-2.09 1.022-2.09 2.201v.916m7.5 0a48.667 48.667 0 00-7.5 0" />
                    </svg>
                  </button>
                </div>
              </div>
            ))}
          </div>
        )}
      </main>
    </div>
  )
}
