//
//  RoomQrCodeSheet.swift
//  Circles
//
//  Created by Charles Wright on 10/11/23.
//

import SwiftUI
import Matrix

struct RoomQrCodeSheet: View {
    @ObservedObject var room: Matrix.Room
    @Environment(\.presentationMode) var presentation
    
    var body: some View {
        VStack {
            
            HStack {
                RoomAvatar(room: room, avatarText: .roomInitials)
                    .frame(width: 120, height: 120)
                
                if let name = room.name {
                    Text(name)
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Spacer()
                }
                
            }
            .padding()
            
            Spacer()
            
            if let qrImage = room.qrImage {
                Image(uiImage: qrImage)
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

