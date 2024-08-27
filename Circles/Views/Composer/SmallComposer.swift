//
//  SmallComposer.swift
//  Circles
//
//  Created by Charles Wright on 8/13/24.
//

import SwiftUI
import PhotosUI
import Matrix

struct SmallComposer: View {
    var room: Matrix.Room
    @Binding var scroll: EventId?
    var parent: Matrix.Message?
    var prompt: String
    
    var body: some View {
        let viewModel = ComposerViewModel(room: room, parent: parent)
        SmallViewModelComposer(viewModel: viewModel, scroll: $scroll, prompt: prompt)
    }
}

struct SmallViewModelComposer: View {
    @ObservedObject var viewModel: ComposerViewModel
    @Binding var scroll: EventId?
    var prompt: String
    @State private var showPicker = false
    
    func send() async throws -> EventId {
        let eventId = try await self.viewModel.send()
        await MainActor.run {
            self.scroll = eventId
        }
        //await self.viewModel.reset()
        return eventId
    }
    
    @ViewBuilder
    var attachmentButton: some View {
        HStack(alignment: .center, spacing: 0) {
            Button(action: {
                self.showPicker = true
            }) {
                Text("\(Image(systemName: SystemImages.paperclip.rawValue))")
                    .font(
                        Font.custom("SF Pro Display", size: 18)
                            .weight(.bold)
                    )
                    .multilineTextAlignment(.center)
            }
            .photosPicker(isPresented: $showPicker, selection: $viewModel.selectedItem)
        }
        .padding(.leading, 8)
        .padding(.trailing, 10)
        .padding(.top, 9)
        .padding(.bottom, 6)
    }
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 0) {
            
            attachmentButton
            
            VStack {
                if let thumbnail = viewModel.messageState.thumbnail {
                    BasicImage(uiImage: thumbnail)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(alignment: .topTrailing) {
                            Button(action: {
                                viewModel.selectedItem = nil
                                viewModel.messageState = .text
                            }) {
                                Image(systemName: SystemImages.xCircleFill.rawValue)
                                    .symbolRenderingMode(.multicolor)
                                    .font(.system(size: 30))
                                    .foregroundColor(.accentColor)
                            }
                        }
                        .frame(maxHeight: 160)
                }
                
                TextField(text: $viewModel.text) {
                    Text(prompt)
                }
                .textFieldStyle(.roundedBorder)
                .submitLabel(.send)
                .onSubmit {
                    Task {
                        try await send()
                    }
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
            .disabled(viewModel.text.isEmpty)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .center)
        .overlay(
            Rectangle()
                .inset(by: 0.5)
                .stroke(Color.greyCool300, lineWidth: 1)
        )
    }
}
