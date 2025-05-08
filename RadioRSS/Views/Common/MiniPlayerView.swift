//
//  MiniPlayerView.swift
//  RadioRSS
//
//  Created by Yanis Labbé on 2025-05-07.
//

import SwiftUI

struct MiniPlayerView: View {
    @EnvironmentObject private var player: PlayerViewModel
    
    var body: some View {
        if player.currentEpisode != nil || player.currentRadio != nil {
            VStack(spacing: 8) {
                Divider()
                HStack {
                    artwork.frame(width: 40, height: 40).clipShape(RoundedRectangle(cornerRadius: 6))
                    Text(player.currentEpisode?.title ?? player.currentRadio?.title ?? "").lineLimit(1)
                    Spacer()
                    Button { player.toggle() } label: { Image(systemName: player.isPlaying ? "pause.fill" : "play.fill") }
                }
                .padding(.horizontal)
                .contentShape(Rectangle())
                .onTapGesture { present() }
                Divider()
            }
            .background(.thickMaterial)
        }
    }
    
    @ViewBuilder private var artwork: some View {
        if let u = player.currentEpisode?.artworkURL {
            AsyncImage(url: u) { p in if case .success(let i) = p { i.resizable().scaledToFill() } else { Color.gray } }
        } else if let d = player.currentRadio?.imageData, let ui = UIImage(data: d) {
            Image(uiImage: ui).resizable().scaledToFill()
        } else { Color.gray }
    }
    
    private func present() {
        if let s = UIApplication.shared.connectedScenes.first as? UIWindowScene, let w = s.windows.first?.rootViewController {
            w.present(UIHostingController(rootView: PlayerView().environmentObject(player)), animated: true)
        }
    }
}
