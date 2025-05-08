//
//  PlayerViewModel.swift
//  RadioRSS
//
//  Created by Yanis Labbé on 2025-05-07.
//

import Foundation
import AVFoundation
import SwiftData
import MediaPlayer
import UIKit
import Combine

@MainActor
final class PlayerViewModel: ObservableObject {
    static let shared = PlayerViewModel()
    private static let artworkCache = NSCache<NSURL, UIImage>()
    private let player = AVPlayer()
    @Published var currentEpisode: Episode?
    @Published var currentRadio: Radio?
    @Published var isPlaying = false
    @Published var currentTime: Double = 0
    @Published var totalTime: Double = 1
    @Published var networkAlert: String?
    private var playlist: [Episode] = []
    private var timeObserver: Any?
    private var endObserver: Any?
    private var stallObserver: Any?
    private var statusObserver: NSKeyValueObservation?
    private var cancellable: AnyCancellable?
    private var pendingEpisode: Episode?
    private var pendingRadio: Radio?
    private var lostConnection = false
    private var autoPausedForBuffer = false

    private init() {
        configureRemoteCommands()
        observeNetwork()
        observePlayerStatus()
    }

    private func observeNetwork() {
        cancellable = NetworkMonitor.shared.$isConnected
            .receive(on: DispatchQueue.main)
            .sink { [weak self] connected in
                self?.handleNetworkChange(connected)
            }
    }

    private func observePlayerStatus() {
        statusObserver = player.observe(\.timeControlStatus, options: [.new]) { [weak self] p, _ in
            guard let self else { return }
            switch p.timeControlStatus {
            case .playing:
                self.isPlaying = true
                self.autoPausedForBuffer = false
            case .paused, .waitingToPlayAtSpecifiedRate:
                self.isPlaying = false
            @unknown default:
                self.isPlaying = false
            }
            self.updateNowPlaying()
        }
    }

    private func handleNetworkChange(_ connected: Bool) {
        if connected {
            if autoPausedForBuffer, currentRadio != nil {
                autoPausedForBuffer = false
                if let r = currentRadio {
                    let item = AVPlayerItem(url: r.streamURL)
                    player.replaceCurrentItem(with: item)
                    player.play()
                }
                return
            }
            if pendingEpisode != nil || pendingRadio != nil {
                if let ep = pendingEpisode {
                    let list = playlist.isEmpty ? [ep] : playlist
                    pendingEpisode = nil
                    play(episode: ep, playlist: list)
                } else if let r = pendingRadio {
                    pendingRadio = nil
                    play(radio: r)
                }
                return
            }
            if lostConnection && player.timeControlStatus != .playing {
                if let r = currentRadio {
                    let item = AVPlayerItem(url: r.streamURL)
                    player.replaceCurrentItem(with: item)
                }
                player.play()
            }
            lostConnection = false
        } else {
            lostConnection = true
        }
    }

    func play(episode: Episode, playlist override: [Episode]? = nil) {
        autoPausedForBuffer = false
        if !NetworkMonitor.shared.isConnected && episode.localFileURL == nil {
            networkAlert = "No Internet Connection"
            pendingEpisode = episode
            pendingRadio = nil
            return
        }

        currentRadio = nil
        currentEpisode = episode

        if let override {
            playlist = override
        } else if let eps = episode.podcast?.episodes {
            playlist = eps.sorted { $0.pubDate > $1.pubDate }
        } else {
            playlist = [episode]
        }

        let url: URL
        if let local = episode.localFileURL {
            let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let newLocal = docs.appendingPathComponent(local.lastPathComponent)
            if FileManager.default.fileExists(atPath: newLocal.path) {
                episode.localFileURL = newLocal
                try? episode.modelContext?.save()
                url = newLocal
            } else {
                episode.localFileURL = nil
                try? episode.modelContext?.save()
                url = episode.audioURL
            }
        } else {
            url = episode.audioURL
        }

        var start = episode.progress
        if let dur = episode.duration, dur - start <= 10 {
            start = 0
            episode.progress = 0
            try? episode.modelContext?.save()
        }

        let item = AVPlayerItem(url: url)
        player.replaceCurrentItem(with: item)

        if let endObserver {
            NotificationCenter.default.removeObserver(endObserver)
        }
        endObserver = NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime,
                                                             object: item,
                                                             queue: .main) { [weak self] _ in
            guard let self else { return }
            if let ep = self.currentEpisode,
               let idx = self.playlist.firstIndex(of: ep),
               idx + 1 < self.playlist.count {
                self.play(episode: self.playlist[idx + 1], playlist: self.playlist)
            } else {
                self.player.pause()
                self.isPlaying = false
                self.updateNowPlaying()
            }
        }

        if let stallObserver {
            NotificationCenter.default.removeObserver(stallObserver)
            self.stallObserver = nil
        }

        if start > 0 {
            player.seek(to: CMTime(seconds: start, preferredTimescale: 1))
        }
        currentTime = start
        player.play()
        totalTime = episode.duration ?? 1
        observeDuration(for: item, episode: episode)
        observeProgress()
    }

    func play(radio: Radio) {
        autoPausedForBuffer = false
        if !NetworkMonitor.shared.isConnected {
            networkAlert = "No Internet Connection"
            pendingRadio = radio
            pendingEpisode = nil
            currentRadio = radio
            return
        }

        currentEpisode = nil
        currentRadio = radio

        if let endObserver {
            NotificationCenter.default.removeObserver(endObserver)
            self.endObserver = nil
        }
        if let stallObserver {
            NotificationCenter.default.removeObserver(stallObserver)
            self.stallObserver = nil
        }

        let item = AVPlayerItem(url: radio.streamURL)
        stallObserver = NotificationCenter.default.addObserver(forName: .AVPlayerItemPlaybackStalled,
                                                               object: item,
                                                               queue: .main) { [weak self] _ in
            self?.handlePlaybackStalled()
        }

        player.replaceCurrentItem(with: item)
        player.play()

        currentTime = 0
        totalTime = 1
        removeObserver()
    }

    private func handlePlaybackStalled() {
        guard currentRadio != nil else { return }
        guard !autoPausedForBuffer else { return }
        guard !NetworkMonitor.shared.isConnected else { return }
        autoPausedForBuffer = true
        player.pause()
    }

    func toggle() {
        if isPlaying {
            player.pause()
            autoPausedForBuffer = false
        } else {
            if !NetworkMonitor.shared.isConnected &&
                currentRadio != nil &&
                pendingRadio == nil &&
                currentEpisode?.localFileURL == nil {
                networkAlert = "No Internet Connection"
                if let r = currentRadio { pendingRadio = r }
                return
            }
            player.play()
            autoPausedForBuffer = false
        }
    }

    func seek(to seconds: Double) {
        player.seek(to: CMTime(seconds: seconds, preferredTimescale: 1))
        if let ep = currentEpisode {
            ep.progress = seconds
            try? ep.modelContext?.save()
        }
        currentTime = seconds
        updateNowPlaying()
    }

    func next() {
        guard let ep = currentEpisode,
              let idx = playlist.firstIndex(of: ep),
              idx + 1 < playlist.count else { return }
        play(episode: playlist[idx + 1], playlist: playlist)
    }

    func previous() {
        guard let ep = currentEpisode,
              let idx = playlist.firstIndex(of: ep),
              idx - 1 >= 0 else { return }
        play(episode: playlist[idx - 1], playlist: playlist)
    }

    private func observeDuration(for item: AVPlayerItem, episode: Episode) {
        Task {
            let sec = (try? await item.asset.load(.duration).seconds) ?? 0
            guard sec.isFinite, sec > 0 else { return }
            totalTime = sec
            if episode.duration == nil || episode.duration != sec {
                episode.duration = sec
                try? episode.modelContext?.save()
            }
            updateNowPlaying()
        }
    }

    private func observeProgress() {
        removeObserver()
        timeObserver = player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 1, preferredTimescale: 1),
                                                      queue: .main) { [weak self] time in
            guard let self else { return }
            Task { @MainActor in
                self.currentTime = time.seconds
                if let ep = self.currentEpisode {
                    ep.progress = self.currentTime
                    try? ep.modelContext?.save()
                }
                self.updateNowPlaying()
            }
        }
    }

    private func removeObserver() {
        if let obs = timeObserver {
            player.removeTimeObserver(obs)
            timeObserver = nil
        }
    }

    private func configureRemoteCommands() {
        let c = MPRemoteCommandCenter.shared()
        c.playCommand.addTarget { [weak self] _ in self?.toggle(); return .success }
        c.pauseCommand.addTarget { [weak self] _ in self?.toggle(); return .success }
        c.nextTrackCommand.addTarget { [weak self] _ in self?.next(); return .success }
        c.previousTrackCommand.addTarget { [weak self] _ in self?.previous(); return .success }
        c.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let e = event as? MPChangePlaybackPositionCommandEvent,
                  let s = self,
                  s.currentEpisode != nil else { return .commandFailed }
            s.seek(to: e.positionTime)
            return .success
        }
    }

    private func updateNowPlaying() {
        var info: [String: Any] = [:]

        if let ep = currentEpisode {
            info[MPMediaItemPropertyTitle] = ep.title
            if let artURL = ep.artworkURL {
                if let img = Self.artworkCache.object(forKey: artURL as NSURL) {
                    info[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: img.size) { _ in img }
                } else if artURL.isFileURL, let img = UIImage(contentsOfFile: artURL.path) {
                    Self.artworkCache.setObject(img, forKey: artURL as NSURL)
                    info[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: img.size) { _ in img }
                } else {
                    Task.detached {
                        if let (data, _) = try? await URLSession.shared.data(from: artURL),
                           let img = UIImage(data: data) {
                            Self.artworkCache.setObject(img, forKey: artURL as NSURL)
                            await MainActor.run { [weak self] in
                                guard let self, self.currentEpisode?.artworkURL == artURL else { return }
                                self.updateNowPlaying()
                            }
                        }
                    }
                }
            }
            info[MPMediaItemPropertyPlaybackDuration] = totalTime
            info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
            info[MPNowPlayingInfoPropertyMediaType] = MPNowPlayingInfoMediaType.audio.rawValue
        } else if let r = currentRadio {
            info[MPMediaItemPropertyTitle] = r.title
            if let d = r.imageData, let img = UIImage(data: d) {
                info[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: img.size) { _ in img }
            }
            info[MPNowPlayingInfoPropertyIsLiveStream] = true
        }

        info[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }
}
