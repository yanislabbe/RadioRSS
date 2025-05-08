//
//  PodcastsView.swift
//  RadioRSS
//
//  Created by Yanis Labbé on 2025-05-07.
//

import SwiftUI
import SwiftData

struct PodcastsView: View {
    @Environment(\.modelContext) private var context
    @Query private var podcasts: [Podcast]
    @State private var search = ""
    @State private var add = false
    @State private var target: Podcast?
    @EnvironmentObject private var player: PlayerViewModel

    var body: some View {
        NavigationStack {
            List {
                ForEach(filtered) { p in
                    NavigationLink {
                        PodcastEpisodesView(podcast: p)
                    } label: {
                        HStack {
                            AsyncImage(url: p.artworkURL) { phase in
                                if case .success(let i) = phase { i.resizable().scaledToFill() } else { Color.gray }
                            }
                            .frame(width: 60, height: 60)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            Text(p.title)
                        }
                    }
                    .swipeActions {
                        Button(role: .destructive) { target = p } label: { Label("Delete", systemImage: "trash") }
                    }
                }
            }
            .searchable(text: $search)
            .navigationTitle("Podcasts")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) { Button { add = true } label: { Image(systemName: "plus") } }
            }
            .sheet(isPresented: $add) { AddPodcastView() }
            .alert("Delete this podcast?", isPresented: Binding(get: { target != nil }, set: { if !$0 { target = nil } })) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    if let p = target { context.delete(p); try? context.save() }
                    target = nil
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            if player.currentEpisode != nil || player.currentRadio != nil {
                Color.clear.frame(height: 56)
            }
        }
    }

    private var filtered: [Podcast] { search.isEmpty ? podcasts : podcasts.filter { $0.title.localizedCaseInsensitiveContains(search) } }
}
