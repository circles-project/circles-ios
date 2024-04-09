//
//  ScanQrCodeView.swift
//  Circles
//
//  Created by Charles Wright on 4/9/24.
//

import SwiftUI
import Matrix
import CodeScanner

struct ScanQrCodeView: View {
    @Binding var roomId: RoomId?
    
    var body: some View {
        VStack {
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
    }
}
