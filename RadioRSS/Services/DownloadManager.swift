//
//  DownloadManager.swift
//  RadioRSS
//
//  Created by Yanis Labbé on 2025-05-07.
//

import Foundation
import SwiftData
import AVFoundation
import UniformTypeIdentifiers

@MainActor
final class DownloadManager: NSObject, ObservableObject, URLSessionDownloadDelegate {
    static let shared = DownloadManager()
    @Published var progress: [UUID: Double] = [:]
    private var map: [UUID: Episode] = [:]
    private lazy var session: URLSession = {
        let config = URLSessionConfiguration.background(withIdentifier: "RadioRSSDownloads")
        return URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }()
    private override init() {}
    func download(episode: Episode) {
        guard episode.localFileURL == nil else {
            print("DownloadManager already downloaded at", String(describing: episode.localFileURL))
            return
        }
        let task = session.downloadTask(with: episode.audioURL)
        task.taskDescription = episode.id.uuidString
        task.resume()
        progress[episode.id] = 0
        map[episode.id] = episode
    }
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten written: Int64, totalBytesExpectedToWrite expected: Int64) {
        guard let idString = downloadTask.taskDescription, let id = UUID(uuidString: idString) else { return }
        let frac = Double(written) / Double(expected)
        Task { @MainActor in
            progress[id] = frac
        }
    }
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard let idString = downloadTask.taskDescription, let id = UUID(uuidString: idString), let episode = map[id] else { return }
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let response = downloadTask.response
        let suggested = response?.suggestedFilename
        var filename = suggested ?? episode.audioURL.lastPathComponent
        if filename.isEmpty {
            let ext: String
            if let mime = (response as? HTTPURLResponse)?.mimeType, let ut = UTType(mimeType: mime)?.preferredFilenameExtension {
                ext = ut
            } else if !episode.audioURL.pathExtension.isEmpty {
                ext = episode.audioURL.pathExtension
            } else {
                ext = "dat"
            }
            filename = "\(idString).\(ext)"
        }
        let dest = docs.appendingPathComponent(filename)
        try? FileManager.default.removeItem(at: dest)
        do {
            try FileManager.default.moveItem(at: location, to: dest)
        } catch {
            print("DownloadManager move error", error)
            return
        }
        Task { @MainActor in
            episode.localFileURL = dest
            if episode.duration == nil {
                let asset = AVURLAsset(url: dest)
                if let sec = try? await asset.load(.duration).seconds, sec.isFinite, sec > 0 {
                    episode.duration = sec
                } else {
                    print("DownloadManager failed to load duration")
                }
            }
            progress[id] = 1
            try? episode.modelContext?.save()
        }
    }
}
