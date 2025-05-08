//
//  PlayerView.swift
//  RadioRSS
//
//  Created by Yanis Labbé on 2025-05-07.
//

import SwiftUI

struct PlayerView: View {
    @EnvironmentObject private var player: PlayerViewModel
    
    private func fmt(_ s: Double) -> String {
        let t = Int(s)
        let m = t / 60
        let sec = t % 60
        return "\(m):" + String(format: "%02d", sec)
    }
    
    var body: some View {
        VStack(spacing: 24) {
            image.frame(width: 250, height: 250).clipShape(RoundedRectangle(cornerRadius: 16))
            Text(player.currentEpisode?.title ?? player.currentRadio?.title ?? "")
                .font(.title2)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            if player.currentEpisode != nil {
                VStack {
                    Slider(value: Binding(get: { player.currentTime }, set: { player.seek(to: $0) }), in: 0...player.totalTime)
                    HStack {
                        Text(fmt(player.currentTime)).font(.caption)
                        Spacer()
                        Text(fmt(player.totalTime)).font(.caption)
                    }
                }
            }
            HStack(spacing: 32) {
                Button { player.previous() } label: { Image(systemName: "backward.fill").font(.largeTitle) }
                Button { player.toggle() } label: { Image(systemName: player.isPlaying ? "pause.circle.fill" : "play.circle.fill").font(.system(size: 60)) }
                Button { player.next() } label: { Image(systemName: "forward.fill").font(.largeTitle) }
            }
            if let e = player.currentEpisode {
                if e.localFileURL == nil {
                    if let p = DownloadManager.shared.progress[e.id] { ProgressView(value: p).frame(width: 100) }
                    Button { DownloadManager.shared.download(episode: e) } label: { Image(systemName: "arrow.down.circle") }
                } else {
                    Button(role: .destructive) {
                        if let u = e.localFileURL {
                            try? FileManager.default.removeItem(at: u)
                            e.localFileURL = nil
                            DownloadManager.shared.progress.removeValue(forKey: e.id)
                            try? e.modelContext?.save()
                        }
                    } label: { Image(systemName: "trash") }
                }
            }
        }
        .padding()
    }
    
    @ViewBuilder private var image: some View {
        if let u = player.currentEpisode?.artworkURL {
            AsyncImage(url: u) { p in if case .success(let i) = p { i.resizable().scaledToFill() } else { Color.gray } }
        } else if let d = player.currentRadio?.imageData, let ui = UIImage(data: d) {
            Image(uiImage: ui).resizable().scaledToFill()
        } else { Color.gray }
    }
}
