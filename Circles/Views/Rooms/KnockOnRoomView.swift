//
//  KnockOnRoomView.swift
//  Circles
//
//  Created by Charles Wright on 4/9/24.
//

import SwiftUI
import Matrix

struct KnockOnRoomView: View {
    var roomId: RoomId
    var session: Matrix.Session

    @Environment(\.presentationMode) var presentation

    @State var reason = ""
    
    var body: some View {
        VStack {
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
        }
    }
}
