//
//  RoomTopicEditorView.swift
//  Circles
//
//  Created by Charles Wright on 4/15/24.
//

import SwiftUI
import Matrix

struct RoomTopicEditorView: View {
    @ObservedObject var room: Matrix.Room
    @Environment(\.presentationMode) var presentation

    @State var newTopic: String
    
    enum FocusField {
        case topic
    }
    @FocusState var focus: FocusField?
    
    init(room: Matrix.Room) {
        self.room = room
        self._newTopic = State(wrappedValue: room.topic ?? "")
    }
    
    var body: some View {
        VStack(alignment: .center, spacing: 100) {
            Spacer()

            HStack {
                TextField(room.name ?? "", text: $newTopic, prompt: Text("New topic"))
                    .textFieldStyle(.roundedBorder)
                    .textInputAutocapitalization(.sentences)
                    .focused($focus, equals: .topic)
                    .frame(width: 300, height: 40)
                    .onAppear {
                        self.focus = .topic
                    }
                Button(action: {
                    self.newTopic = ""
                }) {
                    Image(systemName: SystemImages.xmark.rawValue)
                        .foregroundColor(.gray)
                }
            }
            
            AsyncButton(action: {
                try await room.setTopic(newTopic: newTopic)
                self.presentation.wrappedValue.dismiss()
            }) {
                Text("Update")
            }
            
            Spacer()
        }
        .navigationTitle("Change Topic")
    }
}
