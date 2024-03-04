//
//  ScanQrCodeAndKnockView.swift
//  Circles
//
//  Created by Charles Wright on 10/11/23.
//

import SwiftUI
import Matrix
import CodeScanner

struct ScanQrCodeAndKnockSheet: View {
    var session: Matrix.Session
    @State var reason: String = ""
    @State var roomId: RoomId? = nil
    @Environment(\.presentationMode) var presentation
    
    var body: some View {
        VStack {

            
            if let roomId = roomId {
                
                Label("Request invitation", systemImage: "checkmark.circle.fill")
                    .symbolRenderingMode(.multicolor)
                    .font(.title2)
                    .padding()

                VStack(alignment: .leading) {
                    Text("Include an optional message:")
                        .foregroundColor(.gray)

                    TextEditor(text: $reason)
                        .lineLimit(5)
                        .border(Color.gray)
                    
                    Label("Warning: Your message will not be encrypted, and is accessible by all current members", systemImage: "exclamationmark.shield")
                        .foregroundColor(.orange)
                }

                AsyncButton(action: {
                    print("Sending knock to \(roomId.stringValue)")
                    if reason.isEmpty {
                        try await session.knock(roomId: roomId, reason: nil)
                    } else {
                        try await session.knock(roomId: roomId, reason: reason)

                    }
                    self.presentation.wrappedValue.dismiss()
                }) {
                    Label("Send request for invite", systemImage: "paperplane.fill")
                }
                .padding()

                Spacer()
                
            } else {
                
                Text("Scan QR code to request invite")
                    .font(.title)
                    .padding()
                
                CodeScannerView(codeTypes: [.qr]) { response in
                    if case let .success(result) = response {
                        let scannedCode = result.string
                        print("QR code scanning result = \(scannedCode)")
                        if let scannedRoomId = RoomId(scannedCode) {
                            print("QR code contains a valid roomId")
                            self.roomId = scannedRoomId
                        } else if let firstToken = scannedCode.split(separator: " ").first,
                                  let url = URL(string: firstToken.description)
                        {
                            print("QR code contains a valid URL \(url)")
                            guard let host = url.host(),
                                  CIRCLES_DOMAINS.contains(host)
                            else {
                                print("QR code URL is not for one of our domains (found \(url.host() ?? "nil"))")
                                return
                            }
                            for component in url.pathComponents {
                                if let pathRoomId = RoomId(component) {
                                    print("Found roomId \(pathRoomId) in QR code URL path")
                                    self.roomId = pathRoomId
                                    return
                                }
                            }
                        } else {
                            print("QR does not contain a valid roomId: \(scannedCode)")
                        }
                    } else {
                        print("QR code scanning failed")
                    }
                }
                //.frame(width: 300, height: 300)
                //.padding()
            }
            
            Button(role: .destructive, action: {
                self.presentation.wrappedValue.dismiss()
            }) {
                Text("Cancel")
                    .padding()
            }
        }
        .padding()
    }
}
