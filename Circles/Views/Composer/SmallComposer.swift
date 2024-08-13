//
//  SmallComposer.swift
//  Circles
//
//  Created by Charles Wright on 8/13/24.
//

import SwiftUI
import Matrix

struct SmallComposer: View {
    var room: Matrix.Room
    var parent: Matrix.Message?
    var prompt: String
    
    @State var newMessageText: String = ""
    
    func send() async throws -> EventId {
        let eventId: EventId
        if let parent = self.parent {
            eventId = try await room.sendText(text: self.newMessageText,
                                                  inReplyTo: parent)
        } else {
            eventId = try await room.sendText(text: self.newMessageText)
        }
        await MainActor.run {
            self.newMessageText = ""
        }
        return eventId
    }
    
    @ViewBuilder
    var attachmentButton: some View {
        HStack(alignment: .center, spacing: 0) {
            Button(action: {
                // Pick media to attach
            }) {
                Text("\(Image(systemName: SystemImages.paperclip.rawValue))")
                    .font(
                        Font.custom("SF Pro Display", size: 18)
                            .weight(.bold)
                    )
                    .multilineTextAlignment(.center)
            }
            .disabled(true)
        }
        .padding(.leading, 8)
        .padding(.trailing, 10)
        .padding(.top, 9)
        .padding(.bottom, 6)
    }
    
    var body: some View {
        HStack(spacing: 0) {
            
            attachmentButton
            
            TextField(text: $newMessageText) {
                Text(prompt)
            }
            .textFieldStyle(.roundedBorder)
            .submitLabel(.send)
            .onSubmit {
                Task {
                    try await send()
                }
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 0)
            .frame(maxWidth: .infinity, alignment: .topLeading)
            
            AsyncButton(action: {
                try await send()
            }) {
                Text("\(Image(systemName: SystemImages.paperplaneFill.rawValue))")
                .font(
                    Font.custom("SF Pro Display", size: 18)
                        .weight(.bold)
                )
                .multilineTextAlignment(.center)
                .frame(maxWidth: 40, alignment: .center)
            }
            .disabled(newMessageText.isEmpty)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .center)
        .overlay(
            Rectangle()
                .inset(by: 0.5)
                .stroke(Color.greyCool300, lineWidth: 1)
        )    }
}
