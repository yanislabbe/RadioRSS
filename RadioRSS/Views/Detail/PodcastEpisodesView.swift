//
//  PodcastEpisodesView.swift
//  RadioRSS
//
//  Created by Yanis Labbé on 2025-05-07.
//

import SwiftUI
import SwiftData

struct PodcastEpisodesView: View {
    @Bindable var podcast: Podcast
    @State private var search = ""
    @State private var progress: [UUID: Double] = [:]
    @EnvironmentObject private var player: PlayerViewModel

    var body: some View {
        List {
            ForEach(filtered.sorted { $0.pubDate > $1.pubDate }) { e in
                EpisodeRow(episode: e, indicator: progress[e.id] ?? e.progress)
            }
        }
        .searchable(text: $search)
        .navigationTitle(podcast.title)
        .onReceive(DownloadManager.shared.$progress) { progress = $0 }
        .safeAreaInset(edge: .bottom) {
            if player.currentEpisode != nil || player.currentRadio != nil {
                Color.clear.frame(height: 56)
            }
        }
    }

    private var filtered: [Episode] {
        let list = podcast.episodes
        return search.isEmpty
            ? list
            : list.filter { $0.title.localizedCaseInsensitiveContains(search) }
    }
}
