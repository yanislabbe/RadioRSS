//
//  RecordingsView.swift
//  RadioRSS
//
//  Created by Yanis Labbé on 2025-05-07.
//

import SwiftUI
import SwiftData

struct RecordingsView: View {
    @Query private var episodes: [Episode]
    @State private var search = ""
    @EnvironmentObject private var player: PlayerViewModel

    private var filtered: [Episode] {
        let list = episodes.filter { $0.localFileURL != nil }
        return search.isEmpty ? list : list.filter { $0.title.localizedCaseInsensitiveContains(search) }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(filtered) { e in
                    RecordingRow(episode: e, playlist: filtered)
                }
            }
            .searchable(text: $search)
            .navigationTitle("Downloads")
        }
        .safeAreaInset(edge: .bottom) {
            if player.currentEpisode != nil || player.currentRadio != nil {
                Color.clear.frame(height: 56)
            }
        }
    }
}
