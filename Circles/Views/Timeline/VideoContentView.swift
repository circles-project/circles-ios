//
//  VideoContentView.swift
//  Circles
//
//  Created by Charles Wright on 4/17/24.
//

import SwiftUI
import AVKit
import MarkdownUI
import Matrix

struct VideoContentView: View {
    @ObservedObject var message: Matrix.Message
    var autoplay = false
    var fullscreen = false
    
    @Environment(\.presentationMode) var presentation
    
    enum Status {
        case nothing
        case downloading
        case downloaded(AVPlayer)
        case failed
    }
    @State var status: Status = .nothing
    
    func download(content: Matrix.mVideoContent) async throws {
        if let file = content.file {
            
            let localUrl = URL.temporaryDirectory.appendingPathComponent("\(file.url.serverName):\(file.url.mediaId).mp4")
            //let url = URL.documentsDirectory.appendingPathComponent("\(file.url.mediaId).mp4")


            if FileManager.default.fileExists(atPath: localUrl.absoluteString) {
                self.status = .downloaded(AVPlayer(url: localUrl))
            } else {
                
                do {
                    self.status = .downloading
                    /*
                     let url = try await message.room.session.downloadAndDecryptFile(file)
                     self.status = .downloaded(url)
                     */
                    let data = try await message.room.session.downloadAndDecryptData(file)
                    print("VIDEO\tDownloaded \(data.count) bytes of data")
                    try data.write(to: localUrl)
                    print("VIDEO\tWrote data to local URL")
                    self.status = .downloaded(AVPlayer(url: localUrl))
                } catch {
                    print("VIDEO\tFailed to download and decrypt encrypted video file")
                    self.status = .failed
                }
            }
        } else if let mxc = content.url {
            let localUrl = URL.temporaryDirectory.appendingPathComponent("\(mxc.serverName):\(mxc.mediaId).mp4")
            if FileManager.default.fileExists(atPath: localUrl.absoluteString) {
                self.status = .downloaded(AVPlayer(url: localUrl))
            } else {
                do {
                    self.status = .downloading
                    let data = try await message.room.session.downloadData(mxc: mxc)
                    print("VIDEO\tDownloaded data")
                    try data.write(to: localUrl)
                    print("VIDEO\tWrote data to local URL")
                    self.status = .downloaded(AVPlayer(url: localUrl))
                } catch {
                    print("VIDEO\tFailed to download plaintext video file")
                    self.status = .failed
                }
            }
        } else {
            print("VIDEO\tNo encrypted file or mxc:// URL for m.video")
            self.status = .failed
        }
    }
    
    var body: some View {
        VStack {
            if let content = message.content as? Matrix.mVideoContent {
                
                if let caption = content.caption {
                    let markdown = MarkdownContent(caption)
                    Markdown(markdown)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .font(CustomFonts.inter14)
                }
                
                switch status {
                case .nothing:
                    ZStack(alignment: .center) {
                        MessageThumbnail(message: message)

                        if !autoplay {
                            AsyncButton(action: {
                                try await download(content: content)
                            }) {
                                BasicImage(systemName: SystemImages.playCircle.rawValue)
                                    .frame(width: 80, height: 80)
                                    .foregroundColor(.white)
                                    .shadow(color: .black, radius: 10)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .onAppear {
                        if autoplay {
                            Task {
                                try await download(content: content)
                            }
                        }
                    }

                case .downloading:
                    ZStack(alignment: .center) {
                        MessageThumbnail(message: message)

                        VStack(alignment: .center) {
                            ProgressView()
                                .scaleEffect(2)
                            Text("Downloading...")
                        }
                        .foregroundColor(.white)
                        .shadow(color: .black, radius: 10)
                    }

                case .downloaded(let player):
                    // 2023-08-15: We need the ZStack here to ensure that the VideoPlayer
                    // takes up the same space that the thumbnail image takes.
                    // For whatever reason VideoPlayer is not smart about using space like
                    // Image is, so without this we'd have to hard-code a .frame around the
                    // thing with fixed dimensions, and that would not look good on both
                    // iPhone and iPad.
                    // I tried using a GeometryReader instead, and it also comes out tiny
                    // just like the VideoPlayer; I suspect maybe it's already using one
                    // internally.
                    // Seems like they're not giving the video a high enough layout priority.
                    // Anyway... this works fine for now.
                    ZStack {
                        MessageThumbnail(message: message)

                        VideoPlayer(player: player) {
                            if fullscreen {
                                VStack(alignment: .leading) {
                                    HStack {
                                        Button(action: {
                                            self.presentation.wrappedValue.dismiss()
                                        }) {
                                            Image(systemName: SystemImages.xmark.rawValue)
                                                .foregroundColor(.white)
                                        }
                                        .buttonStyle(.plain)
                                        .padding()
                                        
                                        Spacer()
                                    }
                                    
                                    Spacer()
                                }
                            }
                        }
                            .onAppear {
                                player.play()
                            }
                            .onDisappear {
                                player.pause()
                            }
                    }
                    

                case .failed:
                    ZStack {
                        MessageThumbnail(message: message)

                        Label("Failed to load video", systemImage: SystemImages.exclamationmarkTriangle.rawValue)
                            .foregroundColor(.red)
                            .shadow(color: .white, radius: 10)
                    }
                } // end switch

            } else {
                EmptyView()
            }
        } // end VStack
    } // end body
}
