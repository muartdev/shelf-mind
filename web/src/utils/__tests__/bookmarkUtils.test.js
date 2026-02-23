import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'
import {
  CATEGORIES, FREE_LIMIT,
  normalizeCat, hostname, suggestCategory,
  fetchWithTimeout, fetchMetadata,
  faviconUrl, normalizeUrl, isDuplicate,
  filterBookmarks, calculateStats, canAddBookmark,
} from '../bookmarkUtils'

// ─── Constants ───────────────────────────────────────────────

describe('constants', () => {
  it('CATEGORIES has expected values', () => {
    expect(CATEGORIES).toEqual(['general', 'x', 'instagram', 'youtube', 'article', 'video'])
  })

  it('FREE_LIMIT is 10', () => {
    expect(FREE_LIMIT).toBe(10)
  })
})

// ─── normalizeCat ────────────────────────────────────────────

describe('normalizeCat', () => {
  it('returns "general" for null/undefined/empty', () => {
    expect(normalizeCat(null)).toBe('general')
    expect(normalizeCat(undefined)).toBe('general')
    expect(normalizeCat('')).toBe('general')
  })

  it('normalizes Twitter variants to "x"', () => {
    expect(normalizeCat('x')).toBe('x')
    expect(normalizeCat('X')).toBe('x')
    expect(normalizeCat('twitter')).toBe('x')
    expect(normalizeCat('Twitter')).toBe('x')
    expect(normalizeCat('X (Twitter)')).toBe('x')
    expect(normalizeCat('x (twitter)')).toBe('x')
  })

  it('normalizes categories with startsWith matching', () => {
    expect(normalizeCat('Instagram')).toBe('instagram')
    expect(normalizeCat('Instagram Stories')).toBe('instagram')
    expect(normalizeCat('YouTube')).toBe('youtube')
    expect(normalizeCat('YouTube Music')).toBe('youtube')
    expect(normalizeCat('Article')).toBe('article')
    expect(normalizeCat('Articles & Blogs')).toBe('article')
    expect(normalizeCat('Video')).toBe('video')
    expect(normalizeCat('Video Clips')).toBe('video')
    expect(normalizeCat('General')).toBe('general')
  })

  it('passes through unknown categories as lowercase', () => {
    expect(normalizeCat('Music')).toBe('music')
    expect(normalizeCat('Podcast')).toBe('podcast')
    expect(normalizeCat('  Custom  ')).toBe('custom')
  })
})

// ─── hostname ────────────────────────────────────────────────

describe('hostname', () => {
  it('extracts hostname from valid URL', () => {
    expect(hostname('https://www.example.com/path')).toBe('www.example.com')
    expect(hostname('http://google.com')).toBe('google.com')
    expect(hostname('https://sub.domain.co.uk/page?q=1')).toBe('sub.domain.co.uk')
  })

  it('returns input for invalid URL', () => {
    expect(hostname('not-a-url')).toBe('not-a-url')
    expect(hostname('')).toBe('')
    expect(hostname('ftp')).toBe('ftp')
  })
})

// ─── suggestCategory ─────────────────────────────────────────

describe('suggestCategory', () => {
  it('detects Twitter/X URLs', () => {
    expect(suggestCategory('https://twitter.com/user/status/123')).toBe('x')
    expect(suggestCategory('https://x.com/user/status/456')).toBe('x')
    expect(suggestCategory('https://mobile.twitter.com/user')).toBe('x')
  })

  it('detects Instagram URLs', () => {
    expect(suggestCategory('https://www.instagram.com/p/abc123')).toBe('instagram')
    expect(suggestCategory('https://instagram.com/reel/xyz')).toBe('instagram')
  })

  it('detects YouTube URLs', () => {
    expect(suggestCategory('https://www.youtube.com/watch?v=abc')).toBe('youtube')
    expect(suggestCategory('https://youtu.be/abc123')).toBe('youtube')
    expect(suggestCategory('https://music.youtube.com/watch?v=xyz')).toBe('youtube')
  })

  it('detects article platforms', () => {
    expect(suggestCategory('https://medium.com/@user/article')).toBe('article')
    expect(suggestCategory('https://dev.to/user/post')).toBe('article')
    expect(suggestCategory('https://newsletter.substack.com/p/issue')).toBe('article')
  })

  it('detects video platforms', () => {
    expect(suggestCategory('https://vimeo.com/123456')).toBe('video')
    expect(suggestCategory('https://www.dailymotion.com/video/xyz')).toBe('video')
    expect(suggestCategory('https://www.tiktok.com/@user/video/123')).toBe('video')
  })

  it('returns "general" for unknown domains', () => {
    expect(suggestCategory('https://example.com')).toBe('general')
    expect(suggestCategory('https://github.com/repo')).toBe('general')
    expect(suggestCategory('https://reddit.com/r/programming')).toBe('general')
  })

  it('returns "general" for invalid URLs', () => {
    expect(suggestCategory('not-a-url')).toBe('general')
    expect(suggestCategory('')).toBe('general')
  })
})

// ─── faviconUrl ──────────────────────────────────────────────

describe('faviconUrl', () => {
  it('generates Google favicon API URL', () => {
    expect(faviconUrl('https://github.com/repo')).toBe('https://www.google.com/s2/favicons?domain=github.com&sz=32')
    expect(faviconUrl('https://www.example.com/page')).toBe('https://www.google.com/s2/favicons?domain=www.example.com&sz=32')
  })

  it('returns null for invalid URL', () => {
    expect(faviconUrl('not-a-url')).toBeNull()
    expect(faviconUrl('')).toBeNull()
  })
})

// ─── normalizeUrl ────────────────────────────────────────────

describe('normalizeUrl', () => {
  it('strips trailing slash', () => {
    expect(normalizeUrl('https://example.com/')).toBe('example.com')
    expect(normalizeUrl('https://example.com/path/')).toBe('example.com/path')
  })

  it('removes protocol', () => {
    expect(normalizeUrl('https://example.com')).toBe('example.com')
    expect(normalizeUrl('http://example.com')).toBe('example.com')
  })

  it('removes www prefix', () => {
    expect(normalizeUrl('https://www.example.com')).toBe('example.com')
    expect(normalizeUrl('http://www.example.com/path')).toBe('example.com/path')
  })

  it('combines all normalizations', () => {
    expect(normalizeUrl('https://www.example.com/')).toBe('example.com')
    expect(normalizeUrl('http://www.example.com/path/')).toBe('example.com/path')
  })
})

// ─── isDuplicate ─────────────────────────────────────────────

describe('isDuplicate', () => {
  const bookmarks = [
    { url: 'https://www.example.com/page' },
    { url: 'https://github.com/repo' },
    { url: 'http://blog.dev/post' },
  ]

  it('detects exact match', () => {
    expect(isDuplicate('https://www.example.com/page', bookmarks)).toBe(true)
  })

  it('detects http/https variant', () => {
    expect(isDuplicate('http://www.example.com/page', bookmarks)).toBe(true)
  })

  it('detects www variant', () => {
    expect(isDuplicate('https://example.com/page', bookmarks)).toBe(true)
  })

  it('detects trailing slash variant', () => {
    expect(isDuplicate('https://github.com/repo/', bookmarks)).toBe(true)
  })

  it('returns false for non-match', () => {
    expect(isDuplicate('https://new-site.com', bookmarks)).toBe(false)
  })

  it('handles empty bookmarks', () => {
    expect(isDuplicate('https://example.com', [])).toBe(false)
  })
})

// ─── filterBookmarks ─────────────────────────────────────────

describe('filterBookmarks', () => {
  const bookmarks = [
    { title: 'Swift Tutorial', url: 'https://swift.org', category: 'article', is_favorite: true, is_read: true },
    { title: 'Funny Cat Video', url: 'https://youtube.com/watch?v=abc', category: 'youtube', is_favorite: false, is_read: false },
    { title: 'React Docs', url: 'https://react.dev', category: 'article', is_favorite: true, is_read: false },
    { title: 'Elon Tweet', url: 'https://x.com/elon/status/123', category: 'x', is_favorite: false, is_read: true },
  ]

  it('returns all bookmarks with "all" filter', () => {
    const result = filterBookmarks(bookmarks, 'all', '')
    expect(result).toHaveLength(4)
  })

  it('filters by favorites', () => {
    const result = filterBookmarks(bookmarks, 'favorites', '')
    expect(result).toHaveLength(2)
    expect(result.every((b) => b.is_favorite)).toBe(true)
  })

  it('filters by category', () => {
    const result = filterBookmarks(bookmarks, 'article', '')
    expect(result).toHaveLength(2)
    expect(result.every((b) => normalizeCat(b.category) === 'article')).toBe(true)
  })

  it('filters by x category', () => {
    const result = filterBookmarks(bookmarks, 'x', '')
    expect(result).toHaveLength(1)
    expect(result[0].title).toBe('Elon Tweet')
  })

  it('searches by title', () => {
    const result = filterBookmarks(bookmarks, 'all', 'swift')
    expect(result).toHaveLength(1)
    expect(result[0].title).toBe('Swift Tutorial')
  })

  it('searches by URL', () => {
    const result = filterBookmarks(bookmarks, 'all', 'react.dev')
    expect(result).toHaveLength(1)
    expect(result[0].title).toBe('React Docs')
  })

  it('search is case-insensitive', () => {
    const result = filterBookmarks(bookmarks, 'all', 'SWIFT')
    expect(result).toHaveLength(1)
  })

  it('combines filter and search', () => {
    const result = filterBookmarks(bookmarks, 'article', 'swift')
    expect(result).toHaveLength(1)
    expect(result[0].title).toBe('Swift Tutorial')
  })

  it('returns empty for no matches', () => {
    const result = filterBookmarks(bookmarks, 'all', 'nonexistent')
    expect(result).toHaveLength(0)
  })

  it('ignores whitespace-only search', () => {
    const result = filterBookmarks(bookmarks, 'all', '   ')
    expect(result).toHaveLength(4)
  })
})

// ─── calculateStats ──────────────────────────────────────────

describe('calculateStats', () => {
  it('returns zeros for empty array', () => {
    expect(calculateStats([])).toEqual({ total: 0, read: 0, favorites: 0 })
  })

  it('counts correctly', () => {
    const bookmarks = [
      { is_read: true, is_favorite: true },
      { is_read: true, is_favorite: false },
      { is_read: false, is_favorite: true },
      { is_read: false, is_favorite: false },
    ]
    expect(calculateStats(bookmarks)).toEqual({ total: 4, read: 2, favorites: 2 })
  })

  it('handles all read', () => {
    const bookmarks = [
      { is_read: true, is_favorite: false },
      { is_read: true, is_favorite: false },
    ]
    expect(calculateStats(bookmarks)).toEqual({ total: 2, read: 2, favorites: 0 })
  })
})

// ─── canAddBookmark ──────────────────────────────────────────

describe('canAddBookmark', () => {
  it('allows free user under limit', () => {
    expect(canAddBookmark(0, false)).toBe(true)
    expect(canAddBookmark(9, false)).toBe(true)
  })

  it('blocks free user at limit', () => {
    expect(canAddBookmark(10, false)).toBe(false)
    expect(canAddBookmark(15, false)).toBe(false)
  })

  it('always allows premium user', () => {
    expect(canAddBookmark(0, true)).toBe(true)
    expect(canAddBookmark(10, true)).toBe(true)
    expect(canAddBookmark(1000, true)).toBe(true)
  })
})

// ─── fetchWithTimeout (async + mocked fetch) ────────────────

describe('fetchWithTimeout', () => {
  beforeEach(() => {
    vi.useFakeTimers()
  })

  afterEach(() => {
    vi.useRealTimers()
    vi.restoreAllMocks()
  })

  it('returns response on successful fetch', async () => {
    const mockResponse = { ok: true, status: 200 }
    globalThis.fetch = vi.fn().mockResolvedValue(mockResponse)

    const result = await fetchWithTimeout('https://example.com', 5000)
    expect(result).toBe(mockResponse)
    expect(globalThis.fetch).toHaveBeenCalledOnce()
  })

  it('passes AbortController signal to fetch', async () => {
    globalThis.fetch = vi.fn().mockResolvedValue({ ok: true })

    await fetchWithTimeout('https://example.com', 3000)
    const callArgs = globalThis.fetch.mock.calls[0]
    expect(callArgs[1]).toHaveProperty('signal')
    expect(callArgs[1].signal).toBeInstanceOf(AbortSignal)
  })

  it('throws on fetch error', async () => {
    globalThis.fetch = vi.fn().mockRejectedValue(new Error('Network error'))

    await expect(fetchWithTimeout('https://example.com', 5000)).rejects.toThrow('Network error')
  })
})

// ─── fetchMetadata (async + mocked fetch) ────────────────────

describe('fetchMetadata', () => {
  afterEach(() => {
    vi.restoreAllMocks()
  })

  it('uses noembed for YouTube video URLs', async () => {
    globalThis.fetch = vi.fn().mockResolvedValue({
      json: () => Promise.resolve({ title: 'Cool Video', thumbnail_url: 'https://img.youtube.com/thumb.jpg' }),
    })

    const result = await fetchMetadata('https://www.youtube.com/watch?v=abc123')
    expect(result).toEqual({ title: 'Cool Video', image: 'https://img.youtube.com/thumb.jpg' })
    expect(globalThis.fetch.mock.calls[0][0]).toContain('noembed.com')
  })

  it('uses noembed for youtu.be URLs', async () => {
    globalThis.fetch = vi.fn().mockResolvedValue({
      json: () => Promise.resolve({ title: 'Short Video', thumbnail_url: null }),
    })

    const result = await fetchMetadata('https://youtu.be/abc123')
    expect(result).toEqual({ title: 'Short Video', image: null })
  })

  it('uses noembed for music.youtube.com and rewrites to www', async () => {
    globalThis.fetch = vi.fn().mockResolvedValue({
      json: () => Promise.resolve({ title: 'Music Track', thumbnail_url: 'https://img.youtube.com/music.jpg' }),
    })

    const result = await fetchMetadata('https://music.youtube.com/watch?v=xyz')
    expect(result).toEqual({ title: 'Music Track', image: 'https://img.youtube.com/music.jpg' })
    expect(globalThis.fetch.mock.calls[0][0]).toContain('www.youtube.com')
    expect(globalThis.fetch.mock.calls[0][0]).not.toContain('music.youtube.com')
  })

  it('falls back to microlink for non-YouTube URLs', async () => {
    globalThis.fetch = vi.fn().mockResolvedValue({
      json: () => Promise.resolve({
        status: 'success',
        data: { title: 'Example Page', image: { url: 'https://example.com/og.png' } },
      }),
    })

    const result = await fetchMetadata('https://example.com/article')
    expect(result).toEqual({ title: 'Example Page', image: 'https://example.com/og.png' })
    expect(globalThis.fetch.mock.calls[0][0]).toContain('microlink.io')
  })

  it('falls back to microlink when noembed fails for YouTube', async () => {
    let callCount = 0
    globalThis.fetch = vi.fn().mockImplementation(() => {
      callCount++
      if (callCount === 1) {
        return Promise.reject(new Error('noembed failed'))
      }
      return Promise.resolve({
        json: () => Promise.resolve({
          status: 'success',
          data: { title: 'YouTube Fallback', image: { url: 'https://fallback.jpg' } },
        }),
      })
    })

    const result = await fetchMetadata('https://www.youtube.com/watch?v=abc')
    expect(result).toEqual({ title: 'YouTube Fallback', image: 'https://fallback.jpg' })
    expect(globalThis.fetch).toHaveBeenCalledTimes(2)
  })

  it('filters out deprecated browser titles', async () => {
    globalThis.fetch = vi.fn().mockResolvedValue({
      json: () => Promise.resolve({
        status: 'success',
        data: { title: 'Your browser is deprecated - please update', image: null },
      }),
    })

    const result = await fetchMetadata('https://example.com')
    expect(result).toEqual({ title: null, image: null })
  })

  it('filters out "please upgrade" titles', async () => {
    globalThis.fetch = vi.fn().mockResolvedValue({
      json: () => Promise.resolve({
        status: 'success',
        data: { title: 'Please upgrade your browser', image: null },
      }),
    })

    const result = await fetchMetadata('https://example.com')
    expect(result).toEqual({ title: null, image: null })
  })

  it('returns null when microlink status is not success', async () => {
    globalThis.fetch = vi.fn().mockResolvedValue({
      json: () => Promise.resolve({ status: 'fail' }),
    })

    const result = await fetchMetadata('https://example.com')
    expect(result).toBeNull()
  })

  it('returns null when both APIs fail', async () => {
    globalThis.fetch = vi.fn().mockRejectedValue(new Error('Network error'))

    const result = await fetchMetadata('https://www.youtube.com/watch?v=abc')
    expect(result).toBeNull()
  })

  it('returns null image when data has no image', async () => {
    globalThis.fetch = vi.fn().mockResolvedValue({
      json: () => Promise.resolve({
        status: 'success',
        data: { title: 'No Image Page' },
      }),
    })

    const result = await fetchMetadata('https://example.com')
    expect(result).toEqual({ title: 'No Image Page', image: null })
  })

  it('rejects noembed response with title "Noembed"', async () => {
    let callCount = 0
    globalThis.fetch = vi.fn().mockImplementation(() => {
      callCount++
      if (callCount === 1) {
        return Promise.resolve({
          json: () => Promise.resolve({ title: 'Noembed' }),
        })
      }
      return Promise.resolve({
        json: () => Promise.resolve({
          status: 'success',
          data: { title: 'Microlink Title', image: null },
        }),
      })
    })

    const result = await fetchMetadata('https://www.youtube.com/watch?v=abc')
    expect(result).toEqual({ title: 'Microlink Title', image: null })
    expect(globalThis.fetch).toHaveBeenCalledTimes(2)
  })

  it('rejects noembed response with error field', async () => {
    let callCount = 0
    globalThis.fetch = vi.fn().mockImplementation(() => {
      callCount++
      if (callCount === 1) {
        return Promise.resolve({
          json: () => Promise.resolve({ title: 'Some Title', error: 'no matching providers' }),
        })
      }
      return Promise.resolve({
        json: () => Promise.resolve({
          status: 'success',
          data: { title: 'Fallback Title', image: null },
        }),
      })
    })

    const result = await fetchMetadata('https://www.youtube.com/watch?v=abc')
    expect(result).toEqual({ title: 'Fallback Title', image: null })
  })
})
