//
//  EpisodeRow.swift
//  RadioRSS
//
//  Created by Yanis Labbé on 2025-05-07.
//

import SwiftUI
import SwiftData

struct EpisodeRow: View {
    @Bindable var episode: Episode
    var indicator: Double
    @State private var del = false
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
            .onTapGesture { player.play(episode: episode) }
            Spacer()
            controlButton
        }
        .alert("Delete file?", isPresented: $del) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                if let u = episode.localFileURL {
                    try? FileManager.default.removeItem(at: u)
                    episode.localFileURL = nil
                    DownloadManager.shared.progress.removeValue(forKey: episode.id)
                    try? episode.modelContext?.save()
                }
            }
        }
    }
    
    private var progressBar: AnyView? {
        guard let dur = episode.duration, dur > 0 else { return nil }
        let ratio = min(max(indicator / dur, 0), 1)
        if ratio == 0 { return nil }
        return AnyView(ProgressView(value: ratio))
    }
    
    @ViewBuilder private var controlButton: some View {
        if episode.localFileURL == nil {
            if let p = DownloadManager.shared.progress[episode.id] {
                ProgressView(value: min(max(p, 0), 1)).frame(width: 40)
            } else {
                Button { DownloadManager.shared.download(episode: episode) } label: { Image(systemName: "arrow.down.circle") }
                    .buttonStyle(.borderless)
            }
        } else {
            Button { del = true } label: { Image(systemName: "trash") }
                .buttonStyle(.borderless)
        }
    }
}
