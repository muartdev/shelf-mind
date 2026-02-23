export const CATEGORIES = ['general', 'x', 'instagram', 'youtube', 'article', 'video']

export const FREE_LIMIT = 10

export function normalizeCat(cat) {
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

export function hostname(url) {
  try { return new URL(url).hostname } catch { return url }
}

export function suggestCategory(urlString) {
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

export async function fetchWithTimeout(url, timeoutMs = 5000) {
  const controller = new AbortController()
  const timer = setTimeout(() => controller.abort(), timeoutMs)
  try {
    const res = await fetch(url, { signal: controller.signal })
    clearTimeout(timer)
    return res
  } catch (e) {
    clearTimeout(timer)
    throw e
  }
}

export async function fetchMetadata(url) {
  try {
    const isYouTubeVideo = (url.includes('youtube.com/watch') || url.includes('youtu.be/') || url.includes('music.youtube.com/watch'))
    if (isYouTubeVideo) {
      const ytUrl = url.replace('music.youtube.com', 'www.youtube.com')
      try {
        const res = await fetchWithTimeout(`https://noembed.com/embed?url=${encodeURIComponent(ytUrl)}`, 4000)
        const json = await res.json()
        if (json.title && json.title !== 'Noembed' && !json.error) {
          return { title: json.title, image: json.thumbnail_url || null }
        }
      } catch { /* timeout or error, fall through */ }
    }
    const res = await fetchWithTimeout(`https://api.microlink.io/?url=${encodeURIComponent(url)}`, 5000)
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

export function faviconUrl(url) {
  try {
    const h = new URL(url).hostname
    return `https://www.google.com/s2/favicons?domain=${h}&sz=32`
  } catch {
    return null
  }
}

export function normalizeUrl(u) {
  return u.replace(/\/$/, '').replace(/^https?:\/\//, '').replace(/^www\./, '')
}

export function isDuplicate(newUrl, bookmarks) {
  const normalized = normalizeUrl(newUrl)
  return bookmarks.some((b) => normalizeUrl(b.url) === normalized)
}

export function filterBookmarks(bookmarks, filterType, searchQuery) {
  return bookmarks
    .filter((b) => {
      if (filterType === 'all') return true
      if (filterType === 'favorites') return b.is_favorite
      return normalizeCat(b.category) === filterType
    })
    .filter((b) => {
      if (!searchQuery.trim()) return true
      const q = searchQuery.toLowerCase()
      return b.title?.toLowerCase().includes(q) || b.url?.toLowerCase().includes(q)
    })
}

export function calculateStats(bookmarks) {
  return {
    total: bookmarks.length,
    read: bookmarks.filter((b) => b.is_read).length,
    favorites: bookmarks.filter((b) => b.is_favorite).length,
  }
}

export function canAddBookmark(count, isPremium) {
  return isPremium || count < FREE_LIMIT
}
