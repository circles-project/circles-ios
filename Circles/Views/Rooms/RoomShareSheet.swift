//
//  RoomQrCodeSheet.swift
//  Circles
//
//  Created by Charles Wright on 10/11/23.
//

import SwiftUI
import Matrix

struct RoomShareSheet: View {
    @ObservedObject var room: Matrix.Room
    var url: URL?
    @Environment(\.presentationMode) var presentation
    
    @State var copied = false
    
    var qrImage: UIImage? {
        if let url = self.url,
           let urlQR = qrCode(url: url)
        {
            return urlQR
        } else if let roomQR = room.qrImage {
            return roomQR
        } else {
            return nil
        }
    }
    
    var body: some View {
        VStack {
            
            HStack {
                RoomAvatarView(room: room, avatarText: .roomInitials)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .frame(width: 120, height: 120)
                    .padding()
                
                if let name = room.name {
                    Text(name)
                        .font(.title)
                        .fontWeight(.bold)
                        .padding()
                        .minimumScaleFactor(0.5)
                    
                    //Spacer()
                }
                
            }
            .padding()
            
            Text(room.roomId.stringValue)
                .font(.subheadline)
                .fontWeight(.light)
            
            /*
            if copied {
                Button(action: {}) {
                    Text("Copied!")
                        .frame(width: 220, height: 30)
                }
                .buttonStyle(.bordered)
                .task {
                    try? await Task.sleep(for: .seconds(2))
                    copied = false
                }
            } else {
                Button(action: {
                    let pasteboard = UIPasteboard.general
                    pasteboard.url = url
                    copied = true
                }) {
                    Label("Copy URL to clipboard", systemImage: "doc.on.doc")
                        .frame(width: 220, height: 30)
                }
                .buttonStyle(.bordered)
            }
            */
            
            ShareLink("Share link", item: room.url)
                .buttonStyle(.bordered)
            
            Spacer()

            if let image =  qrImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 240, height: 240)
                    .padding()
                
                VStack(alignment: .leading) {
                    Label("Using the QR code to request access", systemImage: "lightbulb.fill")
                        .foregroundColor(.accentColor)
                        .font(.title3)
                        .fontWeight(.bold)
                    Text("Have your friend select \"Scan QR code\" in the Circles app, then show them this code.")
                }
                .padding()
                
            } else {
                Text("Error: No QR code")
                    .foregroundColor(.red)
            }
            
            Spacer()
            
            Button(action: {
                self.presentation.wrappedValue.dismiss()
            }) {
                Text("Done")
                    .padding()
            }
        }
    }
}

