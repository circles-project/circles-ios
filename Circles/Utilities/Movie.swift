//
//  Movie.swift
//  Circles
//
//  Created by Charles Wright on 8/21/23.
//

import Foundation
import SwiftUI
import AVFoundation
import QuickLookThumbnailing
import Matrix

// Based on https://developer.apple.com/documentation/coretransferable/filerepresentation
class Movie: Transferable {
    let url: URL
    let asset: AVAsset
    public private(set) var thumbnail: UIImage?
    
    required init(url: URL) {
        self.url = url
        self.asset = AVAsset(url: url)
        self.thumbnail = nil
        
        Task {
            try await self.loadThumbnail()
        }
    }
    
    var duration: Double {
        get async throws {
            let cmDuration: CMTime = try await asset.load(.duration)
            return cmDuration.seconds
        }
    }
    
    var size: CGSize {
        get async throws {
            guard let track = try await asset.loadTracks(withMediaType: .video).first
            else {
                Matrix.logger.error("No video tracks in the video")
                throw Matrix.Error("No video tracks in the video")
            }
            return try await track.load(.naturalSize)
        }
    }
    
    func loadThumbnail() async throws -> UIImage {
        Matrix.logger.debug("MOVIE Loading thumbnail for \(self.url.absoluteString)")
        let thumbnailSize = try await self.size
        Matrix.logger.debug("MOVIE Got size \(thumbnailSize.height)x\(thumbnailSize.width)")
        let request = QLThumbnailGenerator.Request(fileAt: self.url,
                                                   size: thumbnailSize,
                                                   scale: 1.0,
                                                   representationTypes: .thumbnail)
        let t = try await QLThumbnailGenerator.shared.generateBestRepresentation(for: request).uiImage
        Matrix.logger.debug("Generated UIImage thumbnail")
        self.thumbnail = t
        return t
    }

    
    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .movie) { movie in
            SentTransferredFile(movie.url)
            } importing: { received in
                let filename = received.file.lastPathComponent
                let copy: URL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
                if FileManager.default.fileExists(atPath: copy.path) {
                    try FileManager.default.removeItem(at: copy)
                }
                try FileManager.default.copyItem(at: received.file, to: copy)
                return Self.init(url: copy) }
    }
}
