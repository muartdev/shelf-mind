//
//  CachedAsyncImage.swift
//  MindShelf
//
//  Created by Murat on 15.02.2026.
//

import SwiftUI

/// AsyncImage wrapper with URLCache support and retry on failure.
struct CachedAsyncImage<Content: View, Placeholder: View>: View {
    let url: URL?
    @ViewBuilder let content: (Image) -> Content
    @ViewBuilder let placeholder: () -> Placeholder

    @State private var phase: AsyncImagePhase = .empty
    @State private var retryCount = 0
    private let maxRetries = 2

    private static var cache: URLCache {
        URLCache.shared
    }

    var body: some View {
        Group {
            switch phase {
            case .success(let image):
                content(image)
            case .failure:
                placeholder()
                    .onTapGesture {
                        if retryCount < maxRetries {
                            retryCount += 1
                            phase = .empty
                            loadImage()
                        }
                    }
            case .empty:
                placeholder()
                    .onAppear { loadImage() }
            @unknown default:
                placeholder()
            }
        }
    }

    private func loadImage() {
        guard let url else {
            phase = .failure(URLError(.badURL))
            return
        }

        let request = URLRequest(url: url)

        // Check cache first
        if let cached = Self.cache.cachedResponse(for: request),
           let uiImage = UIImage(data: cached.data) {
            phase = .success(Image(uiImage: uiImage))
            return
        }

        Task {
            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                // Store in cache
                let cachedResponse = CachedURLResponse(response: response, data: data)
                Self.cache.storeCachedResponse(cachedResponse, for: request)

                if let uiImage = UIImage(data: data) {
                    await MainActor.run {
                        phase = .success(Image(uiImage: uiImage))
                    }
                } else {
                    await MainActor.run {
                        phase = .failure(URLError(.cannotDecodeContentData))
                    }
                }
            } catch {
                await MainActor.run {
                    phase = .failure(error)
                }
            }
        }
    }
}
