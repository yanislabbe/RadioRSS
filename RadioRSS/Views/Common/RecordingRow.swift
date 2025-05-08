//
//  RecordingRow.swift
//  RadioRSS
//
//  Created by Yanis Labbé on 2025-05-07.
//

import SwiftUI
import SwiftData

struct RecordingRow: View {
    @Bindable var episode: Episode
    var playlist: [Episode]
    @EnvironmentObject private var player: PlayerViewModel
    
    var body: some View {
        HStack {
            AsyncImage(url: episode.artworkURL ?? episode.podcast?.artworkURL) { phase in
                if case .success(let i) = phase { i.resizable().scaledToFill() } else { Color.gray }
            }
            .frame(width: 60, height: 60)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            VStack(alignment: .leading) {
                Text(episode.title).font(.headline).lineLimit(2)
                if let bar = progressBar { bar }
            }
            .onTapGesture { player.play(episode: episode, playlist: playlist) }
            Spacer()
            Button(role: .destructive) {
                if let u = episode.localFileURL {
                    try? FileManager.default.removeItem(at: u)
                    episode.localFileURL = nil
                    try? episode.modelContext?.save()
                }
            } label: { Image(systemName: "trash") }
                .buttonStyle(.borderless)
        }
    }
    
    private var progressBar: AnyView? {
        guard let dur = episode.duration, dur > 0 else { return nil }
        let ratio = min(max(episode.progress / dur, 0), 1)
        if ratio == 0 { return nil }
        return AnyView(ProgressView(value: ratio))
    }
}
