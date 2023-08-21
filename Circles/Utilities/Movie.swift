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
struct Movie: Transferable {
    let url: URL
    let asset: AVAsset
    
    init(url: URL) {
        self.url = url
        self.asset = AVAsset(url: url)
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
    
    var thumbnail: UIImage {
        get async throws {
            let thumbnailSize = try await self.size
            let request = QLThumbnailGenerator.Request(fileAt: self.url,
                                                       size: thumbnailSize,
                                                       scale: 1.0,
                                                       representationTypes: .thumbnail)
            return try await QLThumbnailGenerator.shared.generateBestRepresentation(for: request).uiImage
        }
    }
    
    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .movie) { movie in
            SentTransferredFile(movie.url)
            } importing: { received in
                let filename = received.file.lastPathComponent
                let copy: URL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
                try FileManager.default.copyItem(at: received.file, to: copy)
                return Self.init(url: copy) }
    }
}
